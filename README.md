# pass

YubiKey-sealed Secrets-as-Code for git.

`pass` runs in the command line.

## Why?

Online password managers have already reached maturity, however `git` can be used to store encrypted passwords and files just fine.

The i.e. GitHub repo containing them can be private.

## How?
Leveraging [`age`](https://github.com/C2SP/C2SP/blob/main/age.md), one can use private-public keypairs for encryption of data for multiple such keys (recipients).

The private part is directly storeable on a YubiKey. Users are asked for a PIN for additional security.

## Installation

OS: Linux.

Prerequisites:
* [`just`](https://github.com/casey/just) in `$PATH`.
* Run `just install <your secrets repo>`.

## Usage

```bash
$ just pass add mysecretname # Asks for a password, encrypts it to a file "mysecretname" and commit+pushes it to the secrets repository.
$ just pass add_file /tmp/mysecretfile # Encrypts the given file and commit+pushes it to the secrets repository.
$ just pass mysecretname # Decrypts the secret file "mysecretname".
```
Additionally, you can set an alias to get access to the functionality from any path in the shell:
```bash
$ echo 'alias pass="just --justfile ~/git/pass/Justfile pass"' >> ~/.bashrc
$ pass mysecretname # prints the secret
```

# Acknowledgements

`pass` is just a thin wrapper around the following awesome technologies:

* [`YubiKey`](https://www.yubico.com/products/yubikey-5-overview/) - Strong hardware encryption.
* [`age-plugin-yubikey`](https://github.com/str4d/age-plugin-yubikey) - YubiKey plugin for `rage`.
* [`rage`](https://github.com/str4d/rage) - a Rust implementation of the `age` spec.
