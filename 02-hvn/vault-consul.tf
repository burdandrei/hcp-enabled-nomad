resource "hcp_vault_cluster" "demo_hcp_vault" {
  hvn_id          = hcp_hvn.demo_hcp_hvn.hvn_id
  cluster_id      = "demo-vault"
  public_endpoint = true
}

resource "hcp_consul_cluster" "demo_hcp_consul" {
  hvn_id          = hcp_hvn.demo_hcp_hvn.hvn_id
  cluster_id      = "demo-consul"
  tier            = "development"
  public_endpoint = true
}
