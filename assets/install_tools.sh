#!/bin/bash
apt-get -qy update && apt-get install -qy \
    man \
    vim \
    nano \
    htop \
    curl \
    wget \
    rsync \
    ca-certificates \
    git \
    zip \
    procps \
    ssh \
    gettext-base \
    transmission-cli \
    python3-venv \
    supervisor \
    && apt-get -qq clean \
    && rm -rf /var/lib/apt/lists/*

