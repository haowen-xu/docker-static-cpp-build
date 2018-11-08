#!/bin/bash

sudo docker build \
    -t haowenxu/static-cpp-build:latest \
    --build-arg MAKE_ARGS=-j8 \
    .
