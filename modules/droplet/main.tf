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
  image  = "ubuntu-20-04-x64"
  region = "nyc3"
  size   = "s-1vcpu-2gb"
  ssh_keys = [
    digitalocean_ssh_key.terraform_ssh_key.id
  ]

  connection {
    host = self.ipv4_address
    user = "root"
    type = "ssh"
    private_key = tls_private_key.ssh_key.private_key_pem
    timeout = "2m"
  }
  
  provisioner "remote-exec" {
    inline = [
      # install k3s
      "curl -sfL https://get.k3s.io | sh -",
      "export KUBECONFIG=/etc/rancher/k3s/k3s.yaml",
      # install argocd
      "kubectl create namespace argocd",
      "kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml",
      "kubectl patch svc argocd-server -n argocd -p '{\"spec\": {\"type\": \"LoadBalancer\"}}'",
      # install UXP Crossplane
      "kubectl create namespace crossplane",
      "curl -sL https://cli.upbound.io | sh",
      "sudo mv up /usr/local/bin/",
      "up uxp install -n crossplane",
      # install Helm
      "curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3",
      "chmod 700 get_helm.sh",
      "./get_helm.sh",
      # install Port K8s Exporter
      "helm repo add --force-update port-labs https://port-labs.github.io/helm-charts",
      "helm upgrade --install my-cluster port-labs/port-k8s-exporter \\",
      "   --create-namespace --namespace port-k8s-exporter \\",
      "   --set secret.secrets.portClientId='" + var.port_client_id + "' \\",
      "   --set secret.secrets.portClientSecret='" + var.port_client_secret + "' \\",
      "   --set portBaseUrl='https://api.getport.io' \\",
      "   --set stateKey='my-cluster \\",
      "   --set integration.eventListener.type='POLLING' \\",
      "   --set 'extraEnv[0].name'='CLUSTER_NAME' \\",
      "   --set 'extraEnv[0].value'='my-cluster'"
    ]
  }
}

resource "digitalocean_project_resources" "project_resources" {
  project = var.project_id
  resources = [
    digitalocean_droplet.droplet.urn
  ]
}