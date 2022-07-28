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
    values = ["ubuntu/images/*ubuntu-jammy-22.04-amd64-server-*"]
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
  vpc_id                      = module.vpc.vpc_id
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
    nomad_region              = var.region,
    nomad_datacenter          = var.cluster_name,
    consul_ca_file            = base64decode(hcp_consul_cluster.demo_hcp_consul.consul_ca_file),
    consul_gossip_encrypt_key = jsondecode(base64decode(hcp_consul_cluster.demo_hcp_consul.consul_config_file)).encrypt,
    consul_acl_token          = hcp_consul_cluster.demo_hcp_consul.consul_root_token_secret_id,
    vault_endpoint            = hcp_vault_cluster.demo_hcp_vault.vault_private_endpoint_url,
    vault_token               = vault_token.nomad_server.client_token
  })

  subnet_ids = module.vpc.public_subnets

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
  vpc_id                      = module.vpc.vpc_id
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
    nomad_region              = var.region,
    nomad_datacenter          = var.cluster_name,
    consul_ca_file            = base64decode(hcp_consul_cluster.demo_hcp_consul.consul_ca_file),
    consul_gossip_encrypt_key = jsondecode(base64decode(hcp_consul_cluster.demo_hcp_consul.consul_config_file)).encrypt,
    consul_acl_token          = hcp_consul_cluster.demo_hcp_consul.consul_root_token_secret_id,
    vault_endpoint            = hcp_vault_cluster.demo_hcp_vault.vault_private_endpoint_url
  })

  subnet_ids = module.vpc.public_subnets

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
