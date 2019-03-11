FROM ubuntu:latest

RUN apt-get update && apt-get install vim curl -y

COPY bitsgo /workspace/jobs/bits-service/bin/

ENTRYPOINT [ "/workspace/jobs/bits-service/bin/bitsgo", "--config", "/workspace/jobs/bits-service/config/bits-service.yml" ]
