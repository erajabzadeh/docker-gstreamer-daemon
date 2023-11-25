FROM debian:11

ARG GSTD_VERSION=0.15.0
ARG GST_INTERPIPE_VERSION=1.1.8

RUN apt-get update \
        && apt-get -y --no-install-recommends install software-properties-common \
        && add-apt-repository "deb http://httpredir.debian.org/debian sid main" \
        && apt-get update \
        && apt-get install --no-install-recommends -y \
                automake \
                build-essential \
                ca-certificates \
                curl \
                git \
                gtk-doc-tools \
                libdaemon-dev \
                libedit-dev \
                libglib2.0-dev \
                libncurses-dev \
                libsoup2.4-dev \
                libtool \
                pkg-config \
                python3-pip \
                sudo \
        && apt-get install -t sid --no-install-recommends -y \
                gstreamer1.0-libav \
                gstreamer1.0-plugins-base \
                gstreamer1.0-plugins-good \
                gstreamer1.0-plugins-bad \
                gstreamer1.0-plugins-ugly \
                gstreamer1.0-tools \
                gstreamer1.0-vaapi \
                gstreamer1.0-x \
                libgstreamer-plugins-bad1.0-dev \
                libgstreamer-plugins-base1.0-dev \
                libgstreamer1.0-dev \
                libjansson-dev \
                libjson-glib-dev

RUN curl -sSLJ https://github.com/RidgeRun/gstd-1.x/archive/refs/tags/v${GSTD_VERSION}.tar.gz \
        | tar -C /usr/src -xzf - \
        && cd /usr/src/gstd-1.x-${GSTD_VERSION} \
        && ./autogen.sh \
        && ./configure \
        && make \
        && make install

RUN git clone --depth 1 --branch v${GST_INTERPIPE_VERSION} https://github.com/RidgeRun/gst-interpipe.git /usr/src/gst-interpipe \
        && cd /usr/src/gst-interpipe \
        && ./autogen.sh --libdir /usr/lib/x86_64-linux-gnu/gstreamer-1.0/ \
        && make \
        && make check \
        && make install

ENV GST_DEBUG=${GST_DEBUG:-2}

EXPOSE 5000

CMD ["gstd", "-t", "-a", "0.0.0.0", "--gst-debug-no-color"]

