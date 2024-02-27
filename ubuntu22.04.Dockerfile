FROM ubuntu:22.04

ARG TAG
COPY scripts /tmp/scripts
RUN /tmp/scripts/ubuntu.sh ${TAG}
