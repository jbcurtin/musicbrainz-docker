FROM debian:bullseye

RUN apt-get update
RUN apt-get upgrade -y
RUN apt-get install -y \
    postgresql-12 \
    postgresql-contrib-12 \
    postgresql-server-dev-12 \
    git \
    nodejs \
    redis-server \
    build-essential \
    bzip2 \
    vim

RUN apt-get install -y \
    libdb-dev \
    libexpat1-dev \
    libicu-dev \
    liblocal-lib-perl \
    libpq-dev \
    libxml2 \
    libxml2-dev \
    cpanminus \
    pkg-config \
    liblwp-protocol-https-perl

RUN adduser muse --home /home/muse --gecos "" --disabled-password --shell /bin/bash
RUN chown muse.muse -R /home/muse
WORKDIR /home/muse
USER muse

RUN git clone --recursive https://github.com/metabrainz/musicbrainz-server.git
COPY --chown=muse ./configs/.bashrc /home/muse/.bashrc
RUN . /home/muse/.bashrc && \
    cd musicbrainz-server && \
    cpanm --installdeps --notest .
USER root
RUN cpan JSON
USER muse
COPY --chown=muse ./configs/DBDefs.pm ./musicbrainz-server/lib/DBDefs.pm
WORKDIR /home/muse/musicbrainz-server
