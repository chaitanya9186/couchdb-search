
# FROM debian:jessie

FROM openjdk:7

ENV COUCHDB_VERSION couchdb-search

ENV MAVEN_VERSION 3.3.3

RUN groupadd -r couchdb && useradd -d /opt/couchdb -g couchdb couchdb

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
    supervisor \
    ca-certificates \
    curl \
    erlang-nox \
    erlang-reltool \
    libicu52 \
    libmozjs185-1.0 \
    openssl \
    libdbus-glib-1-2 \
    openjdk-7-jdk \
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
 && make \
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
 && rm -rf /var/lib/apt/lists/* /usr/lib/node_modules

# Add configuration
COPY local.ini /usr/src/couchdb/rel/overlay/etc/
COPY vm.args /usr/src/couchdb/rel/overlay/etc/
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Setup directories and permissions
RUN chown -R couchdb:couchdb /usr/src/couchdb/

RUN mkdir -p /var/log/supervisor/ \
 && chmod 755 /var/log/supervisor/

WORKDIR /usr/src/couchdb
EXPOSE 5984

ENTRYPOINT ["/usr/bin/supervisord"]
