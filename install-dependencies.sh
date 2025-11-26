#!/bin/bash
set -e

echo "===== Checking Existing Tools ====="
which aws >/dev/null 2>&1 && echo "AWS CLI already installed" || INSTALL_AWS=true
which kubectl >/dev/null 2>&1 && echo "kubectl already installed" || INSTALL_KUBECTL=true
which eksctl >/dev/null 2>&1 && echo "eksctl already installed" || INSTALL_EKSCTL=true
which terraform >/dev/null 2>&1 && echo "terraform already installed" || INSTALL_TERRAFORM=true

echo "===== Installing Missing Tools ====="

# Install AWS CLI
if [ "$INSTALL_AWS" = true ]; then
    echo "Installing AWS CLI..."
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    sudo apt install unzip -y
    sudo unzip awscliv2.zip
    sudo ./aws/install
    aws --version
fi

# Install eksctl
if [ "$INSTALL_EKSCTL" = true ]; then
    echo "Installing eksctl..."
    curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" \
    | tar xz -C /tmp
    sudo mv /tmp/eksctl /usr/local/bin
    eksctl version
fi

# Install kubectl
if [ "$INSTALL_KUBECTL" = true ]; then
    echo "Installing kubectl..."
    sudo curl --silent --location -o /usr/local/bin/kubectl \
    https://s3.us-west-2.amazonaws.com/amazon-eks/1.22.6/2022-03-09/bin/linux/amd64/kubectl
    sudo chmod +x /usr/local/bin/kubectl
    kubectl version --short --client
fi

# Install Terraform
if [ "$INSTALL_TERRAFORM" = true ]; then
    echo "Installing Terraform..."
    sudo apt install curl gnupg software-properties-common -y
    curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
    sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
    sudo apt-get update
    sudo apt install terraform -y
    terraform -v
fi

echo "===== All tools installed successfully ====="
