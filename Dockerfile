FROM python:3.6-alpine as py-ea
ARG ELASTALERT_VERSION=v0.3.0-b
ENV ELASTALERT_VERSION=${ELASTALERT_VERSION}
# URL from which to download Elastalert.
ARG ELASTALERT_URL=https://github.com/sherifabdlnaby/elastalert/archive/$ELASTALERT_VERSION.zip
ENV ELASTALERT_URL=${ELASTALERT_URL}
# Elastalert home directory full path.
ENV ELASTALERT_HOME /opt/elastalert

WORKDIR /opt

RUN apk add --update --no-cache ca-certificates openssl-dev openssl libffi-dev gcc musl-dev wget && \
# Download and unpack Elastalert.
    wget -O elastalert.zip "${ELASTALERT_URL}" && \
    unzip elastalert.zip && \
    rm elastalert.zip && \
    mv e* "${ELASTALERT_HOME}"

WORKDIR "${ELASTALERT_HOME}"

# Install Elastalert.
# see: https://github.com/Yelp/elastalert/issues/1654
RUN sed -i 's/jira>=1.0.10/jira>=1.0.10,<1.0.15/g' setup.py && \
    python setup.py install && \
    pip install -r requirements.txt

FROM node:alpine
LABEL maintainer="Sherif Abdel-Naby <sherifabdlnaby@gmail.com>"
# Set timezone for this container
ENV TZ Etc/UTC

RUN apk add --update --no-cache curl tzdata python3=3.6.8-r2 make libmagic

COPY --from=py-ea /usr/local/lib/python3.6/site-packages /usr/lib/python3.6/site-packages
COPY --from=py-ea /opt/elastalert /opt/elastalert

WORKDIR /opt/elastalert-server
COPY . /opt/elastalert-server

RUN npm install --production --silent && npm install -g --production --silent envsub

# Add default rules directory
# Set permission as unpriviledged user (1000:1000), compatible with Kubernetes
RUN ln -s /usr/bin/python3 /usr/bin/python && \
    mkdir -p /opt/elastalert/rules/ /opt/elastalert/server_data/tests/ && \
    chown -R node:node /opt && chmod +x /opt/elastalert-server/docker-entrypoint.sh

USER node

EXPOSE 3030

VOLUME [ "/opt/config/config.yaml", "/opt/config/config-test.yaml", "/opt/config/config.json", "/opt/elastalert/rules", "/opt/elastalert/rule_templates"]

ENTRYPOINT ["/opt/elastalert-server/docker-entrypoint.sh"]
