data "http" "nomad_server_policy" {
  url = "https://nomadproject.io/data/vault/nomad-server-policy.hcl"
}

resource "vault_policy" "nomad-server" {
  name   = "nomad-server"
  policy = data.http.nomad_server_policy.response_body
  depends_on = [
    hcp_vault_cluster.demo_hcp_vault
  ]
}

resource "vault_token_auth_backend_role" "nomad-cluster" {
  role_name              = "nomad-cluster"
  disallowed_policies    = ["nomad-server"]
  orphan                 = true
  token_period           = "259200"
  renewable              = true
  token_explicit_max_ttl = 0
  depends_on = [
    hcp_vault_cluster.demo_hcp_vault
  ]
}

resource "vault_token" "nomad_server" {
  policies  = ["nomad-server"]
  renewable = true
  ttl       = "72h"
  no_parent = true
  depends_on = [
    hcp_vault_cluster.demo_hcp_vault
  ]
}

output "nomad_server_vault_token" {
  value     = vault_token.nomad_server.client_token
  sensitive = true
  depends_on = [
    hcp_vault_cluster.demo_hcp_vault
  ]
}
