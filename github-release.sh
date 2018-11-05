PROJECT=$1
SHA=$2
PERSONAL_ACCESS_TOKEN=$3

SHORT_SHA=$(echo ${SHA} | head -c 7)
DATE=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

echo "Creating GitHub Release"
release_output=$(curl \
    --request POST \
    --header "Authorization: token ${PERSONAL_ACCESS_TOKEN}" \
    --header "Content-Type: application/json" \
    --data "{
        \"tag_name\": \"${SHORT_SHA}\",
        \"name\": \"${SHORT_SHA}\",
        \"body\": \"Automated release for ${SHORT_SHA}.\",
        \"draft\": false,
        \"prerelease\": false
    }" \
    https://api.github.com/repos/giantswarm/${PROJECT}/releases
)
echo $release_output | jq

# fetch the release id for the upload
RELEASE_ID=$(echo $release_output | jq '.id')

# TODO
# echo "Upload chart tgz to GitHub Release"
# upload_output=$(curl \
#     --header "Authorization: token ${PERSONAL_ACCESS_TOKEN}" \
#     --header "Content-Type: application/octet-stream" \
#     --data-binary @${PROJECT} \
#     https://uploads.github.com/repos/giantswarm/${PROJECT}/releases/${RELEASE_ID}/assets?name=${PROJECT}
# )
# echo $upload_output | jq

echo "Done!"
