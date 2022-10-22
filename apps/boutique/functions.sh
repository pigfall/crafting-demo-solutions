function fatal() {
    echo "$@" >&2
    exit 1
}

APP_DIR="$(readlink -nf ${BASH_SOURCE[0]%/*})"
: ${SRC_DIR:="$(readlink -nf $APP_DIR/../../../demo)"}
K8S_MANIFEST_FILE="$SRC_DIR/release/kubernetes-manifests.yaml"
NAMESPACE="${SANDBOX_APP}-${SANDBOX_ID}"

[[ -f "$K8S_MANIFEST_FILE" ]] || fatal "Not found: $K8S_MANIFEST_FILE"
