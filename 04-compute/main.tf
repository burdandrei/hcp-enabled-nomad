data "aws_ami" "base" {
  most_recent = true

  # If we change the AWS Account in which test are run, update this value.
  owners = ["099720109477"]

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "name"
    values = ["ubuntu/images/*ubuntu-hirsute-21.04-amd64-server-*"]
  }
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

data "terraform_remote_state" "hcp" {
  backend = "remote"
  config = {
    organization = "bandrei_hc"
    workspaces = {
      name = "02-HCP"
    }
  }
}

data "terraform_remote_state" "vault_config" {
  backend = "remote"
  config = {
    organization = "bandrei_hc"
    workspaces = {
      name = "03-vault-config"
    }
  }
}

#---------------------------------------------------------------------------------------------------------------------
# DEPLOY THE SERVER NODES
# ---------------------------------------------------------------------------------------------------------------------

module "servers" {
  source  = "hashicorp/consul/aws//modules/consul-cluster"
  version = "0.8.6"
  # insert the 14 required variables here
  allowed_inbound_cidr_blocks = ["0.0.0.0/0"]
  ami_id                      = data.aws_ami.base.image_id
  spot_price                  = var.spot_price
  vpc_id                      = data.terraform_remote_state.vpc.outputs.vpc_id
  ssh_key_name                = var.ssh_key_name

  # end of required variables

  cluster_name     = "${var.cluster_name}-server"
  cluster_size     = var.num_servers
  instance_type    = "t3.medium"
  root_volume_size = 16

  # The EC2 Instances will use these tags to automatically discover each othe r and form a cluster
  cluster_tag_key   = var.cluster_tag_key
  cluster_tag_value = var.cluster_name


  user_data = templatefile("user-data-server.sh", {
    nomad_region     = var.nomad_region,
    nomad_datacenter = var.cluster_name,
    consul_ca_file   = base64decode(data.terraform_remote_state.hcp.outputs.consul_ca_file),
    consul_gossip_encrypt_key = data.terraform_remote_state.hcp.outputs.consul_gossip_encrypt_key,
    consul_acl_token = data.terraform_remote_state.hcp.outputs.consul_root_token_secret_id,
    vault_endpoint = data.terraform_remote_state.hcp.outputs.vault_private_endpoint_url,
    vault_token = data.terraform_remote_state.vault_config.outputs.nomad_server_vault_token
  })

  subnet_ids = data.terraform_remote_state.vpc.outputs.public_subnets

  # To make testing easier, we allow Consul and SSH requests from any IP address here but in a production
  # deployment, we strongly recommend you limit this to the IP address ranges of known, trusted servers inside your VPC.
  allowed_ssh_cidr_blocks = ["0.0.0.0/0"]

}


module "clients" {
  source  = "hashicorp/consul/aws//modules/consul-cluster"
  version = "0.8.6"
  # insert the 14 required variables here
  allowed_inbound_cidr_blocks = ["0.0.0.0/0"]
  ami_id                      = data.aws_ami.base.image_id
  spot_price                  = var.spot_price
  vpc_id                      = data.terraform_remote_state.vpc.outputs.vpc_id
  ssh_key_name                = var.ssh_key_name

  # end of required variables

  cluster_name     = "${var.cluster_name}-client"
  cluster_size     = var.num_servers
  instance_type    = "t3.medium"
  root_volume_size = 16

  # The EC2 Instances will use these tags to automatically discover each othe r and form a cluster
  cluster_tag_key   = var.cluster_tag_key
  cluster_tag_value = var.cluster_name


  user_data = templatefile("user-data-client.sh", {
    nomad_region     = var.nomad_region,
    nomad_datacenter = var.cluster_name,
    consul_ca_file   = base64decode(data.terraform_remote_state.hcp.outputs.consul_ca_file),
    consul_gossip_encrypt_key = data.terraform_remote_state.hcp.outputs.consul_gossip_encrypt_key,
    consul_acl_token = data.terraform_remote_state.hcp.outputs.consul_root_token_secret_id,
    vault_endpoint   = data.terraform_remote_state.hcp.outputs.vault_private_endpoint_url
  })

  subnet_ids = data.terraform_remote_state.vpc.outputs.public_subnets

  # To make testing easier, we allow Consul and SSH requests from any IP address here but in a production
  # deployment, we strongly recommend you limit this to the IP address ranges of known, trusted servers inside your VPC.
  allowed_ssh_cidr_blocks = ["0.0.0.0/0"]

}

# ---------------------------------------------------------------------------------------------------------------------
# THE INBOUND/OUTBOUND RULES FOR THE SECURITY GROUP COME FROM THE NOMAD-SECURITY-GROUP-RULES MODULE
# ---------------------------------------------------------------------------------------------------------------------

module "nomad_servers_security_group_rules" {
  source  = "hashicorp/nomad/aws//modules/nomad-security-group-rules"
  version = "0.9.0"

  security_group_id           = module.servers.security_group_id
  allowed_inbound_cidr_blocks = var.allowed_inbound_cidr_blocks

  http_port = 4646
  rpc_port  = 4647
  serf_port = 4648
}

module "nomad_clients_security_group_rules" {
  source  = "hashicorp/nomad/aws//modules/nomad-security-group-rules"
  version = "0.9.0"

  security_group_id           = module.clients.security_group_id
  allowed_inbound_cidr_blocks = var.allowed_inbound_cidr_blocks

  http_port = 4646
  rpc_port  = 4647
  serf_port = 4648
}

resource "aws_security_group_rule" "allow_nomad_dynamic_inbound" {
  type        = "ingress"
  from_port   = 80
  to_port     = 65535 # Don't do it in prod
  protocol    = "tcp"
  cidr_blocks = var.allowed_inbound_cidr_blocks

  security_group_id = module.clients.security_group_id
}