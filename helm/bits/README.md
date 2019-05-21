# bits-helm-release
Bits-Service Helm chart template
```sh
cd ~/workspace/bits-service-release/helm
helm package bits
helm repo index . --url http://cloudfoundry-incubator.github.io/bits-service-release/helm
helm repo add bits http://cloudfoundry-incubator.github.io/bits-service-release/helm
helm repo list
```
**Notice**<p>
This is WORK IN PROGRESS and might change over time, hence no guarantee for stability.
Please contact [#bits-service team](https://cloudfoundry.slack.com/messages/C0BNGJY0G) in CF Slack for more details.
