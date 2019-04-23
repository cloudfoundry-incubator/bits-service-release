# Basic info
This is basic Ubuntu image with 'jq' and 'curl' install.
It has eirini-rootfs-donwloader.sh file to download eirinifs.tar of mentioned TAG in environment varialbe from git hub.

# Build Dockerfile
To build the docker image run the following command <p>
```docker build . -t flintstonecf/eirinifs-downloader```