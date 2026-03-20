FROM ubuntu:22.04

WORKDIR /app

RUN apt update && \
    apt install -y \
    bash \
    procps \
    net-tools \
    iproute2 \
    sysstat \
    curl \
    netcat-openbsd && \
    apt clean

COPY core/ ./core/
COPY exporter/ ./exporter/

RUN useradd -m myapp

RUN chmod -R 777 /app && chmod +x ./core/*.sh

USER myapp

EXPOSE 9100

CMD ["bash", "exporter/metrics_server.sh"]
