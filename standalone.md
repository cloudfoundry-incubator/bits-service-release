# WIP

_This is just a temporary place for putting instructions on how to deploy a standalone bits-service._

For different backends:

```
./scripts/generate-bosh-manifest ./templates/bosh-lite.yml ./templates/s3.yml
./scripts/generate-bosh-manifest ./templates/bosh-lite.yml ./templates/local.yml
./scripts/generate-bosh-manifest ./blobstore-job.yml ./templates/bosh-lite.yml ./templates/webdav.yml
```

### Add Route

If the bits-service has an IP that is not in the 10.244.*.* range, add a route to the VM:

```
# OSX:
sudo route add -net 10.250.0.0/16 192.168.50.4

# Linux:
sudo ip route add 10.250.0.0/16 via 192.168.50.4
```

# Tests

* When targeting an S3 blobstore, the following environment variables are required to be set. Otherwise you can skip this step.

  ```
  export BITS_DIRECTORY_KEY=
  export AWS_ACCESS_KEY_ID=
  export AWS_SECRET_ACCESS_KEY=
  export BITS_AWS_REGION=
  ```

* Generate manifest with tests stubs:

  ```
  ./scripts/generate-test-bosh-lite-manifest ./templates/local.yml # (or s3.yml, or webdav.yml)
  ```

* Deploy release using the generated manifest

* Tell specs where to find the bits-service endpoint. For a bosh-lite deployment, this is:

  ```
  export BITS_SERVICE_ENDPOINT=10.250.0.2 # for local backend
  export BITS_SERVICE_ENDPOINT=10.250.1.2 # for S3 backend
  export BITS_SERVICE_ENDPOINT=10.250.3.2 # for WebDav backend
  ```

  Outside bosh-lite you will need to update the endpoint.
