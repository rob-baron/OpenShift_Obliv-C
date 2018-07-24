FROM rhel  

WORKDIR /app

# To get this to install, on build system install ocamalbrew like this:
#     
#    git clone https://github.com/hcarty/ocamlbrew.git
#    cd ocamlbrew
#    ./ocambrew -x    
#
# This should install ocaml, findlib, opam and oasis on the build system
# once these are available to the main system, we can build the container
# 

# clone obliv-c & ocaml
#  1) the dependncies
ENV OPAMROOT /app/.opam

RUN yum install -y make bzip2 git glibc-devel.i686 libgcrypt libgcrypt-devel perl perl-ExtUtils-MakeMaker perl-Data-Dumper \
                   glibc-devel.x86_64 redhat-rpm-config m4 patch unzip hg wget gcc-c++ curl transfig \
                   texi2html texinfo help2man perl-Thread-Queue gettext \
 && mkdir /app/lib \
 && mkdir /app/include 


# now to install the ocaml toolset
COPY ./ocamlbrew /app/ocamlbrew

RUN cd /app \
  #&& git clone https://github.com/hcarty/ocamlbrew.git \
  && cd /app/ocamlbrew \
  && mkdir /app/ocaml \
  && ./ocamlbrew -v 4.05.0 -b /app/ocaml -x \
  #&& ./ocamlbrew-install \
  && source /app/ocaml/ocaml-4.05.0/etc/ocamlbrew.bashrc \
  && ulimit -s 16384 \
  && opam init -y \
  && eval `opam config env` \
  && opam update \
  && opam switch 4.06.1 \
  && opam install -y ocamlfind \
  && opam install -y depext \
  && opam install -y num \
  && opam install -y batteries \
  && opam install -y camlp4 \
# The above works for ocaml 4.06.1
# For ocaml 4.02 camlp4 
# cannot do this here!  Here is the error:
#
#    [ERROR] camlp4.4.02+1 is not available because your system doesn't comply with
#            !preinstalled & ocaml-version >= "4.02" & ocaml-version < "4.03".
# 
# not sure why, but installing camlp4 from source (below). 
  && cd /app 

#RUN cd /app \
# && git clone https://github.com/ocaml/camlp4.git \
# && cd /app/camlp4 \
# && git checkout "4.02+1" \
# && git fetch \
# && ./configure \
# && make \
# && make install \
# && cd /app

ENV PATH=/app/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/share
ENV LD_LIBRARY_PATH /app/lib
COPY /usr/bin /app/bin
COPY /usr/share	/usr/local/share
COPY /usr/local/lib /app/lib
COPY /usr/local/include /app/include

#This shouldn't be needed thought cannot download right now.
COPY libtool-2.4.6.tar.gz /app


#RUN cd /app \
# #
# # Update autoconf
# #
# && wget https://ftp.gnu.org/gnu/autoconf/autoconf-2.69.tar.gz \
# && tar -zxvf autoconf-2.69.tar.gz \
# && cd autoconf-2.69 \
# && ./configure --prefix=/usr \
# && make all \
# && make install \
# && cd .. \
# #
# # Using automake-1.15.tar.gz as automake-1.16.tar.gz does not build easily.
# #   note: Error
# #     "help2man: can't get `--help' info from automake-1.15"
# #   resolve by:
# #     "yum install perl-Thread-Queue"
# #   Added above.
# #
# && wget https://ftp.gnu.org/gnu/automake/automake-1.15.tar.gz \
# && tar -zxvf automake-1.15.tar.gz \
# && cd automake-1.15 \
# && ./configure --prefix=/usr \
# && make all \
# && make install \
# && cd .. \
# #
# # Update libtoolize:
# #
# #&& wget http://gnu.mirrors.hoobly.com/libtool/libtool-2.4.6.tar.gz \
# && tar -zxvf libtool-2.4.6.tar.gz \
# && cd libtool-2.4.6 \
# && ./configure --prefix=/usr \
# && make all \
# && make install \
# && cd .. \
# #
# # Do some clean up
# #
# && cd /app \
# && rm -rf autoconf-2.69 \
# && rm -rf automake-1.15 \
# && rm -rf libtool-2.4.6 \
# && rm -f autoconf-2.69.tar.gz \
# && rm -f automake-1.15.tar.gz \
# && rm -f libtool-2.4.6.tar.gz \
# #
# # libpgp-error
# #
# #  This error occurs as gettext was not being installed (added above)
# #    Can't exec "autopoint": No such file or directory at /usr/share/autoconf/Autom4te/FileUtils.pm line 345.
# #
# && git clone https://github.com/gpg/libgpg-error.git \
# && cd libgpg-error \
# && aclocal \
# && autoconf \
# && autoheader \
# && automake \
# && ./configure --prefix=/app \
# # This is apparently one of many quirks of the auto make system 
# && cd doc \
# && make stamp-vti \
# && cd .. \
# && make \
# && make install \
# && cd /app \
# #
# # libgcrypt
# #
# && git clone https://github.com/gpg/libgcrypt.git \
# && cd libgcrypt \
# && aclocal \
# && autoconf \
# && autoheader \
# && automake \
# && ./configure --prefix=/app CFLAGS=' -I/app/include -O2 -L/app/lib ' --enable-maintainer-mode --with-capabilities \
# && make CFLAGS=' -I/app/include -O2 -L/app/lib ' \
# && make install \
# #
# && cd /app

# -- install obliv-c
#   Note: obliv-c requires C99 (the -std=c99 flag
#   
#   Due to the following errors:
#
#       src/ext/oblivc/obliv_bits.c:233:35: error: dereferencing pointer to incomplete type
#       for(iter=list;iter!=NULL && iter->ai_family!=AF_INET;iter=iter->ai_next);
#                                   ^
#       src/ext/oblivc/obliv_bits.c:233:65: error: dereferencing pointer to incomplete type
#       for(iter=list;iter!=NULL && iter->ai_family!=AF_INET;iter=iter->ai_next);
#
#   also the -D_POSIX_C_SOURCE=200112L -D_BSD_SOURCE
#
# need to update libgcrypt.  
#
#   the libgcrypt that is shipped with Rhel7 and Fedora have had the elliptical curve cipher
#   and functions stripped from it to not violate patents.  Obliv-C uses the underlying
#   elliptical curve functions so we need to build libgcrypt from source.
#
#   *** here be possible dragons.  libgcrypt may use optimizations for processors to speed up
#       cryptographic processing.
# 
#   1) but as libgcrypt and libgpg-error are built with more recent autoconf/automake tools:
#      need to update autoconf and automake
#
#          wget https://ftp.gnu.org/gnu/autoconf/autoconf-2.69.tar.gz
#          tar -zxvf autoconf-2.69.tar.gz
#
#      Using automake-1.15.tar.gz as automake-1.16.tar.gz does not build easily.
#
#          wget https://ftp.gnu.org/gnu/automake/automake-1.15.tar.gz
#          tar -zxvf automake-1.15.tar.gz
#
#      Also update libtoolize:
#      
#          wget http://gnu.mirrors.hoobly.com/libtool/libtool-2.4.6.tar.gz
#          tar -zxvf libtool-2.4.6.tar.gz
#          ./configure
#
#   2) Build the libgpg-error library (this also requires: 'yum install -y texi2html texinfo'):
#
#          git clone https://github.com/gpg/libgpg-error.git
#          cd libgpg-error 
#          autoconf
#          autoheader
#          automake
#          ./configure
# cd doc
# make stamp-vti
# cd ..
#          make
#          make check 
#          make install
#
#   3) Build the libgcrypt library
# 
#          git clone https://github.com/gpg/libgcrypt.git
#          autoreconf --force --install
#          autoconf
#          automake
#          ./configure
#          make

# Need to do the above for a better solution but for now copy libgcrypt.so over - later build in the container

RUN cd /app \
 && source /app/ocaml/ocaml-4.05.0/etc/ocamlbrew.bashrc \
 && opam switch 4.06.1 \
 && eval `opam config env` \
 && git clone https://github.com/samee/obliv-c.git \
 && cd /app/obliv-c \
 && ./configure CFLAGS=' -I/app/include -O2 -std=c99 -D_POSIX_C_SOURCE=200112L -D_BSD_SOURCE ' \
 && make CFLAGS=' -I/app/include -O2 -std=c99 -D_POSIX_C_SOURCE=200112L -D_BSD_SOURCE ' \
 && cd /app


RUN chmod -R 777 /app
RUN chmod -R 777 /usr

USER 1001

