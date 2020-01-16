FROM ubuntu:latest

COPY bitsgo /workspace/jobs/bits-service/bin/

USER 1001

ENTRYPOINT [ "/workspace/jobs/bits-service/bin/bitsgo", "--config", "/workspace/jobs/bits-service/config/bits-service.yml" ]
ARG GIT_SHA
LABEL org.opencontainers.image.revision=$GIT_SHA \
      org.opencontainers.image.source=https://code.cloudfoundry.org/bits-service
