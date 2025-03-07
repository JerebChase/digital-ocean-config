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

  user_data = <<-EOF
    #!/bin/bash
    set -e

    # Log everything
    exec > /var/log/user-data.log 2>&1
    export HOME=/root

    # Install k3s
    curl -sfL https://get.k3s.io | sh -
    echo "Waiting for K3s to be ready..."
    until kubectl get nodes; do sleep 5; done
    export KUBECONFIG=/etc/rancher/k3s/k3s.yaml

    # Install Kustomize
    curl -s "https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh"  | bash
    mv /root/kustomize /usr/local/bin/kustomize
    chmod +x /usr/local/bin/kustomize

    # Install Helm
    curl -LO https://get.helm.sh/helm-v3.13.2-linux-amd64.tar.gz
    tar -xzvf helm-v3.13.2-linux-amd64.tar.gz
    sudo mv linux-amd64/helm /usr/local/bin/helm

    # Install UXP Crossplane
    # kubectl create namespace crossplane
    # curl -sL https://cli.upbound.io | sh
    # sudo mv up /usr/local/bin/
    # up uxp install -n crossplane

    # Create crossplane secret
    # kubectl create secret generic aws-secret \
    #   --namespace crossplane \
    #   --from-literal=creds="{\"aws_access_key_id\":\"${var.aws_access_key}\",\"aws_secret_access_key\":\"${var.aws_secret_key}\"}"

    # Install Port K8s Exporter
    # helm repo add --force-update port-labs https://port-labs.github.io/helm-charts 
    # helm upgrade --install my-cluster port-labs/port-k8s-exporter \
    #   --create-namespace --namespace port-k8s-exporter \
    #   --set secret.secrets.portClientId="${var.port_client_id}" \
    #   --set secret.secrets.portClientSecret="${var.port_client_secret}" \
    #   --set portBaseUrl="https://api.getport.io" \
    #   --set stateKey="my-cluster" \
    #   --set integration.eventListener.type="POLLING" \
    #   --set "extraEnv[0].name"="CLUSTER_NAME" \
    #   --set "extraEnv[0].value"="my-cluster"

    # Install ArgoCD
    kubectl apply -k https://raw.githubusercontent.com/JerebChase/gitops-config/main/argocd/install

    echo "Setup complete!"
  EOF
}

resource "digitalocean_project_resources" "project_resources" {
  project = var.project_id
  resources = [
    digitalocean_droplet.droplet.urn
  ]
}