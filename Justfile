set positional-arguments := true
set shell := ["bash", "-uc"]

_default:
    @just --list

secrets_repo := "git@github.com:mihaigalos/secrets.git"
tool := "pass"
docker_image_version := "0.0.2"
docker_user_repo := "mihaigalos"
docker_image_dockerhub := docker_user_repo + "/" + tool + ":" + docker_image_version

help:
    cat README.md | less

build_docker:
    docker build  --build-arg=USER={{ docker_user_repo }} -t {{ docker_image_dockerhub }} .

push:
    docker push {{ docker_image_dockerhub }}

# Get or set the password for the requested input.
@pass +input:
    just _run _pass {{ input }}

debug +args: _setup && _teardown
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
    #!/bin/bash
    err() { echo -e "\e[1;31m${@}\e[0m" >&2; just _teardown; exit 1; }
    ([ $# -ge 3 ] && [ $2 = "add_file" ]) && pass_file=$3 || pass_file="/tmp/pass_file"
    [[ $pass_file =~ ^/.* ]] && true || err 'Need an absolute file for the input file (just limitation). Use $(realpath file) instead.'
    touch /tmp/randompass
    docker run --rm -it \
        -v $(pwd):/src \
        -v $pass_file:/tmp/$(basename $pass_file):ro \
        -v /tmp/randompass:/tmp/randompass \
        -v $(realpath Justfile):/src/Justfile:ro \
        -v /run/pcscd/pcscd.comm:/run/pcscd/pcscd.comm \
        -v ~/.gitconfig:/home/{{ docker_user_repo }}/.gitconfig \
        -v ~/.ssh:/home/{{ docker_user_repo }}/.ssh \
        --user $UID:$UID \
        {{ docker_image_dockerhub }} {{ args }}
    unalias xclip > /dev/null 2>&1 || true
    cat /tmp/randompass | xclip -selection clipboard || true
    rm /tmp/randompass

_configure_yubikey:
    age-plugin-yubikey

@_pass +input: _teardown _setup && _teardown
    [[ $# -ne 1 ]] && just _encrypt {{ input }} || just _decrypt {{ input }}

_encrypt +input:
    #!/bin/bash
    [ $1 = "add" ] && echo -n "Password: " && read -s password && echo || true
    [ $1 = "random" ] && password=$(randompass)  || true

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

    file_to_encrypt=$(echo $2 | sed "s/.*\///")
    [ $1 = "add" ] || [ $1 = "random" ] && echo "${password}" | rage ${identities} -e -o ${file_to_encrypt} || true
    [ $1 = "add_file" ] && rage ${identities} /tmp/$file_to_encrypt -o $file_to_encrypt || true

    git add .
    git commit -m "Edited ${file_to_encrypt}"
    git push

    [ $1 = "random" ] && echo ${password} | tr -d '\r' | tr -d '\n' > /tmp/randompass || true

_decrypt +input:
    #!/bin/bash
    err() { echo -e "\e[1;31m${@}\e[0m" >&2; just _teardown; exit 1; }
    secret_file=$1
    cd secrets/
    age-plugin-yubikey --identity > identity 2>/dev/null
    echo
    [ -f $secret_file ] && cat $secret_file | rage -d -i identity || err "ERROR: File $secret_file not present in {{ secrets_repo }}"


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
