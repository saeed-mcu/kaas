export CLUSTER_NAMESPACE=kamaji-system

export OPENSTACK_EXTERNAL_NETWORK_ID=ce4fe159-252e-4f1d-a81a-87653063f922
export OPENSTACK_FLAVOR=g1.xlarge
export OPENSTACK_SSH_KEY_NAME=compute-team
export OPENSTACK_DNS_NAMESERVERS='[172.16.131.11 ,172.16.131.12, 172.16.140.2]'
export OPENSTACK_VOLUME_TYPE_SSD="RBD_SSD"
export OPENSTACK_VOLUME_TYPE_HDD="RBD_HDD"
export OPENSTACK_VOLUME_TYPE_SAN="SAN"
export OPENSTACK_IMAGE_NAME=ubuntu-26.04-kube-v1.36.1

export KUBERNETES_VERSION=v1.36.1
export CONTROL_PLANE_CLUSTER_NAME=kamaji-cp
export WORKLOAD_TENANT_CLUSTER_NAME=tenant-cluster
export CONTROL_PLANE_CLUSTER_KUBECONFIG_SECRET_NAME="${CONTROL_PLANE_CLUSTER_NAME}-kubeconfig"

export CONTROL_PLANE_ENDPOINT_HOST="172.16.139.174"
#------------------------------------------
# Prepare clouds.yaml and cloud.conf
#------------------------------------------
# export OPENSTACK_APP_CREDENTIAL_ID=$(openstack --os-project-id "$TARGET_PROJECT_ID" application credential show "$OPENSTACK_APP_CREDENTIAL_NAME" -f value -c id)
export OPENSTACK_APP_CREDENTIAL_SECRET="223d5e99b5b58920704704f0"
export OPENSTACK_APP_CREDENTIAL_ID="98b4b413ea654e3790a6230bcb4ac954"

export OPENSTACK_CLOUD_NAME=openstack-stage
export OPENSTACK_AUTH_URL=https://iaas-vp-internal.digicloud.ir:5000/v3
export OPENSTACK_REGION_NAME=ir-vanak-plaza
export OPENSTACK_INTERFACE=public
export OPENSTACK_IDENTITY_API_VERSION=3
export OPENSTACK_TLS_INSECURE=true

export CLOUDS_YAML_CONTENT="$(cat <<EOF
clouds:
  ${OPENSTACK_CLOUD_NAME}:
    auth:
      auth_url: ${OPENSTACK_AUTH_URL}
      application_credential_id: ${OPENSTACK_APP_CREDENTIAL_ID}
      application_credential_secret: ${OPENSTACK_APP_CREDENTIAL_SECRET}
    auth_type: v3applicationcredential
    region_name: ${OPENSTACK_REGION_NAME}
    interface: ${OPENSTACK_INTERFACE}
    identity_api_version: ${OPENSTACK_IDENTITY_API_VERSION}
EOF
)"
export REPLACE_BASE64_CLOUDS_YAML=$(printf '%s' "$CLOUDS_YAML_CONTENT" | base64 | tr -d '\n')

export CLOUD_CONF_CONTENT="$(cat <<EOF
[Global]
auth-url=${OPENSTACK_AUTH_URL}
application-credential-id=${OPENSTACK_APP_CREDENTIAL_ID}
application-credential-secret=${OPENSTACK_APP_CREDENTIAL_SECRET}
region=${OPENSTACK_REGION_NAME}
tls-insecure=${OPENSTACK_TLS_INSECURE}
interface=public
identity-api-version=3
auth-type=v3applicationcredential
EOF
)"
export REPLACE_BASE64_CLOUD_CONF=$(printf '%s' "$CLOUD_CONF_CONTENT" | base64 | tr -d '\n')
