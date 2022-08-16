FROM registry.access.redhat.com/ubi8/python-39

USER root

RUN yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm && \
    yum install -y conntrack-tools libcap && \
    yum clean all && \
    setcap CAP_NET_BIND_SERVICE=+eip "$(readlink -f `which python3`)" && \
    setcap CAP_NET_ADMIN=+eip "$(readlink -f `which conntrack`)"

COPY tcp_exporter.py /

ENTRYPOINT ["python3", "/tcp_exporter.py"]
CMD ["9100", "8080"]