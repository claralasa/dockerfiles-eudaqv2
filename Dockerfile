# 
# eudaq2 Dockerfile
# https://github.com/claralasa/dockerfiles-eudaqv2
#
# Creates the environment to run the EUDAQ2
# framework 
#

FROM phusion/baseimage:18.04-1.0.0
LABEL author="clara.lasaosa.garcia@cern.ch" \ 
    version="1.0-87d561f1" \ 
    description="Docker image for EUDAQ2 framework (claralasa/eudaq commit)"

# Use baseimage-docker's init system.
CMD ["/sbin/my_init"]

# Place at the directory
WORKDIR /eudaq2

# Install all dependencies
RUN apt-get update \ 
  && install_clean --no-install-recommends software-properties-common \ 
  && install_clean --no-install-recommends \ 
   build-essential \
   python3-dev \ 
   python3-numpy \
   openssh-server \ 
   qt5-default \ 
   wget \
   git \ 
   python3-click \ 
   python3-pip \ 
   python3-matplotlib \
   python3-tk \
   python3-setuptools \
   python3-wheel \
   cmake \ 
   libusb-dev \ 
   libusb-1.0 \ 
   pkgconf \ 
   vim \ 
   g++ \
   gcc \
   gfortran \
   binutils \
   libxpm4 \ 
   libxft2 \ 
   libtiff5 \ 
   libtbb-dev \ 
   sudo \ 
  && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*


# ROOT 
RUN mkdir /rootfr \ 
  && wget https://root.cern/download/root_v6.14.06.Linux-ubuntu18-x86_64-gcc7.3.tar.gz -O /rootfr/root.v6.14.06.tar.gz \ 
  && tar -xf /rootfr/root.v6.14.06.tar.gz -C /rootfr \ 
  && rm -rf /rootfr/root.v6.14.06.tar.gz

ENV ROOTSYS /rootfr/root
# BE aware of the ROOT libraries
ENV LD_LIBRARY_PATH /rootfr/root/lib
ENV PYTHONPATH /rootfr/root/lib

# download the code, checkout the release and compile
# This will be used only for production!
# For development case, the /eudaq2/eudaq2 directory
# is "bind" from the host computer 
RUN git clone -b v2.4.6 --single-branch https://github.com/claralasa/eudaq.git \ 
  && cd eudaq2 \ 
  && mkdir -p /eudaq2/eudaq2/extern/ZestSC1 \ 
  && mkdir -p /eudaq2/eudaq2/extern/tlufirmware

# COPY The needed files for the TLU and pxar (CMS phase one pixel)
COPY ZestSC1.tar.gz /eudaq2/eudaq2/extern/ZestSC1.tar.gz
COPY tlufirmware.tar.gz /eudaq2/eudaq2/extern/tlufirmware.tar.gz
COPY libftd2xx-x86_64-1.4.22.tgz /eudaq2/eudaq2/extern/libftd2xx-x86_64-1.4.22.tgz

# Untar files and continue with the compilation
RUN cd /eudaq2/eudaq2 \ 
  && tar xzf extern/ZestSC1.tar.gz -C extern && rm extern/ZestSC1.tar.gz \
  && tar xzf extern/tlufirmware.tar.gz -C extern && rm extern/tlufirmware.tar.gz \
  # The pxar library for CMS phase I pixel
  && tar xzf extern/libftd2xx-x86_64-1.4.22.tgz -C extern \
  && mv extern/release extern/libftd2xx-x86_64-1.4.22 && rm extern/libftd2xx-x86_64-1.4.22.tgz \ 
  && cp extern/libftd2xx-x86_64-1.4.22/build/libftd2xx.* /usr/local/lib/ \
  && chmod 0755 /usr/local/lib/libftd2xx.so.1.4.22 \
  && ln -sf /usr/local/lib/libftd2xx.so.1.4.22 /usr/local/lib/libftd2xx.so \
  && cp extern/libftd2xx-x86_64-1.4.22/*.h /usr/local/include/ \ 
  && git clone https://github.com/psi46/pixel-dtb-firmware extern/pixel-dtb-firmare \ 
  && git clone https://github.com/psi46/pxar.git extern/pxar && cd extern/pxar && git checkout production \ 
  && mkdir -p build && cd build && cmake .. && make -j4 install \ 
  && cd /eudaq2/eudaq2 \ 
  # End pxar library 
  && mkdir -p build \ 
  && cd build \ 
  && cmake .. -DBUILD_tlu=ON -DBUILD_python=ON -DBUILD_ni=ON \ 
  && make -j4 install
# STOP ONLY FOR PRODUCTION

ENV PXARPATH="/eudaq2/eudaq2/extern/pxar"
ENV LD_LIBRARY_PATH="${LD_LIBRARY_PATH}:${PXARPATH}/lib:/eudaq2/eudaq2/lib"
ENV PYTHONPATH="${PYTHONPATH}:/eudaq2/eudaq2/lib:/eudaq2/eudaq2/python"
ENV PATH="${PATH}:/rootfr/root/bin:/eudaq2/eudaq2/bin"

COPY initialize_service.sh /usr/bin/initialize_service.sh

# Create a couple of directories needed
RUN mkdir -p /logs && mkdir -p /data
# Add eudaquser, allow to call sudo without password
RUN useradd -md /home/eudaquser -ms /bin/bash -G sudo eudaquser \ 
  && echo "eudaquser:docker" | chpasswd \
  && echo "eudaquser ALL=(ALL) NOPASSWD: ALL\n" >> /etc/sudoers 
# Give previously created folders ownership to the user
RUN chown -R eudaquser:eudaquser /logs && chown -R eudaquser:eudaquser /data \
  && chown -R eudaquser:eudaquser /eudaq2
USER eudaquser

