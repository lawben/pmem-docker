#!/usr/bin/env bash

set -e

# Get directory of this file so that we always use the Dockerfile in the correct dir
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

RUN_NAME="remote_pmem"

if [[ $(docker ps -a | grep $RUN_NAME) ]]; then
    echo "Docker image with name $RUN_NAME already exists."
    if [[ $(docker ps -a -f status=running | grep $RUN_NAME) ]]; then
        echo "Docker running. Doing nothing."
        exit 0
    else
        echo "Removing old docker..."
        docker rm $RUN_NAME
    fi
fi

# Create the docker image with the name remote-pmem
docker build -t remote-pmem ${DIR}

# Start the docker with ...
#   - remote debugging options
#   - ssh port forwarding to host 2222
#   - a mounted tempfs at /mnt/pmem to simulated PMem
#   - name = remote_pmem
docker run -d --cap-add sys_ptrace -p127.0.0.1:2222:22 \
              --tmpfs /mnt/pmem:rw,size=2g,mode=777 \
              --name $RUN_NAME remote-pmem

# Remove any known_host entries for localhost:2222. If this is the first run,
# it will probably look like it "failed" but that is to be expected,
# as there are no entries yet.
ssh-keygen -f "$HOME/.ssh/known_hosts" -R "[localhost]:2222"
