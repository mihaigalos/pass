set shell := ["bash", "-uc"]

_default:
    @just --list

tool := "pass"
docker_image_version := "0.0.1"
docker_user_repo := "mihaigalos"
docker_image_dockerhub := docker_user_repo + "/" + tool+ ":" + docker_image_version

build_docker:
    docker build -t {{ docker_image_dockerhub }} .

