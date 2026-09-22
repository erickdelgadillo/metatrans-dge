FROM rocker/r-ver:4.4.1

RUN apt-get update && apt-get install -y --no-install-recommends \
    libcurl4-openssl-dev \
    libssl-dev \
    libxml2-dev \
    pkg-config \
    zlib1g-dev \
    && rm -rf /var/lib/apt/lists/*

RUN R -q -e "install.packages(c('BiocManager','ggplot2','R.utils'), repos='https://cloud.r-project.org')"

RUN R -q -e "install.packages('data.table', repos='https://cloud.r-project.org', type='source')"

RUN R -q -e "BiocManager::install('edgeR', ask=FALSE, update=FALSE)"

WORKDIR /workspace
