#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

readonly PROJECT=$1
readonly TAG=$2
readonly GITHUB_TOKEN=$3

readonly HELM_URL=https://storage.googleapis.com/kubernetes-helm
readonly HELM_TARBALL=helm-v2.11.0-linux-amd64.tar.gz

main() {
  if ! setup_helm_client; then
    log_error "Helm client could not get installed"
    exit 1
  fi

  if ! id=$(release_github "${PROJECT}" "${TAG}" "${GITHUB_TOKEN}"); then
    log_error "GitHub Release could not get created"
    exit 1
  fi

  if ! upload_assets "${PROJECT}" "${TAG}" "${GITHUB_TOKEN}" "${id}"; then
    log_error "Assets could not be uploaded to GitHub"
    exit 1
  fi

}

setup_helm_client() {
    echo "Setting up Helm client..."

    curl --user-agent curl-ci-sync -sSL -o "${HELM_TARBALL}" "${HELM_URL}/${HELM_TARBALL}"
    tar xzfv "${HELM_TARBALL}"

    PATH="$(pwd)/linux-amd64/:$PATH"

    helm init --client-only
}

release_github() {
  local project="${1?Specify project}"
  local version="${2?Specify version}"
  local token="${3?Specify Github Token}"

  wget --no-check-certificate "https://github.com/giantswarm/${project}/tarball/${version}" > /dev/null 2>&1
  release_exists=$?
  if [ "${release_exists}" -eq 0 ]; then
    log_error "Release already exists."
    return 1
  fi

  echo "Creating Github release ${version}"
  release_output=$(curl -s \
      -X POST \
      -H "Authorization: token ${token}" \
      -H "Content-Type: application/json" \
      -d "{
          \"tag_name\": \"${version}\",
          \"name\": \"${version}\",
          \"body\": \"### New features\\n\\n### Minor changes\\n\\n### Bugfixes\\n\\n\",
          \"draft\": false,
          \"prerelease\": false
      }" \
      "https://api.github.com/repos/giantswarm/${project}/releases"
  )
  echo "The Github release is now published."
  echo "Please add release notes here:"
  echo "https://github.com/giantswarm/${project}/releases/edit/${version}"

  echo "${release_output}"
  # Return release id for the asset upload
  release_id=$(echo "${release_output}" | jq '.id')
  echo "${release_id}"
  return 0
}

upload_assets(){
  local project="${1?Specify project}"
  local version="${2?Specify version}"
  local token="${3?Specify Github Token}"
  local release_id="${4?Specify Release Id}"

  # Replace CI version with release version
  sed -i 's/version:.*/version: '"${version}"'/' "helm/${project}-chart/Chart.yaml"
  chart=$(helm package --save=false "helm/${project}-chart" | tr "/" " " | awk '{print $NF}')

  echo "Upload chart ${chart} to GitHub Release"
  upload_output=$(curl -s \
        -H "Authorization: token ${token}" \
        -H "Content-Type: application/octet-stream" \
        --data-binary @"${chart}" \
          "https://uploads.github.com/repos/giantswarm/${project}/releases/${release_id}/assets?name=${chart}"
  )
  echo "${upload_output}"
  exit 0
}

log_error() {
    printf '\e[31mERROR: %s\n\e[39m' "$1" >&2
}

main
