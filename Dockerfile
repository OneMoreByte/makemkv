FROM docker.io/debian:stable-slim as build

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

WORKDIR /wordir/installdir
RUN ./configure && make DESTDIR=/workdir/installdir/ install

# I consider this accepting the EULA
RUN echo "exit 0" > makemkv-bin-${VERSION}/src/ask_eula.sh

WORKDIR /workdir/makemkv-bin-${VERSION}
RUN make && make DESTDIR=/workdir/installdir/ install 

FROM docker.io/debian:stable-slim

LABEL org.opencontainers.image.version=${VERSION}


ENV DEBIAN_FRONTEND=noninteractive

COPY --from=build /workdir/installdir/usr/bin/* /usr/bin/
COPY --from=build /workdir/installdir/usr/lib/* /usr/lib/
COPY --from=build /workdir/installdir/usr/share/ /tmp/share
COPY rip.py /app/
RUN cp -rp /tmp/share/* /usr/share/

RUN apt-get update
RUN apt-get install -y \
  python3 \
  python3-dev \
  python3-pip \
  python3-venv \
  python3-cdio \
  libc6-dev \
  libssl-dev \
  libexpat1-dev \
  libavcodec-dev \
  libgl1-mesa-dev \
  qtbase5-dev \
  zlib1g-dev \
  ffmpeg

RUN pip install --no-cache-dir makemkv; \
  groupadd -g 11337 mediasvcs; \
  groupadd -g 11 cdrom-fedora; \
  useradd -u 11337 -g mediasvcs -m mediasvcs; \
  usermod -aG cdrom,cdrom-fedora mediasvcs; \
  USER mediasvcs
WORKDIR /app

CMD ["makemkvcon"]
