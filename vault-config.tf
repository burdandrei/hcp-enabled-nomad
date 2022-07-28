provider "vault" {
  address   = hcp_vault_cluster.demo_hcp_vault.vault_public_endpoint_url
  namespace = "admin"
  token     = hcp_vault_cluster_admin_token.demo_hcp_vault_token.token
}

data "http" "nomad_server_policy" {
  url = "https://nomadproject.io/data/vault/nomad-server-policy.hcl"
}

resource "vault_policy" "nomad-server" {
  name   = "nomad-server"
  policy = data.http.nomad_server_policy.response_body
}

resource "vault_token_auth_backend_role" "nomad-cluster" {
  role_name              = "nomad-cluster"
  disallowed_policies    = ["nomad-server"]
  orphan                 = true
  token_period           = "259200"
  renewable              = true
  token_explicit_max_ttl = 0
}

resource "vault_token" "nomad_server" {
  policies  = ["nomad-server"]
  renewable = true
  ttl       = "72h"
  no_parent = true
}

output "nomad_server_vault_token" {
  value     = vault_token.nomad_server.client_token
  sensitive = true
}
