#!/bin/bash

# Update packages and install prerequisites


sudo apt-get install docker.io
docker --version

curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
helm version

sudo apt update -y

sudo apt install -y unzip curl
 

curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"

unzip awscliv2.zip

sudo ./aws/install

aws --version
 

curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"

chmod +x ./kubectl

sudo mv ./kubectl /usr/local/bin/kubectl

kubectl version --client
 

curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz

sudo mv eksctl /usr/local/bin

eksctl version
