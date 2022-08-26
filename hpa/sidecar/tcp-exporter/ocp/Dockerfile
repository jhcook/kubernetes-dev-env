FROM registry.access.redhat.com/ubi8/python-39

USER root
COPY ./ocp/rockylinux.repo /etc/yum.repos.d/

RUN yum install -y conntrack-tools libcap && \
    yum clean all && \
    setcap CAP_NET_BIND_SERVICE=+eip "$(readlink -f `which python3`)" && \
    setcap CAP_NET_ADMIN=+eip "$(readlink -f `which conntrack`)"

COPY tcp_exporter.py /

ENTRYPOINT ["python3", "/tcp_exporter.py"]
CMD ["9100", "8080"]