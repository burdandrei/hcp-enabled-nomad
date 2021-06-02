terraform {
  required_providers {
    vault = {
      source = "hashicorp/vault"
      version = "2.20.0"
    }
  }
}

data "terraform_remote_state" "hcp" {
  backend = "remote"
  config = {
    organization = "bandrei_hc"
    workspaces = {
      name = "02-HCP"
    }
  }
}

provider "vault" {
  address = "https://${data.terraform_remote_state.hcp.outputs.vault_public_endpoint_url}:8200"
  namespace = "admin"
  token = data.terraform_remote_state.hcp.outputs.vault_admin_token
}

data "http" "nomad_server_policy" {
  url = "https://nomadproject.io/data/vault/nomad-server-policy.hcl"
}

resource "vault_policy" "nomad-server" {
  name = "nomad-server"
  policy = data.http.nomad_server_policy.body
}

resource "vault_token_auth_backend_role" "nomad-cluster" {
  role_name           = "nomad-cluster"
  disallowed_policies = ["nomad-server"]
  orphan              = true
  token_period        = "259200"
  renewable           = true
  token_explicit_max_ttl    = 0
}

resource "vault_token" "nomad_server" {
  policies = ["nomad-server"]
  renewable = true
  ttl = "72h"
  no_parent = true
}

output "nomad_server_vault_token" {
  value = vault_token.nomad_server.client_token
  sensitive = true
}