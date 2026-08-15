#!/usr/bin/env bash
set -euo pipefail

source ./env.sh

envsubst < ./templates/tenant-secret.yaml > ./manifest/tenant-secret.yaml
envsubst < ./templates/tenant-cluster.yaml > ./manifest/tenant-cluster.yaml
envsubst < ./templates/tenant-cluster2.yaml > ./manifest/tenant-cluster2.yaml
echo "[Tenant Cluster Resources Generated]"
