terraform {
  backend "s3" {
    bucket         = "paysaxas-tfstate-138941284341"
    key            = "paysaxas/terraform.tfstate"
    region         = "eu-central-1"
    dynamodb_table = "paysaxas-tflock"
    encrypt        = true
  }
}
