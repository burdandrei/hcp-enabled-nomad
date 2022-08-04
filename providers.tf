terraform {
  required_providers {
    hcp = {
      source  = "hashicorp/hcp"
      version = "0.37.0"
    }
    vault = {
      source  = "hashicorp/vault"
      version = "3.8.0"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "4.24.0"
    }
  }
}

provider "hcp" {
  # Configuration options
}

provider "aws" {
  region = var.region
}


provider "vault" {
  address   = hcp_vault_cluster.demo_hcp_vault.vault_public_endpoint_url
  namespace = "admin"
  token     = hcp_vault_cluster_admin_token.demo_hcp_vault_token.token
}
