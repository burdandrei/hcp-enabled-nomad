resource "hcp_vault_cluster" "demo_hcp_vault" {
  hvn_id     = hcp_hvn.demo_hcp_hvn.hvn_id
  cluster_id = "demo-vault"
}

resource "hcp_consul_cluster" "demo_hcp_consul" {
  hvn_id     = hcp_hvn.demo_hcp_hvn.hvn_id
  cluster_id = "demo-consul"
}
