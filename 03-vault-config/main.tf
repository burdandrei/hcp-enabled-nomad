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
  address = data.terraform_remote_state.hcp.outputs.vault_public_endpoint_url
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
  explicit_max_ttl    = "0"
}