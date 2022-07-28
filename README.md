# Demo for Nomad cluster backed by HCP Consul and Vault

It will provision VPC, HVN, connect it and deploy Consul, Vault in HCP and Nomad in AWS

Just `terraform apply` in the root directory, it will provision everything

# Disclaimer

It'll spin non free resources

## Variables

AWS and HCP credentials are needed:

- HCP_CLIENT_ID
- HCP_CLIENT_SECRET
- AWS_ACCESS_KEY_ID
- AWS_SECRET_ACCESS_KEY

