FROM python:3-slim-buster as builder

LABEL description="ElastAlert 2 Official Image"
LABEL maintainer="Jason Ertel"

COPY . /tmp/elastalert

FROM debian:buster
#FROM python:3-slim-buster

ARG DEBIAN_FRONTEND=noninteractive
ARG GID=1000
ARG UID=1000
ARG USERNAME=elastalert

COPY --from=builder /tmp/elastalert/dist/*.tar.gz /tmp/

RUN apt update && apt -y upgrade && \
    apt -y install jq curl gcc libffi-dev python3 python-pip && \
    rm -rf /var/lib/apt/lists/* && \
    pip install /tmp/*.tar.gz && \
    rm -rf /tmp/* && \
    apt -y remove gcc libffi-dev && \
    apt -y autoremove && \
    mkdir -p /opt/elastalert && \
    echo "#!/bin/sh" >> /opt/elastalert/run.sh && \
    echo "set -e" >> /opt/elastalert/run.sh && \
    echo "elastalert-create-index --config /opt/elastalert/config.yaml" \
        >> /opt/elastalert/run.sh && \
    echo "elastalert --config /opt/elastalert/config.yaml \"\$@\"" \
        >> /opt/elastalert/run.sh && \
    chmod +x /opt/elastalert/run.sh && \
    groupadd -g ${GID} ${USERNAME} && \
    useradd -u ${UID} -g ${GID} -M -b /opt -s /sbin/nologin \
        -c "ElastAlert 2 User" ${USERNAME}

RUN mkdir -p /opt/elastalert && \
    cd /tmp/elastalert && \
    pip install setuptools wheel && \
    python setup.py sdist bdist_wheel

USER ${USERNAME}
ENV TZ "UTC"

WORKDIR /opt/elastalert
ENTRYPOINT ["/opt/elastalert/run.sh"]
