# See here for image contents: https://github.com/microsoft/vscode-dev-containers/tree/v0.202.5/containers/python-3/.devcontainer/base.Dockerfile
FROM mcr.microsoft.com/vscode/devcontainers/python:0-3.9-bullseye

COPY requirements.txt /tmp/pip-tmp/
RUN pip3 --disable-pip-version-check --no-cache-dir install -r /tmp/pip-tmp/requirements.txt \
   && rm -rf /tmp/pip-tmp

# [Optional] Uncomment this section to install additional OS packages.
RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
   && apt-get -y install --no-install-recommends \
   libgmp3-dev \
   software-properties-common && \
   rm -rf /var/lib/apt/lists/*

RUN mkdir /loot
WORKDIR /loot/
RUN git clone --recurse-submodules https://github.com/BibliothecaForAdventurers/realms-contracts.git
ENV CAIRO_PATH=/loot/realms-contracts/lib/cairo_contracts/src
WORKDIR /loot/realms-contracts/
RUN pip3 install realms_cli/

RUN curl -L https://raw.githubusercontent.com/software-mansion/protostar/master/install.sh | bash -s -- -v 0.8.1
RUN curl -L https://foundry.paradigm.xyz | bash
RUN /root/.foundry/bin/foundryup
