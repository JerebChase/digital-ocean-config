provider "digitalocean" {}

resource "digitalocean_project" "project" {
  name = "My Test Project"
}