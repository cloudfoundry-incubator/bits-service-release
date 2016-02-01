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
./scripts/generate-bosh-lite-manifest

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
sudo route add -net 10.254.0.0/16 192.168.50.4

# Linux:
sudo ip route add 10.254.0.0/16 via 192.168.50.4
```

## Prerequisites for Development

* `spiff` is used to generate the bosh-lite manifest. Installation:

```
brew tap xoebus/cloudfoundry
brew install spiff
```

## Running Tests

	$ cd test
	$ ./test.sh
