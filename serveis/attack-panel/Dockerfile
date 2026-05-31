FROM python:3.12-slim

RUN apt-get update && apt-get install -y \
    bash \
    curl \
    nmap \
    && apt-get clean

RUN pip install flask

WORKDIR /app

COPY app.py /app/app.py

CMD ["python", "app.py"]