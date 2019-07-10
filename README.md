# Bits Service Release


**Please note: the Bits-Service is not actively maintained anymore. [More information](https://lists.cloudfoundry.org/g/cf-dev/message/8660).**


A [BOSH](http://docs.cloudfoundry.org/bosh/) release for deploying the [bits-service](https://github.com/cloudfoundry-incubator/bits-service).

## Deployment

### Deploy a CF on BOSH Lite with bits-service enabled

Simply follow instructions in [cf-deployment](https://github.com/cloudfoundry/cf-deployment) and the [Ops-file README for experimental](https://github.com/cloudfoundry/cf-deployment/blob/master/operations/experimental/README.md) to add `bits-service.yml` and other necessary Ops-files (documented there as well) to enable the Bits-Service.

## Run Tests

To run bits-service tests, you need to deploy it with upload size limits set to lower values.

Generate deployment manifest with `--size-limits` and deploy.
```
./scripts/generate-cf-with-bits-service-enabled-bosh-lite-manifest local --size-limits
```
Be advised that the deployment should have succeeded before at least once, otherwise CloudFoundry post-install scripts will fail to run with this stricter limits.

Configure test execution:

```sh
export BITS_SERVICE_PRIVATE_ENDPOINT_IP=10.244.0.74
export BITS_SERVICE_MANIFEST=./deployments/cf-with-bits-service-enabled.yml
export CC_API=https://api.bosh-lite.com
export CC_PASSWORD=xxx
export CC_USER=admin

./scripts/add-route
```

The following two lines need to be present in your `/etc/hosts` to run the tests:
```
10.244.0.74 bits-service.service.cf.internal bits-service.bosh-lite.com
10.244.0.130 blobstore.service.cf.internal
```

Then run:

```sh
bundle install
bundle exec rake
```

## CI Pipeline

The pipeline is publicly visible at https://ci.flintstone.cf.cloud.ibm.com. The sources are located at [bits-service-ci](https://github.com/cloudfoundry-incubator/bits-service-ci).
