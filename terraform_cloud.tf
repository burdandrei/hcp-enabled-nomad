resource "tfe_workspace" "terraform_cloud_seed" {
  name                = "TerraformCloudSeed"
  organization        = var.tfc_organization_name
  tag_names           = ["hcp_enabled_nomad"]
  execution_mode      = "remote"
  auto_apply          = true
  global_remote_state = true
  vcs_repo {
    identifier     = "${var.github_username}/hcp-enabled-nomad"
    oauth_token_id = var.oauth_token_id
  }
  working_directory = "00-tfc"
  queue_all_runs    = false
}

resource "tfe_variable" "organization_name" {
  key          = "tfc_organization_name"
  value        = var.tfc_organization_name
  category     = "terraform"
  workspace_id = tfe_workspace.terraform_cloud_seed.id
  description  = "Org Name"
}

resource "tfe_variable" "oauth_token_id" {
  key          = "oauth_token_id"
  value        = var.oauth_token_id
  category     = "terraform"
  workspace_id = tfe_workspace.terraform_cloud_seed.id
  description  = "OAuth Token"
}

resource "tfe_variable" "github_username" {
  key          = "github_username"
  value        = var.github_username
  category     = "terraform"
  workspace_id = tfe_workspace.terraform_cloud_seed.id
  description  = "GitHub Username"
}

resource "tfe_variable" "tfe_token" {
  key          = "TFE_TOKEN"
  value        = "Provide me and make me sensitive"
  category     = "env"
  workspace_id = tfe_workspace.terraform_cloud_seed.id
  description  = "Terraform Cloud API Token"
}
