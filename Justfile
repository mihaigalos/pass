set shell := ["bash", "-uc"]

_default:
    @just --list

secrets_repo := "git@github.com:mihaigalos/secrets.git"

tool := "pass"
docker_image_version := "0.0.1"
docker_user_repo := "mihaigalos"
docker_image_dockerhub := docker_user_repo + "/" + tool+ ":" + docker_image_version


help:
    cat README.md

build_docker:
    docker build  --build-arg=USER={{ docker_user_repo }} -t {{ docker_image_dockerhub }} .

# Get the password for the requested input.
pass input:
   docker run --rm -it \
   -v $(pwd):/src \
   -v $(realpath Justfile):/src/Justfile \
   -v /run/pcscd/pcscd.comm:/run/pcscd/pcscd.comm \
   -v ~/.ssh:/home/{{ docker_user_repo }}/.ssh \
   --user $UID:$UID \
   mihaigalos/pass:0.0.1 _pass {{ input }}

_pass input:
    git clone {{ secrets_repo }} secret && cd secret

test:
    echo test

debug +args:
   docker run --rm -it \
   -v $(pwd):/src \
   -v $(realpath Justfile):/src/Justfile \
   -v /run/pcscd/pcscd.comm:/run/pcscd/pcscd.comm \
   -v ~/.ssh:/home/{{ docker_user_repo }}/.ssh \
   --user $UID:$UID \
   mihaigalos/pass:0.0.1 _debug {{ args }}

_debug +args:
   bash -c "{{ args }}"
