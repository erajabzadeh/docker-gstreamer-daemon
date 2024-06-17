# syntax=docker/dockerfile:1

ARG GSTD_VERSION=feature-libsoup3
ARG GST_PLUGINS_INTERPIPE_VERSION=1.1.8
ARG GST_PLUGINS_RUST_VERSION=0.12.0

FROM debian:bookworm AS gstd-builder

ARG GSTD_VERSION
ARG GST_PLUGINS_INTERPIPE_VERSION

RUN \
        apt-get update \
        && apt-get install --no-install-recommends -y \
                automake \
                build-essential \
                ca-certificates \
                curl \
                git \
                gstreamer1.0-libav \
                gstreamer1.0-plugins-base \
                gstreamer1.0-plugins-good \
                gstreamer1.0-plugins-bad \
                gstreamer1.0-plugins-ugly \
                gstreamer1.0-tools \
                gstreamer1.0-vaapi \
                gstreamer1.0-x \
                gtk-doc-tools \
                libdaemon-dev \
                libedit-dev \
                libglib2.0-dev \
                libgstreamer-plugins-bad1.0-dev \
                libgstreamer-plugins-base1.0-dev \
                libgstreamer1.0-dev \
                libjansson-dev \
                libjson-glib-dev \
                libncursesw5-dev \
                libsoup-3.0-dev \
                libssl-dev \
                libtool \
                pkg-config \
                python3-pip \
                sudo \
        && rm /usr/lib/python3.11/EXTERNALLY-MANAGED

RUN \
        curl -sSLJ https://github.com/erajabzadeh/gstd-1.x/archive/refs/heads/feature/libsoup3.tar.gz | tar -C /usr/src -xzf - \
        && cd /usr/src/gstd-1.x-${GSTD_VERSION} \
        && ./autogen.sh \
        && ./configure \
        && make \
        && make install

RUN \
        git clone --depth 1 --branch v${GST_PLUGINS_INTERPIPE_VERSION} https://github.com/RidgeRun/gst-interpipe.git /usr/src/gst-interpipe \
        && cd /usr/src/gst-interpipe \
        && ./autogen.sh --libdir /usr/lib/x86_64-linux-gnu/gstreamer-1.0 \
        && make \
        && make check \
        && make install


FROM rust:1.79-bookworm AS plugins-builder

ARG GST_PLUGINS_RUST_VERSION

RUN \
        apt-get update \
        && apt-get install --no-install-recommends -y \
                build-essential \
                ca-certificates \
                curl \
                gstreamer1.0-plugins-base \
                gstreamer1.0-plugins-good \
                gstreamer1.0-plugins-bad \
                gstreamer1.0-plugins-ugly \
                gstreamer1.0-x \
                libglib2.0-dev \
                libgstreamer-plugins-bad1.0-dev \
                libgstreamer-plugins-base1.0-dev \
                libgstreamer1.0-dev \
                libssl-dev \
                pkg-config

RUN \
        curl -sSJ "https://gitlab.freedesktop.org/gstreamer/gst-plugins-rs/-/archive/${GST_PLUGINS_RUST_VERSION}/gst-plugins-rs-${GST_PLUGINS_RUST_VERSION}.tar.gz"  | tar -C /usr/src -xzf - \
        && cd /usr/src/gst-plugins-rs-${GST_PLUGINS_RUST_VERSION} \
        && cargo install cargo-c \
        && cargo cbuild \
                -p gst-plugin-aws \
                -p gst-plugin-audiofx \
                -p gst-plugin-inter \
                -p gst-plugin-tracers \
                -p gst-plugin-fallbackswitch \
                -p gst-plugin-uriplaylistbin \
                -p gst-plugin-livesync \
                --prefix=/usr \
        && cargo cinstall \
                -p gst-plugin-aws \
                -p gst-plugin-audiofx \
                -p gst-plugin-inter \
                -p gst-plugin-tracers \
                -p gst-plugin-fallbackswitch \
                -p gst-plugin-uriplaylistbin \
                -p gst-plugin-livesync \
                --prefix=/usr


FROM debian:bookworm AS runner

RUN \
        apt-get update \
        && apt-get install --no-install-recommends -y \
                ca-certificates \
                gstreamer1.0-libav \
                gstreamer1.0-plugins-base \
                gstreamer1.0-plugins-good \
                gstreamer1.0-plugins-bad \
                gstreamer1.0-plugins-ugly \
                gstreamer1.0-tools \
                gstreamer1.0-vaapi \
                gstreamer1.0-x

COPY --from=gstd-builder /usr/lib/x86_64-linux-gnu /usr/lib/x86_64-linux-gnu/
COPY --from=gstd-builder /usr/local/bin /usr/local/bin
COPY --from=gstd-builder /usr/local/lib /usr/local/lib
COPY --from=plugins-builder /usr/lib/gstreamer-1.0 /usr/lib/x86_64-linux-gnu/gstreamer-1.0

RUN ldconfig -v

ENV GST_DEBUG=${GST_DEBUG:-2}

EXPOSE 5000

CMD ["gstd", "-t", "-a", "0.0.0.0"]
