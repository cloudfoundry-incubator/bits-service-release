# Bits Service Docker Image

## prereq

install docker for mac https://docs.docker.com/docker-for-mac/install/
or
install docker for linux ???

clone erini-relese
git clone git@github.com:cloudfoundry-incubator/eirini-release.git
cd eirini-release
switch to develop
git co develop
build the erini rootfs tar
execute ~/workspace/eirini-release/scripts/buildfs.sh
copy to the folder assets
cp ~/workspace/eirini-release/scripts/eirinifs.tar ~/workspace/bits-service-release/docker/assets/
## docker login
docker login -u "$(lpass show "Shared-Flintstone/flintstone Docker account" --username)" -p "$(lpass show "Shared-Flintstone/flintstone Docker account" --password)"


## build the docker image

./generate-docker-image.sh

## test the docker image

docker run -p 4443:4443 --expose=4443 --mount type=bind,source=$HOME/workspace/misc/bits-go/bits-service-local-config,target=/workspace/jobs/bits-service/config --name bits -t flintstonecf/bits-service:latest

curl https://internal.127.0.0.1.nip.io:4443/v2/ -iv -k

docker push flintstonecf/bits-service:latest
