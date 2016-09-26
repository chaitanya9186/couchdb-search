
FROM debian:jessie

ENV COUCHDB_VERSION couchdb-search

ENV MAVEN_VERSION 3.3.3

RUN groupadd -r couchdb && useradd -d /opt/couchdb -g couchdb couchdb

# download dependencies
RUN apt-get update -y && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    erlang-nox \
    erlang-reltool \
    libicu52 \
    libmozjs185-1.0 \
    openssl \
    libdbus-glib-1-2 \
    libllvm3.5 \
    openjdk-7-jdk \
  && rm -rf /var/lib/apt/lists/*

# grab gosu for easy step-down from root and tini for signal handling
RUN gpg --keyserver ha.pool.sks-keyservers.net --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4 \
  && curl -o /usr/local/bin/gosu -fSL "https://github.com/tianon/gosu/releases/download/1.7/gosu-$(dpkg --print-architecture)" \
  && curl -o /usr/local/bin/gosu.asc -fSL "https://github.com/tianon/gosu/releases/download/1.7/gosu-$(dpkg --print-architecture).asc" \
  && gpg --verify /usr/local/bin/gosu.asc \
  && rm /usr/local/bin/gosu.asc \
  && chmod +x /usr/local/bin/gosu \
  && gpg --keyserver ha.pool.sks-keyservers.net --recv-keys 6380DC428747F6C393FEACA59A84159D7001A4E5 \
  && curl -o /usr/local/bin/tini -fSL "https://github.com/krallin/tini/releases/download/v0.9.0/tini" \
  && curl -o /usr/local/bin/tini.asc -fSL "https://github.com/krallin/tini/releases/download/v0.9.0/tini.asc" \
  && gpg --verify /usr/local/bin/tini.asc \
  && rm /usr/local/bin/tini.asc \
  && chmod +x /usr/local/bin/tini

RUN curl -fsSL http://archive.apache.org/dist/maven/maven-3/$MAVEN_VERSION/binaries/apache-maven-$MAVEN_VERSION-bin.tar.gz | tar xzf - -C /usr/share \
  && mv /usr/share/apache-maven-$MAVEN_VERSION /usr/share/maven \
  && ln -s /usr/share/maven/bin/mvn /usr/bin/mvn

ENV MAVEN_HOME /usr/share/maven

ENV COUCHDB_VERSION 2.0.0

# Download dev dependencies
RUN apt-get update -y -qq && apt-get install -y --no-install-recommends --fix-missing \
    apt-transport-https \
    build-essential \
    erlang-dev \
    libcurl4-openssl-dev \
    libicu-dev \
    libmozjs185-dev \
    ssh \
    git-core \
#    supervisor \
 && curl -s https://deb.nodesource.com/gpgkey/nodesource.gpg.key | apt-key add - \
 && echo 'deb https://deb.nodesource.com/node_4.x jessie main' > /etc/apt/sources.list.d/nodesource.list \
 && echo 'deb-src https://deb.nodesource.com/node_4.x jessie main' >> /etc/apt/sources.list.d/nodesource.list \
 && apt-get update -y -qq \
 && apt-get install -y nodejs \
 && npm install -g grunt-cli \
 # Acquire CouchDB source code
 && cd /usr/src \
 && git clone https://github.com/sam/couchdb.git \
 && cd couchdb \
 # Build the release and install into /opt
 && ./configure --disable-docs \
 && make release \
 && mv /usr/src/couchdb/rel/couchdb /opt/ \
 # Cleanup build detritus
 && cd /usr/src \
 && git clone https://github.com/cloudant-labs/clouseau \
 && cd /usr/src/clouseau \
 && mvn -Dmaven.test.skip=true install \
 && apt-get purge -y \
    binutils \
    build-essential \
    cpp \
    erlang-dev \
    git \
    libicu-dev \
    make \
    nodejs \
    perl \
 && apt-get autoremove -y && apt-get clean \
 && apt-get install -y libicu52 --no-install-recommends \
 && rm -rf /var/lib/apt/lists/* /usr/lib/node_modules /usr/src/couchdb*

# Add configuration
COPY local.ini /opt/couchdb/etc/
COPY vm.args /opt/couchdb/etc/
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Setup directories and permissions
RUN mkdir -p /opt/couchdb/data /opt/couchdb/etc/local.d /opt/couchdb/etc/default.d \
 && chown -R couchdb:couchdb /opt/couchdb/

RUN mkdir -p /var/log/supervisor/ \
 && chmod 755 /var/log/supervisor/

WORKDIR /opt/couchdb
EXPOSE 5984
VOLUME ["/opt/couchdb/data"]

ENTRYPOINT ["/usr/bin/supervisord"]
