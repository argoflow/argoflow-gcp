#!/bin/bash

if [ -z "$email" ]; then
  echo "Please set the env: email"
  exit 1
fi

if [ -z "$username" ]; then
  echo "Please set the env: username"
  exit 1
fi

if [ -z "$password" ]; then
  echo "Please set the env: password"
  exit 1
fi

DISTRIBUTION_PATH="./distribution"
OAUTH2_PROXY_SECRET=${DISTRIBUTION_PATH}/oidc-auth/oauth2-proxy-secret.yaml
DEX_CONFIG_SECRET=${DISTRIBUTION_PATH}/oidc-auth/dex-config-secret.yaml
DEX_CONFIG_TEMPLATE=${DISTRIBUTION_PATH}/oidc-auth/dex-config-template.yaml

COOKIE_SECRET=$(python3 -c 'import os, base64; print(base64.urlsafe_b64encode(os.urandom(16)).decode())')
OIDC_CLIENT_ID=$(python3 -c 'import secrets; print(secrets.token_hex(16))')
OIDC_CLIENT_SECRET=$(python3 -c 'import secrets; print(secrets.token_hex(32))')

ADMIN_PASS_DEX=$(python3 -c "from passlib.hash import bcrypt; print(bcrypt.using(rounds=12, ident='2y').hash(\"${password}\"))")

kubectl create secret generic -n auth oauth2-proxy \
  --from-literal=client-id=${OIDC_CLIENT_ID} \
  --from-literal=client-secret=${OIDC_CLIENT_SECRET} \
  --from-literal=cookie-secret=${COOKIE_SECRET} \
  --dry-run=client -o yaml | kubeseal | yq eval -P \
  > ${OAUTH2_PROXY_SECRET}

# yq eval -i ".data.ADMIN = \"${email}\"" ${DISTRIBUTION_PATH}/kubeflow/notebooks/profile-controller_access-management/patch-admin.yaml

yq eval ".staticClients[0].id = \"${OIDC_CLIENT_ID}\" | \
  .staticClients[0].secret = \"${OIDC_CLIENT_SECRET}\" | \
  .staticPasswords[0].hash = \"${ADMIN_PASS_DEX}\" | \
  .staticPasswords[0].email = \"${email}\" | \
  .staticPasswords[0].username = \"${username}\"" \
  ${DEX_CONFIG_TEMPLATE} | \
  kubectl create secret generic -n auth dex-config --dry-run=client --from-file=config.yaml=/dev/stdin -o yaml | \
  kubeseal | yq eval -P \
  > ${DEX_CONFIG_SECRET}
