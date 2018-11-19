#!/bin/sh

# Script to release a managed app

PROJECT=kubernetes-test-app
DATE=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
SHA=$(git pull origin master > /dev/null 2>&1 & git rev-parse HEAD)
VERSION=$(cat ./VERSION)

usage() {
cat << EOF

Managed Apps Release Script

Create a Git tag and GitHub release based on the SemVer specified in
the VERSION file of the current project. The CI-Pipeline will push
the chart to Helm repositories which are defined in the CATALOGS file,
on detection of a the new SemVer Git Tag.

Note: A valid Github Token with write access to the repo has to be placed
      in '${HOME}/.github_token' or are set as ENV \$GITHUB_TOKEN.

      https://help.github.com/articles/creating-a-personal-access-token-for-the-command-line/
EOF
}

release() {
  echo "Releasing ${PROJECT}..."
  echo "Creating Tag v${VERSION}"
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
  echo ${tag_output} | jq
  echo "Done. The managed app will now be pushed to a helm repo."
  echo ""

  echo "Creating Github release v${VERSION}"
  release_output=$(curl -s \
      -X POST \
      -H "Authorization: token ${GITHUB_TOKEN}" \
      -H "Content-Type: application/json" \
      -d "{
          \"tag_name\": \"v${VERSION}\",
          \"name\": \"v${VERSION}\",
          \"body\": \"### New features\\n\\n### Minor changes\\n\\n### Bugfixes\\n\\n\",
          \"draft\": false,
          \"prerelease\": false
      }" \
      https://api.github.com/repos/giantswarm/${PROJECT}/releases
  )
  echo "The Github release is now published."
  echo "Please add release notes here:"
  echo "https://github.com/giantswarm/${PROJECT}/releases/edit/v${VERSION}"

  # fetch the release id for the upload
  RELEASE_ID=$(echo $release_output | jq '.id')

  # Replace CI version with release VERSION
  sed -i 's/version:.*/version: '${VERSION}'/' helm/${PROJECT}-chart/Chart.yaml

  # Install helm and package chart TODO: Not use latest helm
  curl https://raw.githubusercontent.com/kubernetes/helm/master/scripts/get | bash
  CHART=$(helm package --save=false helm/${PROJECT}-chart | tr "/" " " | awk '{print $NF}')
  echo "Upload chart ${CHART} to GitHub Release"
  upload_output=$(curl -s \
        -H "Authorization: token ${GITHUB_TOKEN}" \
        -H "Content-Type: application/octet-stream" \
        --data-binary @${CHART} \
          https://uploads.github.com/repos/giantswarm/${PROJECT}/releases/${RELEASE_ID}/assets?name=${CHART}
  )

  # Cleanup
  git checkout helm/${PROJECT}-chart/Chart.yaml
  rm -f ${CHART}
}

wget --no-check-certificate https://github.com/giantswarm/${PROJECT}/tarball/v${VERSION} > /dev/null 2>&1
if [ $? -eq 0 ];then
  echo "Release already exists. Did you increment the version in the VERSION file?"
  exit 1
elif ! [ -z "${GITHUB_TOKEN}" ]; then
  release
elif [ -e "${HOME}/.github-token" ]; then
  GITHUB_TOKEN=$(cat ${HOME}/.github-token)
  release
else
  echo "Error: No GitHub token found!"
  usage
  exit 1
fi
