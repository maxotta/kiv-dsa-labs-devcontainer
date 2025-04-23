FROM ubuntu:24.04
LABEL maintainer="maxmilio@kiv.zcu.cz" \
      org.opencontainers.image.source="https://github.com/maxotta/kiv-dsa-labs-devcontainer"

ARG WORKSPACE_DIR=/workspace
# Volume for preserving the private & public SSH keys for accessing remote VMs
ARG PERSISTENT_DATA_DIR=/var/dsa-labs-dev-container-data

ENV DEBIAN_FRONTEND noninteractive

# Prepare for the installation of external repositories
RUN set -uex; \
    apt-get update ; \
    apt-get -y install gnupg software-properties-common ca-certificates curl apt-transport-https ; \
    mkdir -p /etc/apt/keyrings

# Install common build tools
RUN apt-get install build-essential -y
RUN apt-get install git -y
RUN apt-get install golang -y
RUN apt-get install docker.io -y
RUN apt-get install net-tools iputils-ping -y
# Add HashiCorp repos and install Terraform
RUN set -uex; \
    curl -fsSL https://apt.releases.hashicorp.com/gpg | gpg --dearmor | tee /usr/share/keyrings/hashicorp-archive-keyring.gpg ; \
    gpg --no-default-keyring --keyring /usr/share/keyrings/hashicorp-archive-keyring.gpg --fingerprint ; \
    echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/hashicorp.list ; \
    apt-get update ;\
    apt-get -y install terraform

# Add NodeJS repos and install NodeJS
RUN set -uex; \
    curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg; \
    NODE_MAJOR=22; \
    echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_$NODE_MAJOR.x nodistro main" > /etc/apt/sources.list.d/nodesource.list; \
    apt-get update; \
    apt-get install nodejs -y;

# Update NPM
RUN npm install -g npm@11.3.0

# Install Terrafrom CDK
RUN npm install -g cdktf-cli@latest
# Install some basic networking tools
RUN apt-get install net-tools iputils-ping jq -y
# Install Python3 environment
RUN apt-get -y install git python3 python3-pip pipenv
# Install the Go language
RUN apt-get -y install golang

COPY init-devcontainer.sh /etc

RUN echo '. /etc/init-devcontainer.sh' >> /root/.bashrc ; \
    echo 'export TF_VAR_vm_ssh_pubkey="`cat ${PERSISTENT_DATA_DIR}/id_ecdsa.pub`"' >> /root/.bashrc

WORKDIR ${WORKSPACE_DIR}

VOLUME ${WORKSPACE_DIR} ${PERSISTENT_DATA_DIR}

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ENV PERSISTENT_DATA_DIR ${PERSISTENT_DATA_DIR}
ENV SHELL /bin/bash
ENV ANSIBLE_HOST_KEY_CHECKING False

# Prevent the container to exit
CMD [ "sleep", "infinity" ]

#
# EOF
#
