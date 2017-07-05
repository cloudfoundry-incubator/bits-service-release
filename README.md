# Bits Service Release

A [BOSH](http://docs.cloudfoundry.org/bosh/) release for deploying the [bits-service](https://github.com/cloudfoundry-incubator/bits-service).

## Deployment

### Deploy a CF on BOSH Lite with bits-service enabled

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

    When targeting an S3 blobstore, the following environment variables are required to be set. Otherwise you can skip this step.

    ```
    export BITS_DIRECTORY_KEY=
    export AWS_ACCESS_KEY_ID=
    export AWS_SECRET_ACCESS_KEY=
    export BITS_AWS_REGION=
    ```

1. Deploy

    ```
    bosh create release --force && bosh upload release && bosh -n deploy
    ```

    When prompted for the name of the bits-service release, accept the default `bits-service`.

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

The pipeline is publicly visible at [flintstone.ci.cf-app.com](https://flintstone.ci.cf-app.com). The sources are located at [bits-service-ci](https://github.com/cloudfoundry-incubator/bits-service-ci).

## Certificate generation
We used CA credentials as provided by `cf-release/templates/bosh-lite-fixtures/server-ca.{crt,key}`. To generate bits-service certificate and key, the following commands have been issued:
```console
certstrap init --key server-ca.key --cn 'bbsCA'
certstrap request-cert --passphrase '' --common-name bits-service
certstrap sign bits-service --CA bbsCA
```

You can pick up you new credentials from `./out/bits-service.{crt,key}`.

Pay extra attention to CA's common name: it absolutely needs to be 'bbsCA' for the certificates to work correctly.

## Troubleshooting
### Failed TCP connections
If you run into connection errors like this one: `Failed to open TCP connection to 10.250.0.2.xip.io:80 (getaddrinfo: nodename nor servname provided, or not known)` try cleaning your DNS cache. On MacOS Sierra (10.12) you can do this with:
```console
sudo killall -HUP mDNSResponder
```

### Failed SSH connections
If you run into errors like `Net::SSH::HostKeyMismatch`, you need to remove the offending entry from `~/.ssh/known_hosts`.
```console
ssh-keygen -R $offending_ip
```
