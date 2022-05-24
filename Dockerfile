FROM ubuntu:latest
MAINTAINER FINDOLOGIC Developers <dev@findologic.com>

RUN apt-get update \
    && apt-get install -y bash git wget jq
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]