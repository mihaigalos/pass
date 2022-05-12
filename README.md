# pass

Yubikey-encrypted Secrets-as-Code for git.

## Why?

Online password managers have already reached maturity.

Git can be used to store encrypted passwords and files just fine.

The i.e. GitHub repo containing them can be private.

## How?
Leveraging [`age`](https://github.com/FiloSottile/age), one can use private-public keypairs for encryption of data.

The private part is directly storeable on a YubiKey. Users are asked for a PIN for additional security.

## Installation

OS: Linux.

Prerequisites: [`just`](https://github.com/casey/just) in `$PATH`.

## Usage

```bash
just pass add mysecretname # Asks for a password, encrypts it to a file "mysecretname" and commit+pushes it to the secrets repository.
```

