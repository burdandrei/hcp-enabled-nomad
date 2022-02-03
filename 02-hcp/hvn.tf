resource "hcp_hvn" "demo_hcp_hvn" {
  hvn_id         = "demo-hvn"
  cloud_provider = "aws"
  region         = var.region
}

data "terraform_remote_state" "vpc" {
  backend = "remote"
  config = {
    organization = "bandrei_hc"
    workspaces = {
      name = "01-VPC"
    }
  }
}


resource "hcp_aws_network_peering" "peer" {
  hvn_id              = hcp_hvn.demo_hcp_hvn.hvn_id
  peer_vpc_id         = data.terraform_remote_state.vpc.outputs.vpc_id
  peer_account_id     = data.terraform_remote_state.vpc.outputs.vpc_owner_id
  peer_vpc_region     = var.region
  peer_vpc_cidr_block = data.terraform_remote_state.vpc.outputs.cidr_block
}

resource "aws_vpc_peering_connection_accepter" "peer" {
  vpc_peering_connection_id = hcp_aws_network_peering.peer.provider_peering_id
  auto_accept               = true
}


resource "aws_route" "hvn-peering" {
  route_table_id            = data.terraform_remote_state.vpc.outputs.public_route_table_ids[0]
  destination_cidr_block    = hcp_hvn.demo_hcp_hvn.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection_accepter.peer.id
}
