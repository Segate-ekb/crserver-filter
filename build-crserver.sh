#!/bin/bash
set -e

docker login 10.20.1.10:5000

docker build \
    --pull \
    -t 10.20.1.10:5000/crs-filter:latest \
    -f Dockerfile 
    
docker push 10.20.1.10:5000/crs-filter:latest
