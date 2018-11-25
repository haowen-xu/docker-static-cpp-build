#FROM ubuntu:16.04
FROM alpine:3.8

MAINTAINER Haowen Xu <haowen.xu@outlook.com>

ARG MAKE_ARGS=

# Do basic configuration of the system, and install build tools
RUN apk update && \
    apk add --no-cache binutils cmake make libgcc musl-dev gcc g++ perl linux-headers && \
    ln -s /usr/bin/x86_64-alpine-linux-musl-gcc-ar /usr/bin/x86_64-alpine-linux-musl-ar && \
    ln -s /usr/bin/x86_64-alpine-linux-musl-gcc-ranlib /usr/bin/x86_64-alpine-linux-musl-ranlib && \
    ln -s /usr/bin/x86_64-alpine-linux-musl-gcc-nm /usr/bin/x86_64-alpine-linux-musl-nm && \
    ln -s /usr/bin/strip /usr/bin/x86_64-alpine-linux-musl-strip && \
    ln -s /usr/bin/objcopy /usr/bin/x86_64-alpine-linux-musl-objcopy
ENV CROSS_COMPILE="/usr/bin/x86_64-alpine-linux-musl-"

# Compile and install the static OpenSSL library
ENV OPENSSL_VERSION=1.1.1
RUN wget -O /tmp/openssl-${OPENSSL_VERSION}.tar.gz https://www.openssl.org/source/openssl-${OPENSSL_VERSION}.tar.gz && \
    cd /tmp && \
    tar xzvf /tmp/openssl-${OPENSSL_VERSION}.tar.gz && \
    rm /tmp/openssl-${OPENSSL_VERSION}.tar.gz && \
    cd /tmp/openssl-${OPENSSL_VERSION} && \
    ./Configure -static --static no-shared no-async no-hw no-zlib no-pic no-dso \
                no-engine no-threads linux-x86_64 && \
    make ${MAKE_ARGS} && \
    make install && \
    cd /tmp && \
    rm -rf /tmp/openssl-${OPENSSL_VERSION}

# Compile and install the Poco library
ENV POCO_VERSION=1.9.0
RUN wget -O /tmp/poco-${POCO_VERSION}-all.tar.gz https://pocoproject.org/releases/poco-${POCO_VERSION}/poco-${POCO_VERSION}-all.tar.gz && \
    cd /tmp && \
    tar xzvf /tmp/poco-${POCO_VERSION}-all.tar.gz && \
    rm /tmp/poco-${POCO_VERSION}-all.tar.gz && \
    cd /tmp/poco-${POCO_VERSION}-all && \
    ./configure --config=Linux --omit=Data/ODBC,Data/MySQL --static --cflags="-static" --no-tests --no-samples && \
    make ${MAKE_ARGS} && \
    make install && \
    cd /tmp && \
    rm -rf /tmp/poco-${POCO_VERSION}-all

# Compile and install the Boost library
ENV BOOST_VERSION=1.68.0
RUN wget -O /tmp/boost_${BOOST_VERSION//./_}.tar.gz https://dl.bintray.com/boostorg/release/${BOOST_VERSION}/source/boost_${BOOST_VERSION//./_}.tar.gz && \
    cd /tmp && \
    tar xzvf /tmp/boost_${BOOST_VERSION//./_}.tar.gz && \
    rm /tmp/boost_${BOOST_VERSION//./_}.tar.gz && \
    cd /tmp/boost_${BOOST_VERSION//./_} && \
    ./bootstrap.sh && \
    echo "using gcc : musl : x86_64-alpine-linux-musl-g++ ;" >> project-config.jam && \
    ./b2 install --build-type=minimal toolset=gcc-musl variant=release link=static threading=multi runtime-link=static && \
    rm -rf /tmp/boost_${BOOST_VERSION//./_}

# setup the default linker options
ENV DEFAULT_LINKER_OPTIONS="-static -L/usr/local/lib -lPocoNetSSL -lPocoCrypto -lPocoNet -lPocoZip -lPocoUtil -lPocoXML -lPocoJSON -lPocoFoundation -lpthread -lssl -lcrypto"

# Install the entry script
COPY entry.sh /
ENTRYPOINT ["/entry.sh"]
