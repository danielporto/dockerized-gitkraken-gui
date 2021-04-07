FROM golang:1.14-buster AS easy-novnc-build
WORKDIR /src
RUN go mod init build && \
    go get github.com/geek1011/easy-novnc@v1.1.0 && \
    go build -o /bin/easy-novnc github.com/geek1011/easy-novnc

FROM debian:buster

RUN apt-get update -y && \
    apt-get install -y --no-install-recommends openbox tigervnc-standalone-server supervisor gosu && \
    rm -rf /var/lib/apt/lists && \
    mkdir -p /usr/share/desktop-directories

RUN apt-get update -y && \
    apt-get install -y --no-install-recommends lxterminal nano wget openssh-client rsync ca-certificates xdg-utils htop tar xzip gzip bzip2 zip unzip && \
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

COPY --from=easy-novnc-build /bin/easy-novnc /usr/local/bin/
COPY menu.xml /etc/xdg/openbox/
COPY supervisord.conf /etc/
EXPOSE 8080

ARG UID=1097
ARG GID=1145


RUN groupadd --gid $GID app && \
    useradd --home-dir /data --shell /bin/bash --uid $UID --gid $GID app && \
    mkdir -p /data
VOLUME /data

CMD ["sh", "-c", "chown app:app /data /dev/stdout && exec gosu app supervisord"]
