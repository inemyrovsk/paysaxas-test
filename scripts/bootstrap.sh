#!/usr/bin/env bash
set -euo pipefail

export AWS_PAGER=""

REGION="eu-central-1"
BUCKET_PREFIX="paysaxas-tfstate"
DYNAMO_TABLE="paysaxas-tflock"
SECRET_NAME="paysaxas/infrastructure"
OIDC_ROLE_NAME="paysaxas-github-deploy"
GITHUB_REPO="${GITHUB_REPO:-inemyrovsk/paysaxas-test}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BACKEND_HCL="${SCRIPT_DIR}/../terraform/backend.hcl"
SSH_KEY_FILE="${SCRIPT_DIR}/.paysaxas_tmp_key"

# --- AWS Account ID ---
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
BUCKET_NAME="${BUCKET_PREFIX}-${ACCOUNT_ID}"

echo "=== PaySaxas Infrastructure Bootstrap ==="
echo "AWS Account: $ACCOUNT_ID"
echo "Region:      $REGION"
echo "GitHub Repo: $GITHUB_REPO"
echo ""

# --- Hetzner Token ---
if [[ -z "${HCLOUD_TOKEN:-}" ]]; then
  echo "HCLOUD_TOKEN is not set."
  read -rsp "Enter your Hetzner Cloud API token: " HCLOUD_TOKEN
  echo ""
fi

# --- Admin IP ---
ADMIN_IP="${ADMIN_IP:-0.0.0.0/0}"

# --- SSH Key Pair ---
# Reuse existing key from Secrets Manager if available, otherwise generate new
if aws secretsmanager get-secret-value --secret-id "$SECRET_NAME" --region "$REGION" &>/dev/null; then
  echo "Reusing SSH key from existing Secrets Manager secret"
  EXISTING_SECRET=$(aws secretsmanager get-secret-value --secret-id "$SECRET_NAME" --region "$REGION" --query SecretString --output text)
  SSH_PRIVATE_KEY=$(echo "$EXISTING_SECRET" | jq -r .ssh_private_key)
  SSH_PUBLIC_KEY=$(echo "$EXISTING_SECRET" | jq -r .ssh_public_key)
else
  echo "Generating new SSH key pair..."
  rm -f "$SSH_KEY_FILE" "${SSH_KEY_FILE}.pub"
  ssh-keygen -t ed25519 -f "$SSH_KEY_FILE" -C "paysaxas-deploy" -N "" -q
  SSH_PRIVATE_KEY=$(cat "$SSH_KEY_FILE")
  SSH_PUBLIC_KEY=$(cat "${SSH_KEY_FILE}.pub")
  rm -f "$SSH_KEY_FILE" "${SSH_KEY_FILE}.pub"
  echo "SSH key pair generated"
fi

# --- S3 State Bucket ---
if aws s3api head-bucket --bucket "$BUCKET_NAME" 2>/dev/null; then
  echo "S3 bucket already exists: $BUCKET_NAME"
else
  echo "Creating S3 bucket: $BUCKET_NAME"
  aws s3api create-bucket \
    --bucket "$BUCKET_NAME" \
    --region "$REGION" \
    --create-bucket-configuration LocationConstraint="$REGION"

  aws s3api put-bucket-versioning \
    --bucket "$BUCKET_NAME" \
    --versioning-configuration Status=Enabled

  aws s3api put-bucket-encryption \
    --bucket "$BUCKET_NAME" \
    --server-side-encryption-configuration '{
      "Rules": [{"ApplyServerSideEncryptionByDefault": {"SSEAlgorithm": "aws:kms"},"BucketKeyEnabled": true}]
    }'

  aws s3api put-public-access-block \
    --bucket "$BUCKET_NAME" \
    --public-access-block-configuration \
      BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true

  echo "S3 bucket created"
fi

# --- DynamoDB Lock Table ---
if aws dynamodb describe-table --table-name "$DYNAMO_TABLE" --region "$REGION" &>/dev/null; then
  echo "DynamoDB table already exists: $DYNAMO_TABLE"
else
  echo "Creating DynamoDB table: $DYNAMO_TABLE"
  aws dynamodb create-table \
    --table-name "$DYNAMO_TABLE" \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --billing-mode PAY_PER_REQUEST \
    --region "$REGION"

  aws dynamodb wait table-exists --table-name "$DYNAMO_TABLE" --region "$REGION"
  echo "DynamoDB table created"
fi

# --- Secrets Manager ---
SECRET_VALUE=$(jq -n \
  --arg hcloud_token "$HCLOUD_TOKEN" \
  --arg ssh_private_key "$SSH_PRIVATE_KEY" \
  --arg ssh_public_key "$SSH_PUBLIC_KEY" \
  --arg admin_ip "$ADMIN_IP" \
  '{
    hcloud_token: $hcloud_token,
    ssh_private_key: $ssh_private_key,
    ssh_public_key: $ssh_public_key,
    admin_ip: $admin_ip
  }')

if aws secretsmanager describe-secret --secret-id "$SECRET_NAME" --region "$REGION" &>/dev/null; then
  echo "Updating existing secret: $SECRET_NAME"
  aws secretsmanager put-secret-value \
    --secret-id "$SECRET_NAME" \
    --secret-string "$SECRET_VALUE" \
    --region "$REGION"
else
  echo "Creating secret: $SECRET_NAME"
  aws secretsmanager create-secret \
    --name "$SECRET_NAME" \
    --description "PaySaxas infrastructure secrets (Hetzner token, SSH keys, admin IP)" \
    --secret-string "$SECRET_VALUE" \
    --region "$REGION"
fi
echo "Secrets stored in AWS Secrets Manager"

# --- GitHub OIDC Provider ---
OIDC_PROVIDER_ARN="arn:aws:iam::${ACCOUNT_ID}:oidc-provider/token.actions.githubusercontent.com"

if aws iam get-open-id-connect-provider --open-id-connect-provider-arn "$OIDC_PROVIDER_ARN" &>/dev/null; then
  echo "GitHub OIDC provider already exists"
else
  echo "Creating GitHub OIDC provider..."
  # AWS validates GitHub OIDC via JWKS, thumbprint is required by API but ignored.
  # Reference: https://github.com/aws-actions/configure-aws-credentials/issues/357
  aws iam create-open-id-connect-provider \
    --url "https://token.actions.githubusercontent.com" \
    --client-id-list "sts.amazonaws.com" \
    --thumbprint-list "ffffffffffffffffffffffffffffffffffffffff"
  echo "GitHub OIDC provider created"
fi

# --- IAM Role for GitHub Actions ---
ROLE_ARN="arn:aws:iam::${ACCOUNT_ID}:role/${OIDC_ROLE_NAME}"
BACKUP_BUCKET_ARN="arn:aws:s3:::paysaxas-db-backups-${ACCOUNT_ID}"

if aws iam get-role --role-name "$OIDC_ROLE_NAME" &>/dev/null; then
  echo "IAM role already exists: $OIDC_ROLE_NAME"
else
  echo "Creating IAM role: $OIDC_ROLE_NAME"

  TRUST_POLICY=$(jq -n \
    --arg provider_arn "$OIDC_PROVIDER_ARN" \
    --arg repo "$GITHUB_REPO" \
    '{
      Version: "2012-10-17",
      Statement: [{
        Effect: "Allow",
        Principal: { Federated: $provider_arn },
        Action: "sts:AssumeRoleWithWebIdentity",
        Condition: {
          StringEquals: {
            "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
          },
          StringLike: {
            "token.actions.githubusercontent.com:sub": [
              ("repo:" + $repo + ":ref:refs/heads/main"),
              ("repo:" + $repo + ":environment:*")
            ]
          }
        }
      }]
    }')

  aws iam create-role \
    --role-name "$OIDC_ROLE_NAME" \
    --assume-role-policy-document "$TRUST_POLICY" \
    --tags "Key=Project,Value=paysaxas"
  echo "IAM role created"
fi

# --- IAM Role Policy ---
echo "Attaching inline policy to role..."

DEPLOY_POLICY=$(jq -n \
  --arg tfstate_bucket_arn "arn:aws:s3:::${BUCKET_NAME}" \
  --arg backup_bucket_arn "$BACKUP_BUCKET_ARN" \
  --arg dynamo_arn "arn:aws:dynamodb:${REGION}:${ACCOUNT_ID}:table/${DYNAMO_TABLE}" \
  --arg secret_arn "arn:aws:secretsmanager:${REGION}:${ACCOUNT_ID}:secret:paysaxas/*" \
  --arg account_id "$ACCOUNT_ID" \
  '{
    Version: "2012-10-17",
    Statement: [
      {
        Sid: "S3TfstateBucket",
        Effect: "Allow",
        Action: "s3:*",
        Resource: [$tfstate_bucket_arn, ($tfstate_bucket_arn + "/*")]
      },
      {
        Sid: "S3BackupBucket",
        Effect: "Allow",
        Action: "s3:*",
        Resource: [$backup_bucket_arn, ($backup_bucket_arn + "/*")]
      },
      {
        Sid: "S3CreateBackupBucket",
        Effect: "Allow",
        Action: [
          "s3:CreateBucket",
          "s3:ListAllMyBuckets",
          "s3:GetBucketLocation"
        ],
        Resource: "*"
      },
      {
        Sid: "KMS",
        Effect: "Allow",
        Action: [
          "kms:CreateKey",
          "kms:CreateAlias",
          "kms:DeleteAlias",
          "kms:UpdateAlias",
          "kms:TagResource",
          "kms:UntagResource",
          "kms:EnableKeyRotation",
          "kms:GetKeyRotationStatus",
          "kms:GetKeyPolicy",
          "kms:ListResourceTags",
          "kms:ScheduleKeyDeletion",
          "kms:DescribeKey",
          "kms:GenerateDataKey",
          "kms:Decrypt",
          "kms:ListAliases"
        ],
        Resource: "*"
      },
      {
        Sid: "DynamoDB",
        Effect: "Allow",
        Action: [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:DeleteItem"
        ],
        Resource: $dynamo_arn
      },
      {
        Sid: "SecretsManager",
        Effect: "Allow",
        Action: [
          "secretsmanager:*"
        ],
        Resource: $secret_arn
      },
      {
        Sid: "IAMBackupUser",
        Effect: "Allow",
        Action: [
          "iam:CreateUser",
          "iam:DeleteUser",
          "iam:GetUser",
          "iam:TagUser",
          "iam:UntagUser",
          "iam:CreateAccessKey",
          "iam:DeleteAccessKey",
          "iam:ListAccessKeys",
          "iam:PutUserPolicy",
          "iam:DeleteUserPolicy",
          "iam:GetUserPolicy"
        ],
        Resource: ("arn:aws:iam::" + $account_id + ":user/paysaxas-*")
      },
      {
        Sid: "STSGetCallerIdentity",
        Effect: "Allow",
        Action: "sts:GetCallerIdentity",
        Resource: "*"
      }
    ]
  }')

aws iam put-role-policy \
  --role-name "$OIDC_ROLE_NAME" \
  --policy-name "${OIDC_ROLE_NAME}-policy" \
  --policy-document "$DEPLOY_POLICY"
echo "Policy attached"

# --- Generate backend.hcl (for local terraform init) ---
echo "Writing backend config: $BACKEND_HCL"
cat > "$BACKEND_HCL" <<EOF
bucket         = "${BUCKET_NAME}"
key            = "paysaxas/terraform.tfstate"
region         = "${REGION}"
dynamodb_table = "${DYNAMO_TABLE}"
encrypt        = true
EOF

echo ""
echo "========================================"
echo "  Bootstrap complete!"
echo "========================================"
echo ""
echo "Resources created:"
echo "  S3 state bucket:     $BUCKET_NAME"
echo "  DynamoDB lock table: $DYNAMO_TABLE"
echo "  Secrets Manager:     $SECRET_NAME"
echo "  OIDC provider:       $OIDC_PROVIDER_ARN"
echo "  IAM role:            $ROLE_ARN"
echo "  Backend config:      $BACKEND_HCL"
echo ""
echo "Set this ONE GitHub Actions secret:"
echo "  AWS_DEPLOY_ROLE_ARN = $ROLE_ARN"
echo ""
echo "Then push to main — CI/CD handles everything else."
