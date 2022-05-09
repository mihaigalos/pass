set positional-arguments
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
pass +input:
   docker run --rm -it \
   -v $(pwd):/src \
   -v $(realpath Justfile):/src/Justfile \
   -v /run/pcscd/pcscd.comm:/run/pcscd/pcscd.comm \
   -v ~/.ssh:/home/{{ docker_user_repo }}/.ssh \
   -v ~/.gitconfig:/home/{{ docker_user_repo }}/.gitconfig \
   --user $UID:$UID \
   mihaigalos/pass:0.0.1 _pass {{ input }}

_pass +input: _setup && _teardown
   #!/bin/bash
   arg_count=$#
   git clone --quiet {{ secrets_repo }} secrets
   [[ $arg_count == 1 ]] && echo Decrypting. || just _add {{ input }}

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

_add +input:
   #!/bin/bash
   secret_file=$2 
   echo -n "Password: "
   read -s password
   echo

   cd secrets/
   
   git pull --ff-only --allow-unrelated-histories
   echo ${password} > ${secret_file}
   git add .
   git commit -m "Edited ${secret_file}"
   git push

_debug +args:
   bash -c "{{ args }}"

_setup:
   age-plugin-yubikey --identity > identity 2>/dev/null

_teardown:
   rm -rf secrets/ identity
