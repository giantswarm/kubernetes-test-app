#!/bin/sh

# Script to publish a release

PROJECT=kubernetes-test-app

DATE=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
SHA=$(git pull origin master > /dev/null 2>&1 & git rev-parse master)
VERSION=$(cat ../VERSION)

# Github personal access token of Github user
GITHUB_TOKEN=$(cat ~/.github-token)


echo "Creating Tag ${PROJECT} v${VERSION}"
tag_output=$(curl \
    --request POST \
    --header "Authorization: token ${GITHUB_TOKEN}" \
    --header "Content-Type: application/json" \
    --data "{
        \"tag\": \"v${VERSION}\",
        \"message\": \"Automated tag for ${VERSION}\",
        \"object\": \"${SHA}\",
        \"type\": \"commit\",
        \"tagger\": {
            \"name\": \"taylorbot\",
            \"email\": \"dev@giantswarm.io\",
            \"date\": \"${DATE}\"
        }
    }" \
    https://api.github.com/repos/giantswarm/${PROJECT}/git/tags
)
echo $tag_output | jq

echo "Creating Github release ${PROJECT} v${VERSION}"
release_output=$(curl -s \
    -X POST \
    -H "Authorization: token ${GITHUB_TOKEN}" \
    -H "Content-Type: application/json" \
    -d "{
        \"tag_name\": \"${VERSION}\",
        \"name\": \"v${VERSION}\",
        \"body\": \"### New features\\n\\n### Minor changes\\n\\n### Bugfixes\\n\\n\",
        \"draft\": true,
        \"prerelease\": false
    }" \
    https://api.github.com/repos/giantswarm/${PROJECT}/releases
)
echo $release_output | jq

# fetch the release id for the upload
RELEASE_ID=$(echo $release_output | jq '.id')

# echo "Upload chart archive to GitHub Release"
# cd bin-dist
# for FILENAME in *.zip *.tar.gz; do
#     [ -f "$FILENAME" ] || break
#     curl \
#       -H "Authorization: token ${GITHUB_TOKEN}" \
#       -H "Content-Type: application/octet-stream" \
#       --data-binary @${FILENAME} \
#         https://uploads.github.com/repos/giantswarm/${PROJECT}/releases/${RELEASE_ID}/assets?name=${FILENAME}
# done
# cd ..

echo "Done. The release is now prepared, but not yet published."
echo "You can now edit your release description here:"
echo "https://github.com/giantswarm/${PROJECT}/releases/"
