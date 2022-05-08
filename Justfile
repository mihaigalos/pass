set shell := ["bash", "-uc"]

_default:
    @just --list

tool := "pass"
docker_image_version := "0.0.1"
docker_user_repo := "mihaigalos"
docker_image_dockerhub := docker_user_repo + "/" + tool+ ":" + docker_image_version

build_docker:
    #!/bin/bash
    sources=$(pwd)
    cd $(mktemp -d)
    git clone --depth 1 https://github.com/str4d/age-plugin-yubikey.git
    cd age-plugin-yubikey
    cp $sources/Dockerfile $sources/Justfile .
    docker build -t {{ docker_image_dockerhub }} .

