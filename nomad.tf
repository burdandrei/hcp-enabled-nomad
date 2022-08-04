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

resource "aws_security_group" "demo" {
  name   = "HCP Enabled Nomad Demo"
  vpc_id = module.vpc.vpc_id
  ingress {
    description      = "Allow All"
    from_port        = 0
    to_port          = 0
    protocol         = "all"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  egress {
    description      = "Allow All"
    from_port        = 0
    to_port          = 0
    protocol         = "all"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  tags = {
    Name = "HCP Enabled Nomad Demo"
  }
}

resource "aws_launch_template" "nomad-servers" {
  name = "HCP_Enabled_Nomad_Servers"

  block_device_mappings {
    device_name = "/dev/sda1"

    ebs {
      volume_size = 16
    }
  }
  # TODO: add IAM role
  # iam_instance_profile {
  #   name = "test"
  # }

  image_id = data.aws_ami.base.image_id

  instance_initiated_shutdown_behavior = "terminate"

  instance_type = "t3.medium"

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
    instance_metadata_tags      = "enabled"
  }

  monitoring {
    enabled = true
  }

  vpc_security_group_ids = [aws_security_group.demo.id]

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "Nomad-server"
    }
  }

  user_data = base64encode(templatefile("user-data-server.sh", {
    nomad_region              = var.region,
    nomad_datacenter          = var.cluster_name,
    consul_ca_file            = base64decode(hcp_consul_cluster.demo_hcp_consul.consul_ca_file),
    consul_gossip_encrypt_key = jsondecode(base64decode(hcp_consul_cluster.demo_hcp_consul.consul_config_file)).encrypt,
    consul_acl_token          = hcp_consul_cluster.demo_hcp_consul.consul_root_token_secret_id,
    vault_endpoint            = hcp_vault_cluster.demo_hcp_vault.vault_private_endpoint_url,
    vault_token               = vault_token.nomad_server.client_token
  }))

}

resource "aws_autoscaling_group" "nomad-servers" {
  name                = "HCP Enabled Nomad servers"
  vpc_zone_identifier = module.vpc.public_subnets

  desired_capacity = 3
  max_size         = 3
  min_size         = 3

  launch_template {
    id      = aws_launch_template.nomad-servers.id
    version = "$Latest"
  }
}







#------------------------



resource "aws_launch_template" "nomad-clients" {
  name = "HCP_Enabled_Nomad_Clients"

  block_device_mappings {
    device_name = "/dev/sda1"

    ebs {
      volume_size = 16
    }
  }
  # TODO: add IAM role
  # iam_instance_profile {
  #   name = "test"
  # }

  image_id = data.aws_ami.base.image_id

  instance_initiated_shutdown_behavior = "terminate"

  instance_type = "t3.medium"

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
    instance_metadata_tags      = "enabled"
  }

  monitoring {
    enabled = true
  }

  vpc_security_group_ids = [aws_security_group.demo.id]

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "Nomad-Client"
    }
  }

  user_data = base64encode(templatefile("user-data-client.sh", {
    nomad_region              = var.region,
    nomad_datacenter          = var.cluster_name,
    consul_ca_file            = base64decode(hcp_consul_cluster.demo_hcp_consul.consul_ca_file),
    consul_gossip_encrypt_key = jsondecode(base64decode(hcp_consul_cluster.demo_hcp_consul.consul_config_file)).encrypt,
    consul_acl_token          = hcp_consul_cluster.demo_hcp_consul.consul_root_token_secret_id,
    vault_endpoint            = hcp_vault_cluster.demo_hcp_vault.vault_private_endpoint_url,
  }))

}

resource "aws_autoscaling_group" "nomad-clients" {
  name                = "HCP Enabled Nomad Clients"
  vpc_zone_identifier = module.vpc.public_subnets

  desired_capacity = 3
  max_size         = 3
  min_size         = 3

  launch_template {
    id      = aws_launch_template.nomad-clients.id
    version = "$Latest"
  }
}


# module "clients" {
#   source  = "hashicorp/consul/aws//modules/consul-cluster"
#   version = "0.8.6"
#   # insert the 14 required variables here
#   allowed_inbound_cidr_blocks = ["0.0.0.0/0"]
#   ami_id                      = data.aws_ami.base.image_id
#   spot_price                  = var.spot_price
#   vpc_id                      = module.vpc.vpc_id
#   ssh_key_name                = var.ssh_key_name

#   # end of required variables

#   cluster_name     = "${var.cluster_name}-client"
#   cluster_size     = var.num_servers
#   instance_type    = "t3.medium"
#   root_volume_size = 16

#   # The EC2 Instances will use these tags to automatically discover each othe r and form a cluster
#   cluster_tag_key   = var.cluster_tag_key
#   cluster_tag_value = var.cluster_name


#   user_data = templatefile("user-data-client.sh", {
#     nomad_region              = var.region,
#     nomad_datacenter          = var.cluster_name,
#     consul_ca_file            = base64decode(hcp_consul_cluster.demo_hcp_consul.consul_ca_file),
#     consul_gossip_encrypt_key = jsondecode(base64decode(hcp_consul_cluster.demo_hcp_consul.consul_config_file)).encrypt,
#     consul_acl_token          = hcp_consul_cluster.demo_hcp_consul.consul_root_token_secret_id,
#     vault_endpoint            = hcp_vault_cluster.demo_hcp_vault.vault_private_endpoint_url
#   })

#   subnet_ids = module.vpc.public_subnets

#   # To make testing easier, we allow Consul and SSH requests from any IP address here but in a production
#   # deployment, we strongly recommend you limit this to the IP address ranges of known, trusted servers inside your VPC.
#   allowed_ssh_cidr_blocks = ["0.0.0.0/0"]

# }
