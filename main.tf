module "project" {
  source = "./modules/project"
}

module "droplet" {
  source     = "./modules/droplet"
  project_id = module.project.project_id
}