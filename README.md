# Bits Service Release

A [BOSH](http://docs.cloudfoundry.org/bosh/) release for deploying [Bits Service](https://github.com/cloudfoundry-incubator/bits-service).

## Deploy to BOSH Lite
### Get the bits-service-release

```
git clone git@github.com:cloudfoundry-incubator/bits-service-release.git
cd bits-service-release/
git submodule update --init
```

### Create a deployment manifest

```
./scripts/generate-default-bosh-lite-manifest

```

For different backends:

```
./scripts/generate-bosh-lite-manifest ./templates/s3.yml
./scripts/generate-bosh-lite-manifest ./templates/local.yml
```

### Deploy

```
bosh create release --force && bosh upload release && bosh -n deploy
```
When prompted for a release name, accept the default ```bits-service```.


### Add Route
If the bits-service has an IP that is not in the 10.244.*.* range, add a route to the VM:

```
# OSX:
sudo route add -net 10.250.0.0/16 192.168.50.4

# Linux:
sudo ip route add 10.250.0.0/16 via 192.168.50.4
```

## Prerequisites for Development

* `spiff` is used to generate the bosh-lite manifest. Installation:

```
brew tap xoebus/cloudfoundry
brew install spiff
```

# Tests

* Generate manifest with tests stubs:
  ```
    ./scripts/generate-bosh-lite-manifest ./spec/assets/body-size-stub.yml ./templates/local.yml # (or s3.yml)
  ```
* Parse the manifest with the ENV variables required
  ```
    BITS_DIRECTORY_KEY=buildpacks ./scripts/manifest_parser.rb ./deployments/bits-service-release-bosh-lite.yml > manifest.yml
  ```
* Deploy release using the generated manifest above
* Tell specs where to find the bits-service endpoint. For a bosh-lite deployment, this is:

  ```
  export BITS_SERVICE_ENDPOINT=10.250.0.2
  ```

  Outside bosh-lite you will need to update the endpoint.

* Run specs:

  ```
  bundle exec rspec spec
  ```
