#syntax=docker/dockerfile:1.6

FROM archlinux:latest

ARG GIT_USER_NAME="ThrowTheSwitch"
ENV GIT_USER_NAME=${GIT_USER_NAME}

# Set the locale
ENV TERM=xterm-256color
ENV STARSHIP_CONFIG=/etc/starship/starship.toml

# Install basic dependencies for the system
RUN pacman -Syu --noconfirm && \
    pacman -S --noconfirm \
    glibc \
    base \
    base-devel \
    sudo \
    bash \
    less

ENV PATH="/usr/bin:$PATH"

RUN pacman -Syu --noconfirm \
    git \
    curl \
    wget

RUN pacman -Syu --noconfirm \
    openssh \
    ca-certificates \
    zip \
    unzip \
    vim \
    tree

RUN pacman -Syu --noconfirm \
    fish \
    starship \
    noto-fonts \
    noto-fonts-emoji \
    fzf \
    ripgrep \
    fd \
    universal-ctags

# Create dev user
ARG USERNAME=Dev
ARG UID=1000
ARG GID=1000

RUN groupadd -g ${GID} ${USERNAME} && \
    useradd -m -u ${UID} -g ${GID} -s /usr/bin/fish ${USERNAME}

RUN echo "${USERNAME} ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/${USERNAME} && \
    chmod 0440 /etc/sudoers.d/${USERNAME}

# Install development dependencies
RUN pacman -Syu --noconfirm \
    make \
    cmake \
    ninja

RUN pacman -Syu --noconfirm \
    bash-language-server \
    fzf

RUN pacman -Syu --noconfirm \
    llvm \
    clang \
    clang-tools-extra

RUN pacman -Syu --noconfirm \
    gdb \
    valgrind \
    gtest


RUN pacman -Syu --noconfirm \
    ruby \
    ruby-irb \
    ruby-rake \
    ruby-bundler

# Seed the Docker image with CMock repository and its dependencies
RUN git clone "https://github.com/${GIT_USER_NAME}/CMock.git" /opt/CMock && \
    cd /opt/CMock && \
    bundle install && \
    chown -R Dev:Dev /opt/CMock

USER ${USERNAME}
ENV HOME=/home/Dev

# Install Vim cofiguration
RUN sudo mkdir -p /usr/share/vim/vimfiles/autoload && \
    sudo curl -fLo /usr/share/vim/vimfiles/autoload/plug.vim \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

COPY Resources/vim /home/Dev/.vim
COPY Resources/vim/.vimrc /home/Dev/.vimrc
RUN vim +'PlugInstall --sync' +qa

# Copy and execute configuration scripts
RUN sudo mkdir -p /etc/fish/conf.d
RUN sudo mkdir -p /opt/container-scripts

ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8

COPY Resources/init.sh /opt/container-scripts/init.sh
COPY Resources/logging.sh /opt/container-scripts/logging.sh
COPY Resources/fish-starship.fish /etc/fish/conf.d/starship.fish
COPY Resources/starship.toml /etc/starship/starship.toml

RUN sudo chmod +x /opt/container-scripts/init.sh

# Configure the entrypoint
WORKDIR /workspace
ENTRYPOINT ["/usr/bin/fish", "-lc", "/opt/container-scripts/init.sh; exec fish"]
