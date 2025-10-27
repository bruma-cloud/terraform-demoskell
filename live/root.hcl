#
# The root terragrunt file is the bootstrap of terragrunt command.
#
locals {
  owner        = "Example"
  project_name = "example"

  ###########
  # IMPORTS #
  ###########
  variables = read_terragrunt_config(find_in_parent_folders("variables.hcl")).inputs
  versions  = read_terragrunt_config("versions.hcl").inputs

  ###########
  # COMPUTE #
  ###########

  # Return [{module}, {env}, {live}, ...]
  reverse_path = reverse(split("/", get_original_terragrunt_dir()))
  module       = local.reverse_path[0]
  env          = local.reverse_path[1]
}

####################
# Terraform Config #
####################
terraform {
  # Module to call
  source = "${local.root_dir}/../modules//${local.module}"
}

#####################
# Generic Providers #
#####################

# The default generated providers.tf
generate "providers" {
  path      = "providers.tf"
  if_exists = "overwrite"
  contents  = file("${local.root_dir}/_terraform/providers.hcl")
}

######################
# VARIABLE INJECTION #
######################

# Merge input from other terragrunt files.
inputs = merge(local.variables, local.versions, {

  # Tags for resources (for AWS providers)
  # See recommended AWS tags : <>
  aws_default_provider = {
    region       = "eu-west-1"
    profile      = "common"
    default_tags = {
      Environment   = local.env
      Cluster       = local.module
      Project       = local.project_name
      Terraform     = true
      Module        = local.module
      Owner         = local.owner
    }
  }

  kubernetes_default_provider = {
    config_path    = local.env == "local" ? "~/.kube/config" : "~/.kube/${local.project_name}-${local.env}.yaml"
    config_context = local.env == "local" ? "minikube" : null
  }

  labels = {
    "app.kubernetes.io/part-of"    = local.project_name
    "app.kubernetes.io/managed-by" = "Terraform"
  }
})
