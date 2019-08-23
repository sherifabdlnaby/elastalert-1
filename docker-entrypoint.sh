#!/bin/sh

# Substitute Env Variables in config
envsub /opt/config/config.yaml /opt/elastalert/config.yaml
envsub /opt/config/config-test.yaml /opt/elastalert/config-test.yaml
envsub /opt/config/config.json /opt/elastalert-server/config/config.json

exec npm start
