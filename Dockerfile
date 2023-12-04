ARG DEBIAN_RELEASE=bookworm
ARG RBLDNSD_VERSION=1.0.1

FROM rspamd/rbldnsd:build AS build

ARG RBLDNSD_VERSION
ENV DEBEMAIL=support@rspamd.com
ENV RBLDNSD_VERSION=$RBLDNSD_VERSION

COPY patches/ /patches/

RUN	apt-get update -y && \
	apt-get install -y git debhelper && \
	mkdir /src && \
	cd /src && \
	git clone -b ${RBLDNSD_VERSION} https://github.com/rspamd/rbldnsd.git && \
	cd rbldnsd && \
	git apply /patches/*.diff && \
	sed -i s/\(.*\)/\(${RBLDNSD_VERSION}\)/ debian/changelog && \
	dpkg-buildpackage -us -uc

ARG DEBIAN_RELEASE

FROM debian:${DEBIAN_RELEASE}-slim AS install

RUN	--mount=type=cache,from=build,source=/src,target=/src apt-get update && \
	dpkg -i /src/*deb || true && \
	apt-get install -f -y && \
	apt-get -q clean && \
	dpkg-query --no-pager -l rbldnsd

ENTRYPOINT /usr/sbin/rbldnsd -b 0.0.0.0/53 -n "$@"

EXPOSE 53/udp
