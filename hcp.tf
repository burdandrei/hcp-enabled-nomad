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
  }
}

provider "hcp" {
  # Configuration options
}


resource "hcp_hvn" "demo_hcp_hvn" {
  hvn_id         = "demo-hvn"
  cloud_provider = "aws"
  region         = var.region
}

resource "hcp_aws_network_peering" "peer" {
  hvn_id          = hcp_hvn.demo_hcp_hvn.hvn_id
  peering_id      = "nomad"
  peer_vpc_id     = module.vpc.vpc_id
  peer_account_id = module.vpc.vpc_owner_id
  peer_vpc_region = var.region
}

resource "hcp_hvn_route" "hvn-to-vpc" {
  hvn_link         = hcp_hvn.demo_hcp_hvn.self_link
  hvn_route_id     = "hvn-to-vpc"
  destination_cidr = module.vpc.vpc_cidr_block
  target_link      = hcp_aws_network_peering.peer.self_link
}

resource "aws_vpc_peering_connection_accepter" "peer" {
  vpc_peering_connection_id = hcp_aws_network_peering.peer.provider_peering_id
  auto_accept               = true
}

resource "aws_route" "hvn-peering" {
  route_table_id            = module.vpc.public_route_table_ids[0]
  destination_cidr_block    = hcp_hvn.demo_hcp_hvn.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection_accepter.peer.id
}

resource "hcp_vault_cluster" "demo_hcp_vault" {
  hvn_id          = hcp_hvn.demo_hcp_hvn.hvn_id
  cluster_id      = "demo-vault"
  public_endpoint = true
}

resource "hcp_vault_cluster_admin_token" "demo_hcp_vault_token" {
  cluster_id = hcp_vault_cluster.demo_hcp_vault.cluster_id
}

resource "hcp_consul_cluster" "demo_hcp_consul" {
  hvn_id          = hcp_hvn.demo_hcp_hvn.hvn_id
  cluster_id      = "demo-consul"
  tier            = "development"
  public_endpoint = true
}
