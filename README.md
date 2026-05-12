Initial setup guide
1. create ssh keys
`ssh-keygen -t ed25519 -f ~/.ssh/paysaxas -C "paysaxas-deploy"`
2. create s3 bucket for state

claude --resume e1fec07f-7e9b-4ab2-aa10-41cb69ed949b

# [Topic]
# Kubernetes
## [Name of chosen tool]
## K3S
k3s is light weight easy to use distributive
### [alternatives considered]
### kubeadm, kubespray
I have not choose kubeadm because its too hard to manage and decided to consentrate on more important bussiness things to deliver app

# OS


# CI
github actions
alternatives
When code is pushed to main it will ran CI workflow which consists of 3 jobs:
1. **Semver**
    - using Gitversion to generate semantic version based on previous jobs
2. **Build**
    - Using Buildah to build docker images
    - pushes images to ghcr
    - saves the image tar archive
3. **Release**
    - pushes release tag to registry