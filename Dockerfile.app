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
    apt-get install -y --no-install-recommends wget && \
    wget https://release.gitkraken.com/linux/gitkraken-amd64.deb  -P /tmp && \
    apt remove -y wget && \
    apt install -y gconf2 gconf-service libgtk2.0-0 libnotify4 libnss3 gvfs-bin xdg-utils libxss1 libasound2 procps && \
    dpkg -i /tmp/gitkraken-amd64.deb && \
    rm -rf /tmp/gitkraken-amd64.deb && \
    rm -rf /var/lib/apt/lists

COPY --from=easy-novnc-build /bin/easy-novnc /usr/local/bin/
COPY menu.xml /etc/xdg/openbox/
COPY supervisord.conf /etc/
EXPOSE 8080

ARG UID=1097
ARG GID=1104


RUN groupadd --gid $GID app && \
    useradd --home-dir /data --shell /bin/bash --uid $UID --gid $GID app && \
    mkdir -p /data
VOLUME /data

CMD ["sh", "-c", "chown app:app /data /dev/stdout && exec gosu app supervisord"]
