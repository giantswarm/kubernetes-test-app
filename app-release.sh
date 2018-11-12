#!/bin/bash

set -eu

curl https://raw.githubusercontent.com/kubernetes/helm/master/scripts/get | bash
tar=$(helm package --save=false helm/kubernetes-test-app-chart | awk '{print $NF}')
mkdir -p /home/circleci/.helm/plugins
helm plugin install https://github.com/technosophos/helm-github
helm github push $tar
