FROM registry.access.redhat.com/ubi8 

RUN yum install -y iptables && \
    setcap CAP_NET_ADMIN,CAP_NET_RAW,CAP_DAC_READ_SEARCH,CAP_DAC_OVERRIDE=+ep "$(readlink -f `which iptables`)"

COPY init.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/init.sh

ENTRYPOINT ["init.sh"]