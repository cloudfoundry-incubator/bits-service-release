# Test rolling enablement of bits-service 

## Test description

* Create a deployment with 2 CCs and one bits-service instance
* Shared blobstore like S3 or webdav (to see potential misalignements between CC and bits-service)
* One run with bits-service disabled for all CC
* Second run with one CC has bits-service disabled (CC1), and the other one have it enabled (CC2)

# Results
The mixed setup of CC with bits-service and CC (without bits-service) seems to work. I found only one [issue](#Issues Found)


# How to test

### Prerequisites

To execute this test it is necessary to use a shared blobstore. We use a webdav blobstore, because we have easy access to the logs to see where the blobstore request come from. 

##Steps

1. Deploy 2 CC with one bitsservice instance, but bits-service has to be disabled for both CC instances.  
deployment manifest:

	```yaml
	  ...
	  cc:
	    bits_service:
	      enabled: false
	   ...
	  jobs:
	  - default_networks:
		 - name: cf1
		 instances: 2
		 name: api_z1
```
2. Push an app for example `cf push my-awesome-app` [here](### crete the dummy-app) is a the _"how to"_ for createing the app.

3. Check the blobstore request without bits-service enabled.  
Log in to blobstore `bosh ssh blobstore_z1`  

	```
	bash@api_z1/1$ tail -F -n0 /var/vcap/sys/log/blobstore/internal_access.log | grep --line-buffered "HEAD /admin/droplets" >> /var/vcap/sys/log/blobstore/output
	```
	open a second terminal on the blobstore to check the filtered output. The file should be empty. 

	```
	bash@api_z1/1$truncate -s 0 /var/vcap/sys/log/blobstore/output
	bash@api_z1/1$ wc -l /var/vcap/sys/log/blobstore/output
	
	0 /var/vcap/sys/log/blobstore/output
	```
4. Scale the app and see whats happend for CC without bits-service

	```
	cf scale my-awesome-app -i 10 && \
	cf scale my-awesome-app -i 15 && \
	cf scale my-awesome-app -i 20 && \
	cf scale my-awesome-app -i 1 && \
	cf scale my-awesome-app -i 5 && \
	cf scale my-awesome-app -i 10 &&\
	cf scale my-awesome-app -i 1
	```

5. Now check blobstore request in the second terminal.  
	`bash@api_z1/1$ wc -l /var/vcap/sys/log/blobstore/output`  
Expected result is, 28 request to blobstore. Additionally you should see the ip from CC1 and CC2 in the log file of the blobstore `output`.

6. Enable the bits service for one CC and repaet the steps. 

	```
	bash$ bosh ssh api_z1/1
	
	bash@api_z1/1$ sudo -i
	
	bash@api_z1/1$ echo "%s/bits_service:\n  enabled: false/bits_service:\r  enabled: true\r  public_endpoint: http:\/\/bits-service.bosh-lite.com \r  private_endpoint: http:\/\/bits-service.service.cf.internal\r  username: admin\r  password: admin/ | w" | vim -e /var/vcap/jobs/cloud_controller_ng/config/cloud_controller_ng.yml
	
	bash@api_z1/1$ monit restart cloud_controller_ng
	
	```

7. Check the result with bits service enabled  
Log in to blobstore `bosh ssh blobstore_z1`

	```
	bash@api_z1/1$ tail -F -n0 /var/vcap/sys/log/blobstore/internal_access.log | grep --line-buffered "HEAD /admin/droplets" >> /var/vcap/sys/log/blobstore/output
	```
	Open a second terminal on the blobstore to check the filtered output. After the the truncate the file should be empty. 
	
	```
	bash@api_z1/1$ truncate -s 0 /var/vcap/sys/log/blobstore/output
	bash@api_z1/1$ wc -l /var/vcap/sys/log/blobstore/output
	
	0 /var/vcap/sys/log/blobstore/output
	```
8. Scale the app again and see whats happend for mixed setup with one CC without bits-service and one CC with bits-service enabled.

	```
	cf scale my-awesome-app -i 10 && \
	cf scale my-awesome-app -i 15 && \
	cf scale my-awesome-app -i 20 && \
	cf scale my-awesome-app -i 1 && \
	cf scale my-awesome-app -i 5 && \
	cf scale my-awesome-app -i 10 &&\
	cf scale my-awesome-app -i 1
	```

9. Now check the output for bits-service enabled.  

	```
	bash@api_z1/1$ tail -F -n0 /var/vcap/sys/log/blobstore/internal_access.log | grep --line-buffered "HEAD /admin/droplets" >> /var/vcap/sys/log/blobstore/output
	```
	
Expected result, 28 request to blobstore, too. But now you should see the ip from CC1 and from the bitsservice in the log file of the blobstore.

		10.244.0.154 - blobstore [20/Apr/2017:11:31:57 +0000] "HEAD /admin/droplets/cd/ce/cdcec42e-0bc4-472c-9c85-2f9c3d1cf9bd/9996f66ec63b00f1d09d3aca917b872334cdde6c HTTP/1.1" 200 0 "-" "HTTPClient/1.0 (2.8.2.4, ruby 2.3.3 (2016-11-21))"
		10.244.0.74 - blobstore [20/Apr/2017:11:31:57 +0000] "HEAD /admin/droplets/cd/ce/cdcec42e-0bc4-472c-9c85-2f9c3d1cf9bd/9996f66ec63b00f1d09d3aca917b872334cdde6c HTTP/1.1" 200 0 "-" "HTTPClient/1.0 (2.7.1, ruby 2.3.1 (2016-04-26))"
	


# Issues Found

### 503 error code: 150003
for run in {1..10}; do cf scale my-awesome-app -i 10 && cf scale my-awesome-app -i 15 && cf scale my-awesome-app -i 20 && cf scale my-awesome-app -i 1 && cf scale my-awesome-app -i 5 && cf scale my-awesome-app -i 10 &&cf scale my-awesome-app -i 1; done

FAILED
Server error, status code: 503, error code: 150003, message: One or more instances could not be started because of insufficient running resources.

## Notes

### Count the requests for droplets

This filters for the droplet requests and redirect it to the output file.  
```
tail -F -n0 /var/vcap/sys/log/blobstore/internal_access.log | grep --line-buffered "HEAD /admin/droplets" >> /var/vcap/sys/log/blobstore/output
```

Now count the lines of the *output* file to see how much request are arrive the blobstore.
```
wc -l /var/vcap/sys/log/blobstore/output
```

Cleanup the output file, if needed.
```
truncate -s 0 /var/vcap/sys/log/blobstore/output
```  
and hit enter in the window where the tail is running.


### Stageing for test

Here is described, how we scale the cf-app for our test purpose. 
The scale chain starts from 1 to 10 -> 15 -> 20, then back to 1 and scale up agian to 5 -> 10 and then reset to 1 instance.

```
cf scale my-awesome-app -i 10 && \
cf scale my-awesome-app -i 15 && \
cf scale my-awesome-app -i 20 && \
cf scale my-awesome-app -i 1 && \
cf scale my-awesome-app -i 5 && \
cf scale my-awesome-app -i 10 &&\
cf scale my-awesome-app -i 1
```

Exepcted out put with CC mixed 
```cat /var/vcap/sys/log/blobstore/output | grep "10.244.0.154\|10.244.0.74"```

```
10.244.0.154 - blobstore [20/Apr/2017:11:31:57 +0000] "HEAD /admin/droplets/cd/ce/cdcec42e-0bc4-472c-9c85-2f9c3d1cf9bd/9996f66ec63b00f1d09d3aca917b872334cdde6c HTTP/1.1" 200 0 "-" "HTTPClient/1.0 (2.8.2.4, ruby 2.3.3 (2016-11-21))"
10.244.0.74 - blobstore [20/Apr/2017:11:31:57 +0000] "HEAD /admin/droplets/cd/ce/cdcec42e-0bc4-472c-9c85-2f9c3d1cf9bd/9996f66ec63b00f1d09d3aca917b872334cdde6c HTTP/1.1" 200 0 "-" "HTTPClient/1.0 (2.7.1, ruby 2.3.1 (2016-04-26))"
```
This is a check for how much, which maschine access the blobestore.

```shell
cat /var/vcap/sys/log/blobstore/output | echo "result: $(grep -c "10.244.0.154\|10.244.0.74")"
result: 28
cat /var/vcap/sys/log/blobstore/output | echo "result: $(grep -c "10.244.0.154")"
result: 4
cat /var/vcap/sys/log/blobstore/output | echo "result: $(grep -c "10.244.0.74")"
result: 24
```

### crete the dummy-app
CF_TRACE

```
mkdir -p my-awesome-app && cd my-awesome-app &&
touch Staticfile &&
echo '<!DOCTYPE html><html><body> hello blobstore test app 1</body></html>' > index.html &&
cf push my-awesome-app
```

### vim
search pattern for enable bits-service:

`
	%s/bits_service:\n  enabled: false/bits_service:\r  enabled: true\r  public_endpoint: http:\/\/bits-service.bosh-lite.com \r  private_endpoint: http:\/\/bits-service.service.cf.internal\r  username: admin\r  password: admin/
	`