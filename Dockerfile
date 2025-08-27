FROM ubuntu:jammy

RUN mkdir /opt/cs
WORKDIR /opt/cs
#APT-PLACE-HOLDER
RUN set -e \
	&& apt update \
	&& apt remove -y python* \
	&& apt autoremove \
	&& apt autoclean \
	&& apt autopurge \
	&& apt install -y wget git aria2

#install code-server online
RUN set -e \
	&& aria2c --max-connection-per-server=10 --min-split-size=1M --max-concurrent-downloads=10 "https://github.com/coder/code-server/releases/download/v4.93.1/code-server_4.93.1_amd64.deb" -o "code-server_4.93.1_amd64.deb" \
	&& dpkg -i ./code-server_4.93.1_amd64.deb \
	&& rm -rf ./code-server_4.93.1_amd64.deb

#install graalvm
RUN set -e \
	&& mkdir -p /opt/graalvm \
	&& cd /opt/graalvm \
	&& aria2c --max-connection-per-server=10 --min-split-size=1M --max-concurrent-downloads=10 https://download.oracle.com/graalvm/21/latest/graalvm-jdk-21_linux-x64_bin.tar.gz \
	&& tar -zxvf ./graalvm-jdk-21_linux-x64_bin.tar.gz \
	&& rm -rf ./graalvm-jdk-21_linux-x64_bin.tar.gz \
	&& ln -s /opt/graalvm/graalvm-jdk-21.0.6+8.1/bin/java /usr/bin/java \
	&& ln -s /opt/graalvm/graalvm-jdk-21.0.6+8.1/bin/javac /usr/bin/javac \
	&& ln -s /opt/graalvm/graalvm-jdk-21.0.6+8.1/bin/native-image /usr/bin/native-image
ENV JAVA_HOME=/opt/graalvm/graalvm-jdk-21.0.6+8.1
ENV GRAALVM_HOME=/opt/graalvm/graalvm-jdk-21.0.6+8.1

RUN set -e \
	&& cd /opt \
	&& aria2c --max-connection-per-server=10 --min-split-size=1M --max-concurrent-downloads=10 https://dlcdn.apache.org/maven/maven-3/3.9.11/binaries/apache-maven-3.9.11-bin.tar.gz \
	&& tar -zxvf apache-maven-3.9.11-bin.tar.gz \
	&& rm -rf apache-maven-3.9.11-bin.tar.gz \
	&& ln -s /opt/apache-maven-3.9.11/bin/mvn /usr/bin/mvn

RUN set -e \
	&& apt install -y curl \
	&& mkdir /opt/uv \
        && cd /opt/uv \
        && DOWNLOAD=$(curl -s https://api.github.com/repos/astral-sh/uv/releases/latest | grep browser_download_url |grep linux|grep x86_64| grep -v rocm| cut -d'"' -f4) \
        && aria2c -x 10 -j 10 -k 1M $DOWNLOAD -o uv.tar.gz \
        && tar -zxvf uv.tar.gz \
        && rm -rf uv.tar.gz \
        && ln -s /opt/uv/uv-x86_64-unknown-linux-gnu/uv /usr/bin/uv \
        && ln -s /opt/uv/uv-x86_64-unknown-linux-gnu/uvx /usr/bin/uvx \
	&& uv venv /opt/venv --python 3.12

RUN set -e \
	&& /usr/bin/code-server --install-extension vscjava.vscode-java-pack \
	#&& /usr/bin/code-server --install-extension gabrielbb.vscode-lombok \
	&& /usr/bin/code-server --install-extension alphabotsec.vscode-eclipse-keybindings \
	&& /usr/bin/code-server --install-extension arzg.intellij-theme \
	&& /usr/bin/code-server --install-extension ms-python.python
	#&& /usr/bin/code-server --install-extension tht13.python

RUN set -e \
	&& apt install -y nginx ttyd \
	&& apt install -y curl

RUN set -e \
	&& mkdir /opt/filebrowser \
        && cd /opt/filebrowser\
        && DOWNLOAD=$(curl -s https://api.github.com/repos/filebrowser/filebrowser/releases/latest | grep browser_download_url |grep linux|grep amd64| grep -v rocm| cut -d'"' -f4) \
        && aria2c -x 10 -j 10 -k 1M $DOWNLOAD -o linux-amd64-filebrowser.tar.gz \
        && tar -zxvf linux-amd64-filebrowser.tar.gz \
        && rm -rf linux-amd64-filebrowser.tar.gz \
        && ln -s /opt/filebrowser/filebrowser /usr/bin/filebrowser

RUN rm -rf /etc/nginx/sites-enabled/default
ADD ./NGINX /etc/nginx/sites-enabled/
COPY ./docker-entrypoint.sh /
RUN chmod +x /docker-entrypoint.sh

#install chinese support
RUN set -e \
	&& apt install -y language-pack-zh-hans \
	&& locale-gen zh_CN.UTF-8 \
	&& sed -i '1a\export LC_ALL=zh_CN.UTF-8' /docker-entrypoint.sh

#install scala
RUN set -e \
        && mkdir -p /opt/scala \
        && cd /opt/scala \
        && aria2c --max-connection-per-server=10 --min-split-size=1M --max-concurrent-downloads=10 https://github.com/scala/scala3/releases/download/3.3.5/scala3-3.3.5.tar.gz \
        && tar -zxvf ./scala3-3.3.5.tar.gz \
        && rm -rf ./scala3-3.3.5.tar.gz \
        && ln -s /opt/scala/scala3-3.3.5/bin/scala /usr/bin/scala \
        && ln -s /opt/scala/scala3-3.3.5/bin/scalac /usr/bin/scalac
ENV SCALA_HOME=/opt/scala/scala3-3.3.5

CMD ["--bind-addr", "127.0.0.1:8080", "--auth", "none"]
ENTRYPOINT ["/docker-entrypoint.sh"]

RUN set -e \
	&& cd /tmp \
	&& aria2c -x 10 -j 10 -k 1m https://github.com/gohugoio/hugo/releases/download/v0.148.2/hugo_extended_0.148.2_linux-amd64.deb -o hugo.deb \
	&& dpkg -i hugo.deb \
	&& apt install -y libsass1 \
	&& ln -s /usr/local/bin/hugo /usr/bin/hugo \
	&& rm -rf hugo.deb

VOLUME /usr/local/lib/python3.10/dist-packages
VOLUME /root
VOLUME /opt
VOLUME /workspace
