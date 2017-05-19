# How to deploy a standalone bits-service

In order to run tests against a standalone bits-service (deployed without Cloud Foundry), the following steps are necessary:

1. Configure environment:

  * When targeting an local blobstore, the following environment variables are required to be set:

    ```
    export BITS_SERVICE_JOB_IP=10.250.0.2
    export BLOBSTORE_JOB_IP=10.250.0.2
    ```

    The `BLOBSTORE_JOB_IP` is redundant for a bits-service with local blobstore, but specifying a dummy values keeps manifest generation simple.

  * When targeting an S3 blobstore, the following environment variables are required to be set. Otherwise you can skip this step.

    ```
    export BITS_DIRECTORY_KEY=
    export AWS_ACCESS_KEY_ID=
    export AWS_SECRET_ACCESS_KEY=
    export BITS_AWS_REGION=
    ```

1. Generate manifest with tests stubs:

  ```
  ./scripts/generate-test-bosh-lite-manifest local # (or s3, or webdav)
  ```

1. Deploy the release using the generated manifest

1. Refer to the README.md on how to run tests.
