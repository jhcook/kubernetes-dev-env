FROM python:3.9-alpine

RUN apk add --no-cache \
        iptables \
        libcap && \
    setcap CAP_NET_ADMIN,CAP_NET_RAW,CAP_DAC_READ_SEARCH,CAP_DAC_OVERRIDE=+ep "$(readlink -f `which iptables`)"

COPY init.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/init.sh

ENTRYPOINT ["init.sh"]