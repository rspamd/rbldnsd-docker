ARG DEBIAN_VERSION=bookworm
FROM debian:${DEBIAN_VERSION}

RUN	apt-get update && \
	apt-get install -y cmake g++ gcc libjemalloc-dev libev-dev make pkg-config python3-pip python3-venv zlib1g-dev && \
	python3 -mvenv /venv && \
	bash -c "source /venv/bin/activate && pip install py3dns robotframework" && \
	useradd rbldns
