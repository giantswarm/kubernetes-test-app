#!/bin/bash

set -eu

curl https://raw.githubusercontent.com/kubernetes/helm/master/scripts/get | bash
tar=$(helm package --save=false helm/kubernetes-test-app-chart | tr "/" " " | awk '{print $NF}')
mkdir -p /home/circleci/.helm/plugins
helm plugin install https://github.com/technosophos/helm-github


git config credential.helper 'cache --timeout=120'
git config user.email "dev@giantswarm.io"
git config user.name "Taylor Bot"
helm github push $tar
