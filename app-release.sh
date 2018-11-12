#!/bin/bash

set -eu

curl https://raw.githubusercontent.com/kubernetes/helm/master/scripts/get | bash
helm package helm/kubernetes-test-app-chart
tar=$(helm package --save=false helm/kubernetes-test-app-chart | awk '{print $NF}')
helm plugin install https://github.com/technosophos/helm-github
helm github push $tar
