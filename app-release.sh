#!/bin/bash

set -eu

REPONAME=$1
PERSONAL_ACCESS_TOKEN=$2

push() {
  echo "Pushing ${1} to ${2}"
  helm repo index ./ --merge https://giantswarm.github.com/${REPONAME} --url https://giantswarm.github.com/${REPONAME}
  git add ./$1 ./index.yaml
  git commit -m "Auto-commit ${1}"
  # git push origin master
  git push -q https://${PERSONAL_ACCESS_TOKEN}@github.com/giantswarm/${REPONAME}.git ${2}
  echo "Successfully pushed ${1} to GitHub Pages"
}

# Install helm and package chart
curl https://raw.githubusercontent.com/kubernetes/helm/master/scripts/get | bash
CHART=$(helm package --save=false helm/${REPONAME}-chart | tr "/" " " | awk '{print $NF}')

# Set up git
git config credential.helper 'cache --timeout=120'
git config user.email "dev@giantswarm.io"
git config user.name "Taylor Bot"

# Push to github
git co gh-pages
push ${CHART} gh-pages
