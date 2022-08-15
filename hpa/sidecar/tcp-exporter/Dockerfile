FROM python:3.9-alpine

RUN apk add --no-cache \
        conntrack-tools \
        libcap \
        curl && \
    setcap CAP_NET_BIND_SERVICE=+eip "$(readlink -f `which python3`)" && \
    setcap CAP_NET_ADMIN=+eip "$(readlink -f `which conntrack`)"

COPY tcp_exporter.py /

ENTRYPOINT ["python3", "/tcp_exporter.py"]
CMD ["9100", "8080"]