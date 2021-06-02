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


#---------------------------------------------------------------------------------------------------------------------
# DEPLOY THE SERVER NODES
# ---------------------------------------------------------------------------------------------------------------------

module "servers" {
  source  = "hashicorp/consul/aws"
  version = "0.10.1"
  # insert the 4 required variables here
  ami_id       = data.aws_ami.base.image_id
  spot_price   = var.spot_price
  vpc_id       = data.terraform_remote_state.vpc.outputs.vpc_id
  ssh_key_name = var.ssh_key_name

  # end of required variables

  cluster_name     = "${var.cluster_name}-server"
  cluster_size     = var.num_servers
  instance_type    = "t3.medium"
  root_volume_size = 16

  # The EC2 Instances will use these tags to automatically discover each othe r and form a cluster
  cluster_tag_key   = var.cluster_tag_key
  cluster_tag_value = var.cluster_name


  user_data = templatefile("user-data-server.sh", {
    cluster_tag_key   = var.cluster_tag_key,
    cluster_tag_value = var.cluster_name
  })

  subnet_ids = data.terraform_remote_state.vpc.outputs.public_subnets

  # To make testing easier, we allow Consul and SSH requests from any IP address here but in a production
  # deployment, we strongly recommend you limit this to the IP address ranges of known, trusted servers inside your VPC.
  allowed_ssh_cidr_blocks = ["0.0.0.0/0"]

  allowed_inbound_cidr_blocks = ["0.0.0.0/0"]

}

# ---------------------------------------------------------------------------------------------------------------------
# THE INBOUND/OUTBOUND RULES FOR THE SECURITY GROUP COME FROM THE NOMAD-SECURITY-GROUP-RULES MODULE
# ---------------------------------------------------------------------------------------------------------------------

module "nomad_security_group_rules" {
  source = "github.com/hashicorp/terraform-aws-nomad.git//modules/nomad-security-group-rules?ref=v0.6.0"

  security_group_id           = module.servers.security_group_id
  allowed_inbound_cidr_blocks = var.allowed_inbound_cidr_blocks

  http_port = 4646
  rpc_port  = 4647
  serf_port = 4648
}
