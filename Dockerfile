FROM debian:12-slim

ARG GSTD_VERSION=0.15.0
ARG GST_INTERPIPE_VERSION=1.1.8

RUN apt-get update \
        && apt-get install --no-install-recommends -y \
                ca-certificates \
                debootstrap \
                pkg-config \
                sudo

RUN mkdir -p /srv/chroot/gstd \
        && debootstrap bookworm /srv/chroot/gstd http://deb.debian.org/debian \
        && chroot /srv/chroot/gstd \
        && apt-get install --no-install-recommends -y \
                automake \
                build-essential \
                curl \
                git \
                gstreamer1.0-libav \
                gstreamer1.0-plugins-bad \
                gstreamer1.0-plugins-base \
                gstreamer1.0-plugins-good \
                gstreamer1.0-plugins-ugly \
                gstreamer1.0-tools \
                gstreamer1.0-vaapi \
                gtk-doc-tools \
                libdaemon-dev \
                libedit-dev \
                libglib2.0-dev \
                libgstreamer-plugins-bad1.0-dev \
                libgstreamer-plugins-base1.0-dev \
                libgstreamer1.0-dev \
                libjansson-dev \
                libjson-glib-dev \
                libncurses-dev \
                libsoup2.4-dev \
                libtool \
                python3-pip

RUN rm /usr/lib/python3.11/EXTERNALLY-MANAGED

RUN chroot /srv/chroot/gstd \
        && curl -sSLJ https://github.com/RidgeRun/gstd-1.x/archive/refs/tags/v${GSTD_VERSION}.tar.gz | tar -C /usr/src -xzf - \
        && cd /usr/src/gstd-1.x-${GSTD_VERSION} \
        && ./autogen.sh \
        && ./configure \
        && make \
        && make install

RUN chroot /srv/chroot/gstd \
        && git clone --depth 1 --branch v${GST_INTERPIPE_VERSION} https://github.com/RidgeRun/gst-interpipe.git /usr/src/gst-interpipe-${GST_INTERPIPE_VERSION} \
        && cd /usr/src/gst-interpipe-${GST_INTERPIPE_VERSION} \
        && ./autogen.sh --libdir /usr/lib/x86_64-linux-gnu/gstreamer-1.0/ \
        && make \
        && make check \
        && make install

ENV GST_DEBUG=${GST_DEBUG:-2}

EXPOSE 5000

CMD ["gstd", "-t", "-a", "0.0.0.0"]
