# Test rolling enablement of bits-service

## Test description

* Create a deployment with two CloudControllers (CCs) and one bits-service instance
* Use shared blobstore like S3 or webdav (to see potential misalignments between CC and bits-service)
* Run once with bits-service disabled for both CCs
* Run again with one CC having bits-service disabled (CC1), and the other one having it enabled (CC2)

## Results
The mixed configuration of CCs with and without bits-service seems to work. Only one potential [issue](#issues-found) was found so far. It is related to resource shortage which may occur due to the selected testing method and does not directly relate to bits-service or cloud controllers.

## How to test

### Prerequisites

To execute this test it is necessary to use a shared blobstore. We use a webdav blobstore, because we have easy access to blobstore's logs.

In further examples we will assume the following IP addresses:

| VM | IP |
|----|----|
|CC1 (api_z1/0)|10.244.0.138|
|CC2 (api_z1/1)|10.244.0.154|
|bits-service|10.244.0.74|

### Steps

1. Deploy CloudFoundry with two CCs and one bits-service instance, but bits-service has to be disabled for both CC instances.

    Deployment manifest snippet:
    ```yml
    jobs:
    - default_networks:
      - name: cf1
      instances: 2
      name: api_z1

    properties:
      cc:
        bits_service:
          enabled: false
    ```

2. Push an app, for example `cf push my-awesome-app`.
    Follow this instructions to create a dummy app. [Create dummy app](#create-the-dummy-app).

    Store app GUID in a shell variable.
    ```bash
    APP_ID=$(cf app my-awesome-app --guid)
    ```

3. Check the blobstore request without bits-service enabled.

    Log in to blobstore.
    ```console
    bash@localhost$ bosh ssh blobstore_z1
    ```

    Start tailing and filtering blobstore access log.
    ```console
    bash@api_z1/1$ tail -F -n0 /var/vcap/sys/log/blobstore/internal_access.log \
      | grep --line-buffered "HEAD /admin/droplets"
    ```

4. Scale the app using each of the CCs.
    ```bash
    curl -X PUT \
      "http://10.244.0.138:9022/v2/apps/${APP_ID}?async=true" \
      -d '{"instances":2}' \
      -H "Authorization: $(cf oauth-token)"

    curl -X PUT \
      "http://10.244.0.154:9022/v2/apps/${APP_ID}?async=true" \
      -d '{"instances":3}' \
      -H "Authorization: $(cf oauth-token)"
    ```

5. Now go back to blobstore access log. You should see the IP address of both CCs.

6. Enable the bits service for one CC and repeat the steps.
    ```console
    bash@localhost$ bosh ssh api_z1/1

    bash@api_z1/1$ sudo -i

    bash@api_z1/1$ echo "%s/bits_service:\n  enabled: false/bits_service:\r  enabled: true\r  public_endpoint: http:\/\/bits-service.bosh-lite.com \r  private_endpoint: http:\/\/bits-service.service.cf.internal\r  username: admin\r  password: admin/ | w" | vim -e /var/vcap/jobs/cloud_controller_ng/config/cloud_controller_ng.yml

    bash@api_z1/1$ monit restart cloud_controller_ng
    ```

7. Check the result with bits service enabled.

    Log in to blobstore.
    ```console
    bash@localhost$ bosh ssh blobstore_z1
    ```

    Start tailing and filtering blobstore access log.
    ```console
    bash@api_z1/1$ tail -F -n0 /var/vcap/sys/log/blobstore/internal_access.log \
      | grep --line-buffered "HEAD /admin/droplets"
    ```

8. Scale the app using each of the CCs.
    ```bash
    curl -X PUT \
      "http://10.244.0.138:9022/v2/apps/${APP_ID}?async=true" \
      -d '{"instances":4}' \
      -H "Authorization: $(cf oauth-token)"

    curl -X PUT \
      "http://10.244.0.154:9022/v2/apps/${APP_ID}?async=true" \
      -d '{"instances":5}' \
      -H "Authorization: $(cf oauth-token)"
    ```

9. Go back to blobstore access log again.
    Now you should see the IP address of CC1 and bits-service.
    ```
    10.244.0.154 - blobstore [20/Apr/2017:11:31:57 +0000] "HEAD /admin/droplets/cd/ce/cdcec42e-0bc4-472c-9c85-2f9c3d1cf9bd/9996f66ec63b00f1d09d3aca917b872334cdde6c HTTP/1.1" 200 0 "-" "HTTPClient/1.0 (2.8.2.4, ruby 2.3.3 (2016-11-21))"
    10.244.0.74 - blobstore [20/Apr/2017:11:31:57 +0000] "HEAD /admin/droplets/cd/ce/cdcec42e-0bc4-472c-9c85-2f9c3d1cf9bd/9996f66ec63b00f1d09d3aca917b872334cdde6c HTTP/1.1" 200 0 "-" "HTTPClient/1.0 (2.7.1, ruby 2.3.1 (2016-04-26))"
    ```

## Notes

### Scaling cf apps for the test

This section describes how to scale a cf-app for our test's purposes.

We issue scaling requests directly to CCs to prevent any kind of load balancing on the side of ha_proxy.
Make sure the number of instances increases by 1 on each consecutive request to get the desired result.
You may also set it to 0 and 1 in turns. Lowering number of instances does not trigger blobstore access.

Make sure you are targeting the CF API in you test environment and is logged in.
We rely on this to get OAuth token for the direct scaling requests.

```bash
APP_ID=$(cf app my-awesome-app --guid)

curl -X PUT \
  "http://10.244.0.138:9022/v2/apps/${APP_ID}?async=true" \
  -d '{"instances":2}' \
  -H "Authorization: $(cf oauth-token)"

curl -X PUT \
  "http://10.244.0.154:9022/v2/apps/${APP_ID}?async=true" \
  -d '{"instances":3}' \
  -H "Authorization: $(cf oauth-token)"
```

### Create a dummy-app

```bash
mkdir -p my-awesome-app && cd my-awesome-app
touch Staticfile
echo '<!DOCTYPE html><html><body> hello blobstore test app 1</body></html>' > index.html
cf push my-awesome-app
```

### vim

Search pattern for enabling bits-service:
```vim
%s/bits_service:\n  enabled: false/bits_service:\r  enabled: true\r  public_endpoint: http:\/\/bits-service.bosh-lite.com \r  private_endpoint: http:\/\/bits-service.service.cf.internal\r  username: admin\r  password: admin/
```
## Issues Found

### HTTP Status code 503, error code: 150003

When the scaling operation is executed 10 times in a row,
```bash
for run in {1..10}; do
  CF_TRACE=true \
  cf scale my-awesome-app -i 10 && \
  cf scale my-awesome-app -i 15 && \
  cf scale my-awesome-app -i 20 && \
  cf scale my-awesome-app -i 1 && \
  cf scale my-awesome-app -i 5 && \
  cf scale my-awesome-app -i 10 && \
  cf scale my-awesome-app -i 1
done
```
then this error occurs.
```
FAILED
Server error, status code: 503, error code: 150003, message: One or more instances could not be started because of insufficient running resources.
```

#### Verification

Repeat this test with CC1 and CC2 bits-service _ENABLED_.  
_Result:_  the error does not occur.

Repeat this test with CC1 and CC2 bits-service _DISABLED_.  
_Result:_  the error occurs 2 times.  

```
FAILED
Server error, status code: 503, error code: 150003, message: One or more instances could not be started because of insufficient running resources.
FAILED
Server error, status code: 503, error code: 150003, message: One or more instances could not be started because of insufficient running resources.
```

#### Remarks

Seems that bits-service will fix this issue for CC.
The error "150003" is known and documented for the API v2.
[Documentation of v2 api errors](https://docs.cloudfoundry.org/running/troubleshooting/v2-errors.html).

#### Summary
No effect to our rolling enablement test.
