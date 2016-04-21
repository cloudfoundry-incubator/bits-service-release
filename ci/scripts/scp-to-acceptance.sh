#!/bin/bash -e

# scp $FILE to $SSH_CONNECTION_STRING/$RELEASE_NAME/$VERSION_FILE/
# e.g.
# cf-release/230.0.0-dev.84/release.tgz
# bits-service-release/1.0.0-dev.90/manifest.yml

function main {
  setup_ssh

  local remote_dir="$RELEASE_NAME/$(cat $VERSION_FILE)/"
  create-directory "$remote_dir"
  copy-file "$remote_dir"
  echo "Copied $FILE to $remote_dir"
}

# copied from ci/scripts/recreate-bosh-lite.sh
function setup_ssh {
  echo "$SSH_KEY" > $PWD/.ssh-key
  chmod 600 $PWD/.ssh-key
  mkdir -p ~/.ssh && chmod 700 ~/.ssh
  local ip=$(echo $SSH_CONNECTION_STRING | cut -d "@" -f2 | tr -d '"')

  ssh-keyscan -t rsa,dsa $ip >> ~/.ssh/known_hosts
}

function create-directory {
  ssh -i "$PWD/.ssh-key" "$SSH_CONNECTION_STRING" "mkdir -p $1"
}

function copy-file {
  scp -i "$PWD/.ssh-key" ${FILE} "$SSH_CONNECTION_STRING:$1"
}

main
