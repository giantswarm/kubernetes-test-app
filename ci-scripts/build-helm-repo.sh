#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

readonly PROJECT=$1
readonly BRANCH=$2
readonly CIRCLECI_TOKEN=$3


main () {
  if ! trigger_build ${PROJECT} "${BRANCH}" "${CIRCLECI_TOKEN}"; then
    log_error "Build could not be triggered."
    exit 1
  fi

  echo "Successfully triggered catalog build"
}

trigger_build() {
  local project="${1?Specify project}"
  local branch="${2?Specify branch}"
  local circleci_token="${3?Specify token}"

  echo "Triggering build for branch $branch..."
  curl -X POST -H "Content-Type: application/json" \
    -d '{"branch": "'"$branch"'"}' \
    https://circleci.com/api/v1.1/project/github/giantswarm/"$project"/build\?circle-token="$circleci_token"
}

log_error() {
    printf '\e[31mERROR: %s\n\e[39m' "$1" >&2
}

main
