FROM ubuntu:latest

RUN apt-get update && apt-get install vim curl jq -y

COPY eirini-rootfs-downloader.sh /

RUN chmod u+x /eirini-rootfs-downloader.sh