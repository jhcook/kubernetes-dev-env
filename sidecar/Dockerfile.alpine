FROM python:3.9-alpine

RUN apk add conntrack-tools
COPY tcp_exporter.py /

ENTRYPOINT ["python3", "/tcp_exporter.py"]
CMD ["9100", "8080"]