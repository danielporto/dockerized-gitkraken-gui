FROM golang:1.14-buster AS easy-novnc-build
WORKDIR /src
RUN go mod init build && \
    go get github.com/geek1011/easy-novnc@v1.1.0 && \
    go build -o /bin/easy-novnc github.com/geek1011/easy-novnc

FROM debian:buster

RUN apt-get update -y && \
    apt-get install -y --no-install-recommends openbox tigervnc-standalone-server supervisor gosu tint2 && \
    rm -rf /var/lib/apt/lists && \
    mkdir -p /usr/share/desktop-directories

RUN apt-get update -y && \
    apt-get install -y --no-install-recommends lxterminal zsh git nano vim curl wget openssh-client rsync ca-certificates xdg-utils htop tar xzip gzip bzip2 zip unzip && \
    rm -rf /var/lib/apt/lists

# customize which gui application to run
RUN apt-get update -y && \
    apt-get install -y --no-install-recommends wget keepassxc firefox-esr && \
    wget https://release.gitkraken.com/linux/gitkraken-amd64.deb  -P /tmp && \
    apt install -y gconf2 gconf-service libgtk2.0-0 libnotify4 libnss3 gvfs-bin xdg-utils libxss1 libasound2 procps libgbm-dev && \
    dpkg -i /tmp/gitkraken-amd64.deb && \
    rm -rf /tmp/gitkraken-amd64.deb && \
    rm -rf /var/lib/apt/lists

# adds firefox (sometimes required to authenticate with gitkraken tokens)
RUN apt-get update -y &&  apt install -y --no-install-recommends firefox-esr && rm -rf /var/lib/apt/lists

# adds keepassxc (in case I need to use my credentials)
RUN apt-get update -y &&  apt install -y --no-install-recommends keepassxc && rm -rf /var/lib/apt/lists

# install vscode (for smooth remote container development)
RUN wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg \
    && install -o root -g root -m 644 packages.microsoft.gpg /etc/apt/trusted.gpg.d/ \
    && sh -c 'echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/trusted.gpg.d/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list' \
    && apt update \
    && apt install -y apt-transport-https \
    && apt install code \
    && rm -rf /var/lib/apt/lists

# install goland (Jetbrains Golang IDE)
ENV GOLAND_VERSION=2021.1.1
RUN wget https://download-cf.jetbrains.com/go/goland-${GOLAND_VERSION}.tar.gz \
    && tar xvf goland-${GOLAND_VERSION}.tar.gz -C /opt \
    && rm -f goland-${GOLAND_VERSION}.tar.gz \
    && mv /opt/GoLand-${GOLAND_VERSION} /opt/GoLand \ 
    && chmod -R o+rw /opt/GoLand* \
    && echo "Goland installed"

# configure vnc and supervisord
COPY --from=easy-novnc-build /bin/easy-novnc /usr/local/bin/
COPY menu.xml /etc/xdg/openbox/
COPY supervisord.conf /etc/
EXPOSE 8080

ARG UID=1097
ARG GID=1145


RUN groupadd --gid $GID app && \
    useradd --home-dir /data --shell /bin/bash --uid $UID --gid $GID app && \
    mkdir -p /data && \  
    chown -R app /data 
VOLUME /data


# install asdf
RUN git clone https://github.com/asdf-vm/asdf.git /opt/asdf --branch v0.8.0 \
    && chmod -R o+rw /opt/asdf \
    && echo "ASDF installed"

# customize user environment
USER app 
# install zsh
RUN curl https://raw.githubusercontent.com/danielporto/zsh-dotfiles/master/zimrc -o ~/.zimrc \
    && curl -fsSL https://raw.githubusercontent.com/zimfw/install/master/install.zsh | zsh \
    && curl https://raw.githubusercontent.com/danielporto/zsh-dotfiles/master/gitconfig -o ~/.gitconfig  \
    && echo "Zimfw installed"
    

RUN ls -la /data
# install GOLANG 1.14.13 or 1.16 
ENV GO_INSTALL_VERSION=1.14.13 
ENV PATH="/opt/asdf/bin:/opt/asdf/shims:$PATH"
RUN asdf plugin-add golang https://github.com/kennyp/asdf-golang.git && \
    asdf install golang $GO_INSTALL_VERSION && \
    asdf global golang $GO_INSTALL_VERSION && \
    echo "Golang installed"

USER root

CMD ["sh", "-c", "chown app:app /data /dev/stdout && exec gosu app supervisord"]
