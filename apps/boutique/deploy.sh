#!/bin/bash

. "${BASH_SOURCE[0]%/*}/functions.sh"

# Ignore the error in case namespace exists.
kubectl create ns "$NAMESPACE" 2>/dev/null || true

# Remove Load Balancer and loadgenerator.
yaml2json < "$K8S_MANIFEST_FILE" | \
    jq -cMr '.|select(.spec.type != "LoadBalancer" and .metadata.name != "loadgenerator")' | \
    kubectl -n "$NAMESPACE" apply -f - >&2

cat <<EOF
{
    "namespace": "$NAMESPACE"
}
EOF
