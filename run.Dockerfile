FROM gcr.io/buildpacks/gcp/run:v1
USER root
RUN apt-get update && apt-get install -y --no-install-recommends \
  libpq-dev zlib1g-dev liblzma-dev libxml2-dev libxslt1-dev patch && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/*
USER cnb
