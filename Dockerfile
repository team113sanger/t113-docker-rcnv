FROM quay.io/team113sanger/r-base:2.0.1 as builder

USER root

# Locale
ENV LC_ALL C
ENV LC_ALL C.UTF-8
ENV LANG C.UTF-8

ENV DEBIAN_FRONTEND=noninteractive

ENV PATH $OPT/bin:$OPT/python3/bin:$OPT/texlive/2019/bin/x86_64-linux:$PATH

ENV VER_SEQUENZA_UTILS="3.0.0"
ENV VER_BWA="0.7.17"
ENV VER_SAMTOOLS="1.10"
ENV VER_HTSLIB="1.10.2"
ENV VER_FACETS="0.5.14"

RUN apt-get install -yq \
  texinfo \
  libcurl4-openssl-dev \
  libbz2-dev \
  liblzma-dev \
  libpcre3-dev \
  zlib1g-dev \
  libxml2-dev \
  libblas-dev \
  python-pip \
  python-dev \
  autoconf \
  gcc \
  make \
  curl \
  libssl-dev \
  libhts-dev \
  libncurses-dev

ADD build/install_R_packages.sh build/
RUN bash build/install_R_packages.sh

ADD build/opt-build.sh build/
RUN bash build/opt-build.sh $OPT

FROM quay.io/team113sanger/r-base:2.0.1

LABEL maintainer="vo1@sanger.ac.uk" \
      version="1.0.0" \
      description="R-cnv container"

MAINTAINER  Victoria Offord <vo1@sanger.ac.uk>

ENV DEBIAN_FRONTEND=noninteractive

USER root
  
RUN apt-get -yq update
RUN apt-get install -yq --no-install-recommends \
  curl \
  libxml2 \
  libblas3 \
  python \
  python-distutils-extra \
  zlib1g \
  libcurl4 \
  libssl1.1 \
  libbz2-1.0 \  
  liblzma5 \
  libhts2 \
  libncurses5

ENV OPT /opt/wsi-t113
ENV PATH $OPT/bin:$OPT/python3/bin:$OPT/texlive/2019/bin/x86_64-linux:$PATH
ENV LD_LIBRARY_PATH $OPT/lib:$OPT/htslib/lib
ENV PYTHONPATH $OPT/python3:$OPT/python3/lib/python3.6/site-packages

ENV LC_ALL C
ENV LC_ALL C.UTF-8
ENV LANG C.UTF-8
ENV DISPLAY=:0

RUN mkdir -p $OPT
COPY --from=builder $OPT $OPT

RUN find / -name *tclConfig* > /tmp/tcl.all

USER ubuntu
WORKDIR /home/ubuntu

CMD ["/bin/bash"]
