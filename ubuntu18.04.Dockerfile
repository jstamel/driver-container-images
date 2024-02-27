FROM ubuntu:18.04

ARG TAG
COPY scripts /tmp/scripts
RUN /tmp/scripts/ubuntu.sh ${TAG}
