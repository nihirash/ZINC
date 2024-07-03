#!/bin/bash

# This script rebuilds docker image with ez80asm

docker rmi nihirash/ez80asm:x64
docker build . -t nihirash/ez80asm:x64
docker push nihirash/ez80asm:x64