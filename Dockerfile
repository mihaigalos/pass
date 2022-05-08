# docker run --rm -it -v $(pwd):/src -v /run/pcscd/pcscd.comm:/run/pcscd/pcscd.comm mihaigalos/pass

FROM rust:alpine3.14 as base

ARG USER

RUN apk update \
    && apk add \
        git \
        gcc \
        g++ \
        pcsc-lite-dev \
        openssl \
        openssl-dev \
        pkgconfig

COPY . /src

WORKDIR /src

RUN git clone --depth 1 https://github.com/str4d/rage.git \
    && cd rage \
    && RUSTFLAGS="-C target-feature=-crt-static" cargo build --release

RUN git clone --depth 1 https://github.com/str4d/age-plugin-yubikey.git \
    && cd age-plugin-yubikey \
    && RUSTFLAGS="-C target-feature=-crt-static" cargo build --release

RUN git clone --depth 1 https://github.com/casey/just.git \
    && cd just \
    && RUSTFLAGS="-C target-feature=-crt-static" cargo build --release

FROM alpine:3.14 as tool

ARG USER

RUN apk update \
    && apk add \
        bash \
        git \
        libgcc \
        openssh-client \
        pcsc-lite-dev

COPY --from=base /src/age-plugin-yubikey/target/release/age-plugin-yubikey /usr/local/bin/
COPY --from=base /src/rage/target/release/rage* /usr/local/bin/
COPY --from=base /src/just/target/release/just /usr/local/bin/

RUN addgroup -S ${USER} -g 1000 && adduser -S ${USER} -G ${USER} -u 1000
USER ${USER}

WORKDIR /src
ENTRYPOINT [ "just" ]
CMD [ "help" ]
