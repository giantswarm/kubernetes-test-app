[![CircleCI](https://circleci.com/gh/giantswarm/kubernetes-test-app.svg?style=svg)](https://circleci.com/gh/giantswarm/kubernetes-test-app)
# kubernetes-managed-test-app
Testing app for managed app release flow

# Releasing
Create a release by pushing a tag to GitHub. The version must by SemVer format
(`major.minor.patch`).

```bash
> git tag -a [version] -m "Release [version]"
> git push origin [version]
```

Add Release notes by editing the published release here:

https://github.com/giantswarm/kubernetes-test-app/releases/edit/[version]

