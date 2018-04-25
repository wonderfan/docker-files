#!/bin/bash
export RELEASE_VERSION=$TRAVIS_TAG
docker images
make docker-login
make push