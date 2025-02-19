terraform {
  required_providers {
    digitalocean = {
      source = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
    tls = {
      source = "hashicorp/tls"
    }
  }
}

resource "tls_private_key" "ssh_key" {
  algorithm = "ED25519" 
}

resource "digitalocean_ssh_key" "terraform_ssh_key" {
  name       = "terraform-ssh-key"
  public_key = tls_private_key.ssh_key.public_key_openssh
}

resource "digitalocean_droplet" "droplet" {
  name   = "test-droplet"
  image  = "ubuntu-18-04-x64"
  region = "nyc3"
  size   = "s-1vcpu-2gb"
  ssh_keys = [
    digitalocean_ssh_key.terraform_ssh_key.id
  ]
}