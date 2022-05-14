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

# Get or set the password for the requested input.
pass +input:
   just _run _pass {{ input }}

debug +args:
   just _run _debug {{ args }}

install secrets_repository:
   just configure_yubikey
   just configure_secrets_repo {{ secrets_repository }}

configure_yubikey:
   just _run _configure_yubikey

# Set the secrets repository. Example: just configure_secrets_repo git@github.com:myuser/myrepo.git
configure_secrets_repo secrets_repository:
   sed -i -e 's|^\(secrets_repo := \)\(.*\)|\1"{{ secrets_repository }}"|' Justfile

_run +args:
   docker run --rm -it \
   -v $(pwd):/src \
   -v $(realpath Justfile):/src/Justfile \
   -v /run/pcscd/pcscd.comm:/run/pcscd/pcscd.comm \
   -v /tmp:/tmp \
   -v ~/.gitconfig:/home/{{ docker_user_repo }}/.gitconfig \
   -v ~/.ssh:/home/{{ docker_user_repo }}/.ssh \
   --user $UID:$UID \
   {{ docker_image_dockerhub }} {{ args }}

_configure_yubikey:
   age-plugin-yubikey

@_pass +input: _setup && _teardown
   [[ $# == 1 ]] && just _decrypt {{ input }} || just _encrypt {{ input }}

_encrypt +input:
   #!/bin/bash
   secret_file=$2 
   echo -n "Password: " && read -s password
   echo

   cd secrets/
   git pull --ff-only --allow-unrelated-histories

   if [ ! -f identities ]; then
      echo
      echo "🔑 Plugin all YubiKeys now to store private keys. It is assumed they are already set up using: https://github.com/str4d/age-plugin-yubikey#configuration"
      read -p "Press ENTER to continue."
      age-plugin-yubikey --identity > identities
      identities=$(age-plugin-yubikey --identity | grep Recipient | sed -e "s/ //g" | cut -d':' -f2 | sed -e 's/^age\(.*\)/ -r age\1/g'  | tr -d '\n')
   else
      identities=$(cat identities | grep Recipient | sed -e "s/ //g" | cut -d':' -f2 | sed -e 's/^age\(.*\)/ -r age\1/g'  | tr -d '\n')
   fi

   [ $1 = "add" ] && echo "${password}" | rage ${identities} -o ${secret_file} || true
   [ $1 = "add_file" ] && cat $2 | rage ${identities} -o $(basename $2) || true

   git add .
   git commit -m "Edited ${secret_file}"
   git push

_decrypt +input:
   #!/bin/bash
   secret_file=$1
   cd secrets/
   age-plugin-yubikey --identity > identity 2>/dev/null
   echo
   cat {{ input }} | rage -d -i identity

_debug +args:
   bash -c "{{ args }}"

@_setup:
   [ -d secrets ] && rm -rf secrets/ || true
   git clone --quiet {{ secrets_repo }} secrets

@_teardown:
   rm -rf secrets/ identity

test:
   #!/bin/bash
   err() { echo -e "\e[1;31m${@}\e[0m" >&2; exit 1; }
   ok() { echo -e "\e[1;32mOK\e[0m"; }
   highlight() { echo; echo -e "\e[1;37m${@}\e[0m"; }
   highlight --------------------- Testing encrypt ---------------------
   just pass add test_pass
   highlight --------------------- Testing decrypt ---------------------
   just pass test_pass

