provider "hcloud" {
  token = var.hcloud_token
}

provider "aws" {
  region = "eu-central-1"
}
