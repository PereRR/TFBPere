FROM kalilinux/kali-rolling

RUN apt-get update && apt-get install -y \
    nmap \
    curl \
    netcat-openbsd \
    hydra \
    sqlmap \
    iputils-ping \
    dnsutils \
    tcpdump \
    && apt-get clean

WORKDIR /attacks
CMD ["/bin/bash"]