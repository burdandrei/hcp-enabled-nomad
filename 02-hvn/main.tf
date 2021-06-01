resource "hcp_hvn" "demo_hcp_hvn" {
  hvn_id         = "demo-hvn"
  cloud_provider = "aws"
  region         = var.region
}

provider "aws" {
  region = var.region
}

resource "aws_vpc" "peer" {
  cidr_block = "10.0.0.0/16"
}

data "aws_arn" "peer" {
  arn = aws_vpc.peer.arn
}

resource "hcp_aws_network_peering" "peer" {
  hvn_id              = hcp_hvn.demo_hcp_hvn.hvn_id
  peer_vpc_id         = aws_vpc.peer.id
  peer_account_id     = aws_vpc.peer.owner_id
  peer_vpc_region     = data.aws_arn.peer.region
  peer_vpc_cidr_block = aws_vpc.peer.cidr_block
}

resource "aws_vpc_peering_connection_accepter" "peer" {
  vpc_peering_connection_id = hcp_aws_network_peering.peer.provider_peering_id
  auto_accept               = true
}
