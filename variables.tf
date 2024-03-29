# VPC #


variable "region" {
  description = "The region of the VPC, HCP HVN and Vault & Consul clusters"
  type        = string
  default     = "eu-central-1"
}

variable "name" {
  type    = string
  default = "hcpenablednomad"
}
variable "public_subnets" {
  type = list(any)
  default = [
    "10.0.20.0/24",
    "10.0.21.0/24",
    "10.0.22.0/24",
  ]
}
variable "cidr" {
  default = "10.0.0.0/16"
}

# Compute 

variable "ami_id" {
  description = "The ID of the AMI to run in the cluster. This should be an AMI built from the Packer template under examples/consul-ami/consul.json. To keep this example simple, we run the same AMI on both server and client nodes, but in real-world usage, your client nodes would also run your apps. If the default value is used, Terraform will look up the latest AMI build automatically."
  type        = string
  default     = null
}

variable "cluster_name" {
  description = "What to name the Consul cluster and all of its associated resources"
  type        = string
  default     = "hc_demo"
}

variable "num_servers" {
  description = "The number of Server nodes to deploy. We strongly recommend using 3 or 5."
  type        = number
  default     = 3
}

variable "num_clients" {
  description = "The number of client nodes to deploy. You typically run the Consul client alongside your apps, so set this value to however many Instances make sense for your app code."
  type        = number
  default     = 3
}

variable "cluster_tag_key" {
  description = "The tag the EC2 Instances will look for to automatically discover each other and form a cluster."
  type        = string
  default     = "hc_demo-servers"
}

variable "ssh_key_name" {
  description = "The name of an EC2 Key Pair that can be used to SSH to the EC2 Instances in this cluster. Set to an empty string to not associate a Key Pair."
  type        = string
  default     = null
}

variable "vpc_id" {
  description = "The ID of the VPC in which the nodes will be deployed.  Uses default VPC if not supplied."
  type        = string
  default     = null
}

variable "spot_price" {
  description = "The maximum hourly price to pay for EC2 Spot Instances."
  type        = number
  default     = null
}

variable "allowed_inbound_cidr_blocks" {
  description = "A list of CIDR-formatted IP address ranges from which the EC2 Instances will allow connections to Consul"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "nomad_datacenter" {
  type        = string
  description = "Nomad Datacenter"
  default     = "demo"
}
