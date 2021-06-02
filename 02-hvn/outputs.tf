output "cidr_block" {
  value = hcp_hvn.demo_hcp_hvn.cidr_block
}


output "consul_ca_file" {
  value = hcp_consul_cluster.demo_hcp_consul.consul_ca_file
}

output "consul_root_token_secret_id" {
  value     = hcp_consul_cluster.demo_hcp_consul.consul_root_token_secret_id
  sensitive = true
}
