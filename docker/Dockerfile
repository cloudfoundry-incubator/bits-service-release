FROM ubuntu:latest

RUN apt-get update && apt-get install vim curl -y

COPY bitsgo /workspace/jobs/bits-service/bin/

COPY assets/example_droplet /assets/
COPY assets/eirinifs.tar /assets/

ENTRYPOINT [ "/workspace/jobs/bits-service/bin/bitsgo", "--config", "/workspace/jobs/bits-service/config/bits-service.yml" ]
