module "project" {
  source = "./modules/project"
}

module "droplet" {
  source             = "./modules/droplet"
  project_id         = module.project.project_id
  port_client_id     = var.port_client_id
  port_client_secret = var.port_client_secret
  aws_access_key     = var.aws_access_key
  aws_secret_key     = var.aws_secret_key
}