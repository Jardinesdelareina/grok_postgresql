FROM postgres:latest

RUN apt-get update \
    && apt-get install -y git postgresql-server-dev-all libcurl4-openssl-dev make g++ \
    && apt-get install -y make gcc \
    && git clone https://github.com/pramsey/pgsql-http.git \
    && cd pgsql-http \
    && make && make install \
    && cd .. && rm -rf pgsql-http \
    && apt-get remove --purge -y make gcc postgresql-server-dev-all git \
    && apt-get autoremove -y \
    && apt-get clean