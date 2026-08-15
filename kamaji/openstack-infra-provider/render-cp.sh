#!/usr/bin/env bash
set -euo pipefail

source ./env.sh

envsubst < ./templates/control-plane-secret.yaml > ./manifest/control-plane-secret.yaml
envsubst < ./templates/control-plane-cluster.yaml > ./manifest/control-plane-cluster.yaml
envsubst < ./templates/helm.yaml > ./manifest/helm.yaml

echo "[Cluster Resources Generated]"
