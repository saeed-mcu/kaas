# Install Kind
kind is a tool for running local Kubernetes clusters.

## Local Repository
### Python

```bash
cat > /etc/pip.conf <<\EOF
[global]
index-url = https://artifactory.digikala.com/artifactory/api/pypi/pypi-proxy/simple
trusted-host = https://artifactory.digikala.com
EOF
```

```bash
cat > /root/.pypirc <<\EOF
[distutils]
index-servers = local
[local]
repository: https://artifactory.digikala.com/artifactory/api/pypi/pypi-proxy
EOF
```

### Ubuntu 26.04

```bash
cat > /etc/apt/sources.list.d/ubuntu.sources << EOF
Types: deb
URIs: https://artifactory.digikala.com/artifactory/ubuntu-proxy/
Suites: resolute resolute-updates resolute-backports
Components: main restricted universe multiverse
Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg

Types: deb
URIs: https://artifactory.digikala.com/artifactory/ubuntu-proxy/
Suites: resolute-security
Components: main restricted universe multiverse
Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg
EOF
```

### Ubuntu 24.04
```bash
cat > /etc/apt/sources.list.d/ubuntu.sources << EOF
Types: deb
URIs: https://artifactory.digikala.com/artifactory/ubuntu-proxy/
Suites: noble noble-updates noble-backports
Components: main restricted universe multiverse
Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg

Types: deb
URIs: https://artifactory.digikala.com/artifactory/ubuntu-proxy/
Suites: noble-security
Components: main restricted universe multiverse
Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg
EOF
```

### Proxy

```bash
cat > /etc/environment << EOF
PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/snap/bin"
export NO_PROXY=.digicloud.ir,.digikala.com,93.113.225.22,172.16.140.19,172.16.139.230,localhost,127.0.0.1,172.16.140.98,172.16.140.63,172.16.9.106,172.16.140.12
export no_proxy=.digicloud.ir,.digikala.com,93.113.225.22,172.16.140.19,172.16.139.230,localhost,127.0.0.1,172.16.140.98,172.16.140.63,172.16.9.106,172.16.140.12
export http_proxy=http://172.30.23.24:8000/
export https_proxy=http://172.30.23.24:8000/
export HTTP_PROXY=http://172.30.23.24:8000/
export HTTPS_PROXY=http://172.30.23.24:8000/
EOF
```

## Docker
```bash
sudo apt update
sudo apt install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

sudo tee /etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://artifactory.digikala.com/artifactory/docker-ubuntu-proxy/
Suites: $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")
Components: stable
Architectures: $(dpkg --print-architecture)
Signed-By: /etc/apt/keyrings/docker.asc
EOF
```

```bash
sudo apt update
sudo apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y
```

## kubectl
```bash
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
mv kubectl /usr/local/bin/
echo 'source <(kubectl completion bash)' >> /etc/bash_completion.d/kubectl-rc
echo 'alias k=kubectl' >> /etc/bash_completion.d/kubectl-rc
echo 'complete -o default -F __start_kubectl k' >> /etc/bash_completion.d/kubectl-rc
```

## helm
```bash
wget -c https://get.helm.sh/helm-v4.2.3-linux-amd64.tar.gz
tar -zxvf helm-v4.2.3-linux-amd64.tar.gz
mv linux-amd64/helm /usr/local/bin/
helm version

echo 'source <(helm completion bash)' >> /etc/bash_completion.d/helm-rc
echo 'alias h=helm' >> /etc/bash_completion.d/helm-rc
echo 'complete -o default -F __start_helm h' >> /etc/bash_completion.d/helm-rc
```

## Kind
```bash
wget -c https://github.com/kubernetes-sigs/kind/releases/download/v0.32.0/kind-linux-amd64
chmod +x ./kind-linux-amd64
sudo mv ./kind-linux-amd64 /usr/local/bin/kind
```
### kind config
```bash
mkdir -p /opt/kind/

sudo tee /opt/kind/kind-config.yaml <<EOF
---
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4

nodes:
- role: control-plane
  extraPortMappings:
    - listenAddress: "127.0.0.1"
      containerPort: 6443
      hostPort: 6443
    # public ip of server
    - listenAddress: "172.16.139.230"
      containerPort: 6443
      hostPort: 6443
  extraMounts:
    - hostPath: /opt/kind/docker.toml
      containerPath: /etc/containerd/certs.d/docker.io/hosts.toml
    - hostPath: /opt/kind/k8s.toml
      containerPath: /etc/containerd/certs.d/registry.k8s.io/hosts.toml
    - hostPath: /opt/kind/quay.toml
      containerPath: /etc/containerd/certs.d/quay.io/hosts.toml
    - hostPath: /opt/kind/90-registry.toml
      containerPath: /etc/containerd/conf.d/90-registry.toml
EOF
```

```bash
sudo tee /opt/kind/docker.toml <<EOF
server = "https://docker.io"
[host."https://artifactory.digikala.com/v2/docker"]
  capabilities = ["pull","resolve"]
  skip_verify = true
  override_path = true
EOF
```

```bash
sudo tee /opt/kind/k8s.toml <<EOF
server = "https://registry.k8s.io"
[host."https://artifactory.digikala.com/v2/k8s"]
  capabilities = ["pull","resolve"]
  skip_verify = true
  override_path = true
EOF
```

```bash
sudo tee /opt/kind/quay.toml <<EOF
server = "https://quay.io"
[host."https://artifactory.digikala.com/v2/docker-proxy-quay"]
  capabilities = ["pull","resolve"]
  skip_verify = true
  override_path = true
EOF
```

```bash
sudo tee /opt/kind/90-registry.toml <<EOF
  [plugins."io.containerd.cri.v1.images".registry]
     config_path = "/etc/containerd/certs.d"
EOF
```
## Create Kind Cluster
```bash
kind create cluster --image=artifactory.digikala.com/docker/kindest/node:v1.36.1 --name kamaji --config /opt/kind/kind-config.yaml
```
k8s config file
```bash
cat ~/.kube/config
```
kind commands:
```
kind get clusters
kind delete cluster --name=${cluster}
```
