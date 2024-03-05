FROM debian:stable-slim as build

ENV VERSION=1.17.6
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update
RUN apt-get install -y \
  build-essential \
  pkg-config \
  libc6-dev \
  libssl-dev \
  libexpat1-dev \
  libavcodec-dev \
  libgl1-mesa-dev \
  qtbase5-dev \
  zlib1g-dev \
  ffmpeg

ADD "https://www.makemkv.com/download/makemkv-bin-${VERSION}.tar.gz" /workdir/
ADD "https://www.makemkv.com/download/makemkv-oss-${VERSION}.tar.gz" /workdir/
WORKDIR /workdir

RUN tar zxf makemkv-bin-${VERSION}.tar.gz; \
  tar zxf makemkv-oss-${VERSION}.tar.gz; \
  mkdir -p /workdir/installdir

WORKDIR /workdir/makemkv-oss-${VERSION}
RUN ./configure && make DESTDIR=/workdir/installdir/ install


WORKDIR /workdir/makemkv-bin-${VERSION}
# I consider this accepting the EULA
RUN echo "exit 0" > src/ask_eula.sh
RUN make && make DESTDIR=/workdir/installdir/ install 

FROM debian:stable-slim

LABEL org.opencontainers.image.version=${VERSION}
ENV DEBIAN_FRONTEND=noninteractive

COPY --from=build /workdir/installdir/usr/bin/* /usr/bin/
COPY --from=build /workdir/installdir/usr/lib/* /usr/lib/
COPY --from=build /workdir/installdir/usr/share/* /tmp/share

RUN apt-get update
RUN apt-get install -y \
  libc6-dev \
  libssl-dev \
  libexpat1-dev \
  libavcodec-dev \
  libgl1-mesa-dev \
  qtbase5-dev \
  zlib1g-dev \
  ffmpeg


RUN groupadd -g 11337 mediasvcs; \
  groupadd -g 11 cdrom-fedora; \
  useradd -u 11337 -g mediasvcs -m mediasvcs; \
  usermod -aG cdrom,cdrom-fedora mediasvcs; 

USER mediasvcs

CMD ["makemkvcon"]
