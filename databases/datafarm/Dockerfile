FROM python:3.10

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONFAULTHANDLER=1
ENV PYTHONUNBUFFERED=1
ENV PYTHONHASHSEED=random
ENV PIP_NO_CACHE_DIR=off
ENV PIP_DISABLE_PIP_VERSION_CHECK=on
ENV PIP_DEFAULT_TIMEOUT=100

RUN apt-get update && \
    apt-get install -y postgresql && \
    apt-get install -y libpq-dev && \
    apt-get clean

WORKDIR /app
COPY req.txt /app
RUN pip3 install --no-cache-dir -r req.txt
COPY datafarm_init.sql /docker-entrypoint-initdb.d/datafarm_init.sql
COPY . /app

CMD ["python", "main.py"]