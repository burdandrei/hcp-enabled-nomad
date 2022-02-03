resource "tfe_workspace" "hcp" {
  name         = "HCP"
  organization = var.tfc_organization_name
  tag_names    = ["hcp_enabled_nomad"]
  vcs_repo {
    identifier     = "${var.github_username}/hcp-enabled-nomad"
    oauth_token_id = var.oauth_token_id
  }
  working_directory   = "02-hcp"
  execution_mode      = "remote"
  auto_apply          = true
  global_remote_state = true
  queue_all_runs      = false
}

// Need this for remote state sharing
resource "tfe_variable" "organization_name_for_hcp" {
  key          = "tfc_organization_name"
  value        = var.tfc_organization_name
  category     = "terraform"
  workspace_id = tfe_workspace.hcp.id
  description  = "Org Name"
}

resource "tfe_variable" "hcp_client_id" {
  key          = "HCP_CLIENT_ID"
  value        = "Provide me and make me sensitive"
  category     = "env"
  workspace_id = tfe_workspace.hcp.id
}

resource "tfe_variable" "hcp_client_secret" {
  key          = "HCP_CLIENT_SECRET"
  value        = "Provide me and make me sensitive"
  category     = "env"
  workspace_id = tfe_workspace.hcp.id
}

resource "tfe_run_trigger" "vpc_hcp" {
  workspace_id  = tfe_workspace.hcp.id
  sourceable_id = tfe_workspace.vpc.id
}
