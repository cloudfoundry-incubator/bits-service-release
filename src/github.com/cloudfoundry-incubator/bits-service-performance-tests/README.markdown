# Bits-Service Performance Tests

This test suite exercises a [bits-service deployment](https://github.com/cloudfoundry-incubator/bits-service-release) using the golang cf CLI and curl.

# One-Time Go Setup

```bash
export GOPATH=~/workspace/bits-service-release
export PATH=$GOPATH/bin:$PATH
```

* Install `ginkgo` if not present
* `brew install glide`

# Install Dependencies

```bash
cd ~/workspace/bits-service-release/src/github.com/cloudfoundry-incubator/bits-service-performance-tests
glide install
```

# Create Test Configuration

```bash
cat <<EOT > integration_config.json
{
  "api": "api.${CF_DOMAIN}",
  "apps_domain": "${CF_DOMAIN}",
  "admin_user": "${CF_ADMIN_USER}",
  "admin_password": "${CF_ADMIN_PASSWORD}",
  "skip_ssl_validation": true,
  "use_http": true
}
EOT
export CONFIG=integration_config.json
```

# Run Test

```bash
ginkgo -v --progress
```

# Metrics

Some tests report statistics to a statsd server. You can use `netcat` to verify that these metrics are actually sent:

```bash
nc -ulv 8125
```
