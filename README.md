# pass

YubiKey-encrypted Secrets-as-Code for git.

## Why?

Online password managers have already reached maturity, however `git` can be used to store encrypted passwords and files just fine.

The i.e. GitHub repo containing them can be private.

## How?
Leveraging [`age`](https://github.com/FiloSottile/age), one can use private-public keypairs for encryption of data for multiple such keys (recipients).

The private part is directly storeable on a YubiKey. Users are asked for a PIN for additional security.

## Installation

OS: Linux.

Prerequisites:
* [`just`](https://github.com/casey/just) in `$PATH`.
* Preconfigured YubiKeys. See [this](https://github.com/str4d/age-plugin-yubikey#configuration) for more info.
* Edit the `Justfile` `secrets_repo` field to point to a repository to store the secrets to.

## Usage

```bash
just pass add mysecretname # Asks for a password, encrypts it to a file "mysecretname" and commit+pushes it to the secrets repository.
just pass add_file /tmp/mysecretfile # Asks for a password, encrypts it to a file "mysecretfile" and commit+pushes it to the secrets repository.
just pass mysecretname # Decrypts the secret file "mysecretname".
```

# Acknowledgements

`pass` is just a thin wrapper around the following awesome technologies:

* [`YubiKey`](https://www.yubico.com/products/yubikey-5-overview/) - Strong hardware encryption.
* [`age-plugin-yubikey`](https://github.com/str4d/age-plugin-yubikey) - YubiKey plugin for `rage`.
* [`rage`](https://github.com/str4d/rage) - a Rust implementation of the `age` spec.
