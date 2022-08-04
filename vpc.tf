module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  name   = var.name
  cidr   = var.cidr

  azs            = slice(data.aws_availability_zones.available.*.names[0], 0, 3)
  public_subnets = var.public_subnets
  public_subnet_tags = {
    Name = "${var.name}-public"
  }
  enable_dns_hostnames            = true
  enable_ipv6                     = true
  assign_ipv6_address_on_creation = true
  public_subnet_ipv6_prefixes     = [0, 1, 2]

  tags = {
    Terraform = "true"
    Name      = var.name
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}
