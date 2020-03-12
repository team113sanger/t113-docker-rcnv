#! /bin/bash

set -xe

if [[ -z "${TMPDIR}" ]]; then
  TMPDIR=/tmp
fi

set -u

if [ "$#" -lt "1" ] ; then
  echo "Please provide an installation path such as /opt/ICGC"
  exit 1
fi

# get path to this script
SCRIPT_PATH=`dirname $0`;
SCRIPT_PATH=`(cd $SCRIPT_PATH && pwd)`

# get the location to install to
INST_PATH=$1
mkdir -p $1
INST_PATH=`(cd $1 && pwd)`
echo $INST_PATH

# get current directory
INIT_DIR=`pwd`

CPU=`grep -c ^processor /proc/cpuinfo`
if [ $? -eq 0 ]; then
  if [ "$CPU" -gt "6" ]; then
    CPU=6
  fi
else
  CPU=1
fi
echo "Max compilation CPUs set to $CPU"

SETUP_DIR=$INIT_DIR/install_tmp
mkdir -p $SETUP_DIR/distro # don't delete the actual distro directory until the very end
mkdir -p $INST_PATH/bin
cd $SETUP_DIR

# make sure tools installed can see the install loc of libraries
set +u
export LD_LIBRARY_PATH=`echo $INST_PATH/lib:$LD_LIBRARY_PATH | perl -pe 's/:\$//;'`
export LIBRARY_PATH=`echo $INST_PATH/lib:$LIBRARY_PATH | perl -pe 's/:\$//;'`
export C_INCLUDE_PATH=`echo $INST_PATH/include:$C_INCLUDE_PATH | perl -pe 's/:\$//;'`
export PATH=`echo $INST_PATH/bin:$PATH | perl -pe 's/:\$//;'`
export MANPATH=`echo $INST_PATH/man:$INST_PATH/share/man:$MANPATH | perl -pe 's/:\$//;'`
export PERL5LIB=`echo $INST_PATH/lib/perl5:$PERL5LIB | perl -pe 's/:\$//;'`
set -u

# bwa
if [ ! -e $SETUP_DIR/bwa.success ]; then
  mkdir $INST_PATH/bwa
  curl -sSL --retry 10 -o dist.tar.bz2 https://github.com/lh3/bwa/releases/download/v${VER_BWA}/bwa-${VER_BWA}.tar.bz2
  mkdir dist
  tar --strip-components 1 -C $INST_PATH/bwa -xvf dist.tar.bz2
  cd $INST_PATH/bwa
  make
  ln -s $INST_PATH/bwa/bwa $INST_PATH/bin/bwa
  cd $SETUP_DIR
  rm -r dist*
  touch $SETUP_DIR/bwa.success
fi

# htslib
if [ ! -e $SETUP_DIR/htslib.success ]; then
  curl -sSL --retry 10 -o dist.tar.bz2 https://github.com/samtools/htslib/releases/download/${VER_HTSLIB}/htslib-${VER_HTSLIB}.tar.bz2
  mkdir dist
  mkdir -p $INST_PATH/htslib
  tar --strip-components 1 -C dist -xjf dist.tar.bz2
  cd dist
  autoheader
  autoconf
  ./configure --prefix=$INST_PATH/htslib
  make
  make install
  cd $SETUP_DIR
  rm -r dist*
  ln -s $INST_PATH/htslib/bin/* $INST_PATH/bin/
  touch $SETUP_DIR/htslib.success
fi

# samtools
if [ ! -e $SETUP_DIR/samtools.success ]; then
  curl -sSL --retry 10 -o dist.tar.bz2 https://github.com/samtools/samtools/releases/download/${VER_SAMTOOLS}/samtools-${VER_SAMTOOLS}.tar.bz2
  mkdir dist
  mkdir -p $INST_PATH/samtools
  tar --strip-components 1 -C dist -xjf dist.tar.bz2
  cd dist
  autoheader
  autoconf
  ./configure --prefix=$INST_PATH/samtools --with-htslib=$INST_PATH/htslib
  make
  make install
  cd $SETUP_DIR
  rm -r dist*
  ln -s $INST_PATH/samtools/bin/* $INST_PATH/bin/
  touch $SETUP_DIR/samtools.success
fi
 
# facets scripts
if [ ! -e $SETUP_DIR/facets.success ]; then
  curl -sSL --retry 10 -o dist.tar.gz https://github.com/mskcc/facets/archive/v${VER_FACETS}.tar.gz
  mkdir dist
  tar --strip-components 1 -C dist -xf dist.tar.gz
  cd dist
  g++ -std=c++11 -I$INST_PATH/htslib/include inst/extcode/snp-pileup.cpp -L$INST_PATH/htslib/lib -lhts -Wl,-rpath=$INST_PATH/lib -o inst/extcode/snp-pileup
  mkdir $INST_PATH/facets
  cp -r $SETUP_DIR/dist/inst/extcode/* $INST_PATH/facets/
  cd $SETUP_DIR
  rm -r dist*
  ln -s $INST_PATH/facets/snp-pileup $INST_PATH/bin/snp-pileup
  touch $SETUP_DIR/facets.success
fi

# sequenza-utils
if [ ! -e $SETUP_DIR/sequenza-utils.success ]; then
  pip -v install --install-option="--install-scripts=${INST_PATH}/bin" --target=$INST_PATH/python3 sequenza-utils==${VER_SEQUENZA_UTILS}
  touch $SETUP_DIR/sequenza-utils.success
fi
