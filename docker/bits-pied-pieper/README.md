# Bits Pied Pieper

This docker image is the foundation for the kubernetes job, which downloads the eirini rootfs layer before the bits-service will startup.
This is only necesarry for useing bits-service as registry for a eirini kubernetes based cloud foundry.

## build
```sh
$./generate-docker-image.sh
```
