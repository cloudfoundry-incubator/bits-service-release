FROM ubuntu:latest

COPY bitsgo /workspace/jobs/bits-service/bin/

ENTRYPOINT [ "/workspace/jobs/bits-service/bin/bitsgo", "--config", "/workspace/jobs/bits-service/config/bits-service.yml" ]
