FROM ubuntu:20.04

# RUN sed -i 's/archive.ubuntu.com/mirrors.ustc.edu.cn/g' /etc/apt/sources.list \
# && sed -i 's/security.ubuntu.com/mirrors.ustc.edu.cn/g' /etc/apt/sources.list 

RUN sed -i 's/archive.ubuntu.com/mirrors.163.com/g' /etc/apt/sources.list \
&& sed -i 's/security.ubuntu.com/mirrors.163.com/g' /etc/apt/sources.list 


RUN apt-get update\
&& apt-get install -y \
    openssl \
    net-tools \
    git \
    locales \
    sudo \
    dumb-init \
    vim \
    curl \
    wget \
    bash-completion \
    # kotlin gradle maven htop \
    python2 python3 python3-pip python-is-python3  \
    && rm -rf /var/lib/apt/lists/*


RUN chsh -s /bin/bash
ENV SHELL=/bin/bash

RUN ARCH=amd64 && \
    curl -sSL "https://github.com/boxboat/fixuid/releases/download/v0.4.1/fixuid-0.4.1-linux-$ARCH.tar.gz" | tar -C /usr/local/bin -xzf - && \
    chown root:root /usr/local/bin/fixuid && \
    chmod 4755 /usr/local/bin/fixuid && \
    mkdir -p /etc/fixuid && \
    printf "user: coder\ngroup: coder\n" > /etc/fixuid/config.yml

RUN CODE_SERVER_VERSION=3.12.0 && \
    curl -sSOL https://github.com/cdr/code-server/releases/download/v${CODE_SERVER_VERSION}/code-server_${CODE_SERVER_VERSION}_amd64.deb && \
    sudo dpkg -i code-server_${CODE_SERVER_VERSION}_amd64.deb

## kubectl
RUN curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl && \
    chmod +x ./kubectl && \
    mv ./kubectl /usr/local/bin/kubectl

## helm
RUN HELM_VERSION=v3.0.0 && \
    mkdir /tmp/helm && \
    curl -L https://get.helm.sh/helm-${HELM_VERSION}-linux-amd64.tar.gz -o /tmp/helm/helm.tar.gz && \
    tar xvf /tmp/helm/helm.tar.gz -C /tmp/helm/ && \
    chmod +x /tmp/helm/linux-amd64/helm && \
    sudo -S mv /tmp/helm/linux-amd64/helm /usr/local/bin/helm && \
    rm -r /tmp/helm

# kubectx/kubens/fzf
RUN git clone https://github.com/ahmetb/kubectx /opt/kubectx && \
    ln -s /opt/kubectx/kubectx /usr/local/bin/kubectx && \
    ln -s /opt/kubectx/kubens /usr/local/bin/kubens && \
    git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf && \
    ~/.fzf/install

# nodejs
RUN NODE_VERSION=14 && \
curl -sL https://deb.nodesource.com/setup_${NODE_VERSION}.x | sudo -E bash -

# golang

RUN GOLANG_VERSION=1.17.1 && \
wget -c https://dl.google.com/go/go${GOLANG_VERSION}.linux-amd64.tar.gz -O - | sudo tar -xz -C /usr/local

# dotnet 

RUN wget https://packages.microsoft.com/config/ubuntu/20.04/packages-microsoft-prod.deb -O packages-microsoft-prod.deb \
&& sudo dpkg -i packages-microsoft-prod.deb \
&& rm packages-microsoft-prod.deb
RUN  sudo apt-get update; \
    sudo apt-get install -y apt-transport-https && \
    sudo apt-get update && \
    sudo DEBIAN_FRONTEND=noninteractive  apt-get install -y dotnet-sdk-5.0 \
&& rm -rf /var/lib/apt/lists/*

RUN echo "Asia/Shanghai" > /etc/timezone \ 
&& locale-gen en_US.UTF-8
# We unfortunately cannot use update-locale because docker will not use the env variables
# configured in /etc/default/locale so we need to set it manually.
ENV LC_ALL=en_US.UTF-8

## User account
RUN adduser --disabled-password --gecos '' coder && \
    adduser coder sudo && \
    echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers;

RUN chmod g+rw /home && \
    mkdir -p /home/coder/workspace && \
    chown -R coder:coder /home/coder && \
    chown -R coder:coder /home/coder/workspace;

USER coder

# poetry
RUN pip3 install poetry -i https://pypi.tuna.tsinghua.edu.cn/simple && \
    # cd /usr/local/bin && \
    # ln -s /opt/poetry/bin/poetry && \
    # source $HOME/.poetry/env && \
    $HOME/.local/bin/poetry config virtualenvs.create false

# gopath
RUN ecoh "export PATH=$PATH:/usr/local/go/bin" >> /home/coder/.bashrc

# git env

RUN git config --global core.autocrlf false \
&& git config --global credential.helper store

RUN git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf && \
        ~/.fzf/install

ENV PASSWORD=${PASSWORD:-P@ssw0rd}

RUN echo "source <(kubectl completion bash)" >> /home/coder/.bashrc && \
    echo 'export PS1="\[\e]0;\u@\h: \w\a\]\[\033[01;32m\]\u\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ "' >> /home/coder/.bashrc

WORKDIR /home/coder/project

EXPOSE 8080

ENTRYPOINT ["dumb-init", "fixuid", "-q", "/usr/bin/code-server", "--bind-addr", "0.0.0.0:8080", "."]
