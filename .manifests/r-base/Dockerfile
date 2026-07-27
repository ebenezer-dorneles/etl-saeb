FROM rocker/r2u:26.04

RUN apt-get update && apt-get install -y \
    ca-certificates \
    curl \
    openssl \
    r-cran-arrow \
    r-cran-duckdb \
    r-cran-dbi \
    r-cran-dbplyr \
    r-cran-dplyr \
    r-cran-tidyr \
    r-cran-ggplot2 \
    r-cran-scales \
    r-cran-forcats \
    r-cran-psych \
    r-cran-lme4 \
    r-cran-lmertest \
    r-cran-performance \
    r-cran-broom.mixed \
    r-cran-httr2 \
    r-cran-fs \
    r-cran-here \
    r-cran-glue \
    r-cran-dotenv \
    r-cran-cli \
    r-cran-data.table \
    r-cran-testthat \
    r-cran-zip \
    && rm -rf /var/lib/apt/lists/*

# Adiciona certificado intermediário da RNP
RUN curl -o /usr/local/share/ca-certificates/rnp.crt \
    http://secure.globalsign.com/cacert/rnpicpedugr46ovtlsca2025.crt \
    && update-ca-certificates

ENV SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt
ENV CURL_CA_BUNDLE=/etc/ssl/certs/ca-certificates.crt

WORKDIR /workspace
