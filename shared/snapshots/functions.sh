SCRIPT_BASE_DIR="$(readlink -nf ${BASH_SOURCE[0]%/*})"

function build() {
    local name="$1" fn="$2"
    local prefix="$name/" suffix flags
    for snapshot in $(cs snapshot list -o json | jq -cMr '.[]|.meta.name') ; do
        suffix="${snapshot#$prefix}"
        # Check if name matches the prefix.
        [[ "$suffix" != "$snapshot" ]] || continue
        # Make sure suffix is a number.
        [[ "$((suffix))" != "0" ]] || continue
    
        if [[ -z "$SNAPSHOT_VERSION" ]]; then
            suffix=$((suffix+1))
        elif [[ "$SNAPSHOT_VERSION" != "last" ]]; then
            suffix="$SNAPSHOT_VERSION"
            flags="--force"
        fi
        echo "Build $snapshot -> $prefix$suffix"
        build_snapshot_$fn "$prefix$suffix" $flags
        return $?
    done

    # No matching, suffix starts from 1.
    echo "Build ${prefix}1"
    build_snapshot_$fn "${prefix}1"
}
