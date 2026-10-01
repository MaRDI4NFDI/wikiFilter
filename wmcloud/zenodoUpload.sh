#!/bin/bash
# Upload files as a new version of a Zenodo record and leave it as a draft for review.
# Usage: zenodoUpload.sh <record> <metadata.json> <description.html> <file>...
# The metadata replace those of the previous version field by field.
set -euo pipefail

API=${ZENODO_API:-https://zenodo.org/api}
record=$1 metadata=$2 description=$3
shift 3
auth="Authorization: Bearer ${ZENODO_TOKEN:?Set ZENODO_TOKEN to a token with the deposit:write scope}"
json='Content-Type: application/json'

# Prints Zenodo's error message, which curl -f would swallow
zenodo() {
	local out
	out=$(curl -sSL --fail-with-body -H "$auth" "$@") || { echo "$out" >&2; return 1; }
	echo "$out"
}

latest=$(zenodo "$API/records/$record" | jq -r .id)
draft=$(zenodo -X POST "$API/records/$latest/versions")
id=$(jq -r .id <<< "$draft")
echo "New version $id of $latest"

jq --slurpfile m "$metadata" --rawfile d "$description" \
	'{access, files: {enabled: true}, custom_fields, metadata: (.metadata + $m[0]
		| .description = $d | .publication_date = (now | strftime("%Y-%m-%d")))}' <<< "$draft" |
	zenodo -X PUT -H "$json" --data-binary @- "$API/records/$id/draft" > /dev/null

for file in "$@"; do
	key=$(basename "$file")
	echo "Uploading $key"
	zenodo -X POST -H "$json" -d "[{\"key\": \"$key\"}]" "$API/records/$id/draft/files" > /dev/null
	zenodo -X PUT -H 'Content-Type: application/octet-stream' --upload-file "$file" \
		"$API/records/$id/draft/files/$key/content" > /dev/null
	zenodo -X POST "$API/records/$id/draft/files/$key/commit" > /dev/null
done

echo "Draft ready for review: ${API%/api}/uploads/$id"
