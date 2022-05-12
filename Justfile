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
   -v /tmp:/tmp \
   -v ~/.gitconfig:/home/{{ docker_user_repo }}/.gitconfig \
   -v ~/.ssh:/home/{{ docker_user_repo }}/.ssh \
   --user $UID:$UID \
   mihaigalos/pass:0.0.1 _pass {{ input }}

_pass +input: _setup && _teardown
   #!/bin/bash
   arg_count=$#
   [[ $arg_count == 1 ]] && just _decrypt {{ input }} || just _encrypt {{ input }}

debug +args:
   docker run --rm -it \
   -v $(pwd):/src \
   -v $(realpath Justfile):/src/Justfile \
   -v /run/pcscd/pcscd.comm:/run/pcscd/pcscd.comm \
   -v /tmp:/tmp \
   -v ~/.ssh:/home/{{ docker_user_repo }}/.ssh \
   --user $UID:$UID \
   mihaigalos/pass:0.0.1 _debug {{ args }}

_encrypt +input:
   #!/bin/bash
   secret_file=$2 
   echo -n "Password: " && read -s password
   echo

   cd secrets/
   
   git pull --ff-only --allow-unrelated-histories

   echo
   echo "🔑 Plugin all YubiKeys now to store private keys. It is assumed they are already set up using: https://github.com/str4d/age-plugin-yubikey#configuration"
   read -p "Press ENTER to continue."

   identities=$(age-plugin-yubikey --identity | grep Recipient | sed -e "s/ //g" | cut -d':' -f2 | sed -e 's/^age\(.*\)/ -r age\1/g'  | tr -d '\n')

   [ $1 = "add" ] && echo "${password}" | rage ${identities} -o ${secret_file} || true
   [ $1 = "add_file" ] && cat $2 | rage ${identities} -o $(basename $2) || true

   git add .
   git commit -m "Edited ${secret_file}"
   git push

_decrypt +input:
   #!/bin/bash
   secret_file=$1
   cd secrets/
   age-plugin-yubikey --identity > identity
   cat {{ input }} | rage -d -i identity

_debug +args:
   bash -c "{{ args }}"

_setup:
   #!/bin/bash
   git clone --quiet {{ secrets_repo }} secrets
   age-plugin-yubikey --identity > secrets/identity 2>/dev/null

_teardown:
   rm -rf secrets/ identity

test:
   #!/bin/bash
   err() { echo -e "\e[1;31m${@}\e[0m" >&2; exit 1; }
   ok() { echo -e "\e[1;32mOK\e[0m"; }
   highlight() { echo; echo -e "\e[1;37m${@}\e[0m"; }
   highlight --------------------- Testing encrypt ---------------------
   just pass add test_secret_name
   highlight --------------------- Testing decrypt ---------------------
   just pass test_secret_name

