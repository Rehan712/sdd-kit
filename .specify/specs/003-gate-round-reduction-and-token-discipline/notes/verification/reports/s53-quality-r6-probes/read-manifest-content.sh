set -u
. scripts/lib.sh
. scripts/verification-lib.sh
n=0
while IFS= read -r -d '' path; do
  n=$((n+1))
  vf_path_content "$1" "$path" "$2/path-$n" || exit 3
done < "$3"
