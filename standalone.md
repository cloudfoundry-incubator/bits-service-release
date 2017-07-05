# How to deploy a standalone bits-service

In order to run tests against a standalone bits-service (deployed without Cloud Foundry), the following steps are necessary:

1. Configure environment:

    When targeting an S3 blobstore, the following environment variables are required to be set. Otherwise you can skip this step.

      ```
      export BITS_DIRECTORY_KEY=
      export AWS_ACCESS_KEY_ID=
      export AWS_SECRET_ACCESS_KEY=
      export BITS_AWS_REGION=
      ```

1. Generate manifest with tests stubs:

    * For local:
      ```
      ./scripts/generate-test-bosh-lite-manifest-local
      ```

    * For webdav:
      ```
      ./scripts/generate-test-bosh-lite-manifest-webdev
      ```

    * For S3:
      ```
      ./scripts/generate-test-bosh-lite-manifest-s3
      ```

1. Deploy the release using the generated manifest

1. Refer to the README.md on how to run tests.

    Make sure to point `BITS_SERVICE_PRIVATE_ENDPOINT_IP` to your bits-service VM. Also, you don't need to patch your `/etc/hosts` since standalone manifests use xip.io for addressing.
