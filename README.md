# Bits Service Release

A [BOSH](http://docs.cloudfoundry.org/bosh/) release for deploying the [bits-service](https://github.com/cloudfoundry-incubator/bits-service).

# Deployment

## Deploy a CF on BOSH Lite with bits-service enabled

**Important**: We assume that you already deployed a CF to bosh-lite, with the deployment manifest in `cf-release/bosh-lite/deployments/cf.yml`.

1. Grab the bits-service-release

  ```
  git clone git@github.com:cloudfoundry-incubator/bits-service-release.git
  cd bits-service-release/
  ./scripts/update
  ```

1. Install `spruce` which is used to generate the bosh-lite manifest:

  ```
  brew install starkandwayne/cf/spruce
  ```

1. Generate the deployment manifest. Pass the backend to be used (`local`, `s3`, or `webdav`) as parameter. For example, for a bits-service with local backend:

  ```
  ./scripts/generate-cf-with-bits-service-enabled-bosh-lite-manifest local
  ```

1. Deploy

  ```
  bosh create release --force && bosh upload release && bosh -n deploy
  ```

  When prompted for the name of the bits-service release, accept the default `bits-service`.

# Run Tests

Configure test execution:

```sh
export BITS_SERVICE_PRIVATE_ENDPOINT=http://bits-service.service.cf.internal
export BITS_SERVICE_PUBLIC_ENDPOINT=http://bits-service.bosh-lite.com
export BITS_SERVICE_PRIVATE_ENDPOINT_IP=10.244.0.74
export BITS_SERVICE_MANIFEST=./deployments/bits-service-release.yml
export GOPATH=$PWD
```

Then run:

```sh
bundle install
bundle exec rake
```

If you run into errors like `Net::SSH::HostKeyMismatch`, you need to remove the offending entry from `~/.ssh/known_hosts`.

# CI Pipeline

The pipeline is publicly visible at [flintstone.ci.cf-app.com](https://flintstone.ci.cf-app.com). The sources are located at [bits-service-ci](https://github.com/cloudfoundry-incubator/bits-service-ci).
