resource "tfe_workspace" "vpc" {
  name         = "VPC"
  organization = var.tfc_organization_name
  tag_names    = ["hcp_enabled_nomad"]
  vcs_repo {
    identifier     = "${var.github_username}/hcp-enabled-nomad"
    oauth_token_id = var.oauth_token_id
  }
  working_directory   = "01-vpc"
  execution_mode      = "remote"
  auto_apply          = true
  global_remote_state = true
  queue_all_runs      = false

}
