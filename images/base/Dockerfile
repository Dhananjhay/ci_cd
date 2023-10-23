ARG BASE_CONTAINER=ubuntu:22.04

FROM --platform=linux/amd64 ${BASE_CONTAINER}

LABEL maintainer="CANFAR Project <support@canfar.net>"

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ENV SHELL=/bin/bash

USER root

WORKDIR /tmp

COPY apt-install.sh conda-env-update.sh /usr/local/bin/

# install bunch of packages
COPY apt.list .
RUN apt-install.sh apt.list

# nsswitch for correct sss lookup
ADD nsswitch.conf /etc/

# install micromamba and initialize
ARG PYTHON_VERSION=3.10

ENV CONDA_DIR=/opt/conda
ENV PATH="${CONDA_DIR}/bin:${PATH}"

COPY condarc "${CONDA_DIR}/.condarc"

RUN set -x \
    && curl -Ls https://micromamba.snakepit.net/api/micromamba/linux-64/latest | tar -xvj bin/micromamba \
    && ./bin/micromamba install \
        --root-prefix="${CONDA_DIR}" \
        --prefix="${CONDA_DIR}" \
        --yes \
        python=${PYTHON_VERSION} mamba

# conda profile scripts by default
RUN ln -s ${CONDA_DIR}/etc/profile.d/conda.sh /etc/profile.d/conda.sh

COPY channels.list .
RUN sed -i -e '/conda-forge/d' channels.list \
    && [ $(wc -l channels.list | awk '{print $1}') != 0 ] \
    && cat channels.list | uniq | awk 'NF' \
       | xargs -n1 conda config --system --prepend channels \
    || echo "no new channels to add"

# install minimimal base conda environment
COPY env.yml .
RUN conda-env-update.sh env.yml

COPY pinned .
RUN touch ${CONDA_DIR}/conda-meta/pinned \
    && cat pinned ${CONDA_DIR}/conda-meta/pinned | sort | uniq > pinned.new \
    && cp pinned.new ${CONDA_DIR}/conda-meta/pinned

# save packages files into container
COPY Dockerfile .
RUN mkdir -p /build-info \
    && for f in env.yml apt.list Dockerfile; do \
       [[ -e ${f} ]] && cp ${f} /build-info/ ; done \
    && rm -rf /tmp/* ~/.cache/*
ENTRYPOINT ["tini", "-g", "--"]
RUN add-apt-repository ppa:cartavis-team/carta
RUN apt-install.sh fits2idia
