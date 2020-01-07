FROM ubuntu:latest

RUN apt-get update \ 
  && apt-get install --no-install-recommends curl jq ca-certificates  -y \
  && rm -rf /var/lib/apt/lists/*

COPY eirini-rootfs-downloader.sh /

RUN chmod u+x /eirini-rootfs-downloader.sh
