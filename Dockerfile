FROM ubuntu:20.04 as builder

LABEL maintainer="donato@wolfisberg.dev"
ARG version="2.30"

ENV DEBIAN_FRONTEND="noninteractive" TZ="Europe/London"
RUN apt-get update \
    && apt-get upgrade -y \
    && apt-get install -y \
        gcc \
        libbz2-dev \
        liblz4-dev \
        libpq-dev \
        libssl-dev \
        libxml2-dev \
        libz-dev \
        libzstd-dev \
        make \
        pkg-config \
        wget \
    && mkdir /build \
    && wget -q -O - "https://github.com/pgbackrest/pgbackrest/archive/release/${version}.tar.gz" \
    |  tar zx -C /build \
    && cd "/build/pgbackrest-release-${version}/src" \
    && ./configure && make \
    && mv /build/pgbackrest-release-${version}/src/pgbackrest /build/pgbackrest

FROM ubuntu:20.04

LABEL maintainer="donato@wolfisberg.dev"

RUN apt-get update \
    && apt-get upgrade -y \
    && apt-get install -y \
        postgresql-client

WORKDIR /usr/bin
COPY "./entrypoint.sh" /entrypoint.sh
COPY --from=builder "/build/pgbackrest" .

RUN chmod 755 pgbackrest \
    &&  mkdir -p -m 770 /var/log/pgbackrest \
    &&  mkdir -p /etc/pgbackrest/conf.d \
    &&  touch /etc/pgbackrest/pgbackrest.conf \
    &&  chmod 640 /etc/pgbackrest/pgbackrest.conf \
    &&  chmod +x /entrypoint.sh


ENTRYPOINT ["/entrypoint.sh"]
