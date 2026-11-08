set -euo pipefail
. scripts/lib.sh
. scripts/verification-lib.sh
vf_snapshot "$1" "$PWD" "$PWD" "$2"
