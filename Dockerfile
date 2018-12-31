FROM python:2-slim

# Group ID for serial device access
# Maps to uucp on arch
ARG PGID=14

LABEL maintainer="cmotch@gmail.com"

ENV CURA_VERSION=15.04.6
ENV OCTO_VERSION=1.3.10

EXPOSE 5000

WORKDIR /opt/octoprint

RUN apt-get update && apt-get install -y --no-install-recommends \
  build-essential \
  wget \
  && rm -rf /var/lib/apt/lists/*

# Install virtualenv
RUN pip install --no-cache-dir virtualenv

# Install ffmpeg
RUN cd /tmp \
  && wget -O ffmpeg.tar.xz https://johnvansickle.com/ffmpeg/releases/ffmpeg-release-32bit-static.tar.xz \
  && mkdir -p /opt/ffmpeg \
  && tar xvf ffmpeg.tar.xz -C /opt/ffmpeg --strip-components=1 \
  && rm -Rf /tmp/*

# Install Cura
RUN cd /tmp \
  && wget https://github.com/Ultimaker/CuraEngine/archive/${CURA_VERSION}.tar.gz \
  && tar -zxf ${CURA_VERSION}.tar.gz \
  && cd CuraEngine-${CURA_VERSION} \
  && mkdir build \
  && make \
  && mv -f ./build /opt/cura/ \
  && rm -Rf /tmp/*

RUN groupadd -g ${PGID} serial
# Create an octoprint user
RUN useradd -ms /bin/bash octoprint && adduser octoprint dialout && adduser octoprint serial

# Install Octoprint
RUN mkdir -p /opt/octoprint
RUN chown -R octoprint:octoprint /opt/octoprint
USER octoprint
#This fixes issues with the volume command setting wrong permissions
RUN mkdir /home/octoprint/.octoprint

RUN wget -qO- https://github.com/foosel/OctoPrint/archive/${OCTO_VERSION}.tar.gz | tar xz -C /opt/octoprint --strip-components=1 \
  && virtualenv venv \
  && ./venv/bin/python setup.py install

VOLUME /home/octoprint/.octoprint

CMD ["/opt/octoprint/venv/bin/octoprint", "serve"]
