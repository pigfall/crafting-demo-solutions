#!/bin/bash

. "${BASH_SOURCE[0]%/*}/functions.sh"

kubectl delete ns "$NAMESPACE" >&2
