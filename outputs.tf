# VPC

output "cidr_block" {
  value = module.vpc.vpc_cidr_block
}

output "vpc_id" {
  value = module.vpc.vpc_id
}

output "public_subnets" {
  value = module.vpc.public_subnets
}

output "public_route_table_ids" {
  value = module.vpc.public_route_table_ids
}

output "vpc_owner_id" {
  value = module.vpc.vpc_owner_id
}


# HVN

output "hvn_cidr_block" {
  value = hcp_hvn.demo_hcp_hvn.cidr_block
}

output "consul_ca_file" {
  value = hcp_consul_cluster.demo_hcp_consul.consul_ca_file
}

output "consul_gossip_encrypt_key" {
  value = jsondecode(base64decode(hcp_consul_cluster.demo_hcp_consul.consul_config_file)).encrypt
}

output "consul_root_token_secret_id" {
  value     = hcp_consul_cluster.demo_hcp_consul.consul_root_token_secret_id
  sensitive = true
}

output "vault_private_endpoint_url" {
  value = hcp_vault_cluster.demo_hcp_vault.vault_private_endpoint_url
}

output "vault_public_endpoint_url" {
  value = hcp_vault_cluster.demo_hcp_vault.vault_public_endpoint_url
}

output "vault_admin_token" {
  value     = hcp_vault_cluster_admin_token.demo_hcp_vault_token.token
  sensitive = true
}
