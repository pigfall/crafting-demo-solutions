#!/bin/bash

readonly METRIC="sandbox_problematic_workloads_count"

STATUS_JSON="$(cs -O $SANDBOX_ORG sandbox list -o json)"

function sandbox_names() {
    jq -cMr '.[]|.meta.name' <<<"$STATUS_JSON"
}

function workload_status() {
    jq -cMr '.[]|select(.meta.name == "'"$1"'").status.workloads[]|"\(.status.state)"' <<<"$STATUS_JSON"
}

echo "# TYPE $METRIC gauge"
echo "# HELP $METRIC The number of PROMBLEMATIC workloads in a sandbox"

for sandbox in $(sandbox_names) ; do
    count=0
    for state in $(workload_status "$sandbox"); do
        case "$state" in
        PROBLEMATIC|ERROR) count=$((count+1)) ;;
        *) ;;
        esac
    done
    echo "$METRIC"' {sandbox="'"$sandbox"'"} '"$count"
done
