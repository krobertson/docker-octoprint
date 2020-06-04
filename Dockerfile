FROM python:slim

# Group ID for serial device access
# Maps to uucp on arch
ARG PGID=987

ENV OCTO_VERSION=1.4.0

RUN set -ex \
  && apt-get update \
  && apt-get install -y --no-install-recommends build-essential wget python3-numpy libatlas-base-dev \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

# Install virtualenv
RUN pip install --no-cache-dir virtualenv

# Install ffmpeg
RUN set -ex \
  && cd /tmp \
  && wget -O ffmpeg.tar.xz https://johnvansickle.com/ffmpeg/releases/ffmpeg-release-amd64-static.tar.xz \
  && mkdir -p /opt/ffmpeg \
  && tar xvf ffmpeg.tar.xz -C /opt/ffmpeg --strip-components=1 \
  && rm -Rf /tmp/*

RUN groupadd -g ${PGID} serial

# Create an octoprint user
RUN useradd -ms /bin/bash octoprint && adduser octoprint dialout && adduser octoprint serial

# Install Octoprint
RUN mkdir -p /opt/octoprint && chown -R octoprint:octoprint /opt/octoprint
USER octoprint

# This fixes issues with the volume command setting wrong permissions
RUN mkdir /home/octoprint/.octoprint

# Install Octoprint
RUN set -ex \
  && cd /opt/octoprint \
  && wget -qO- https://github.com/foosel/OctoPrint/archive/${OCTO_VERSION}.tar.gz | tar xz -C /opt/octoprint --strip-components=1 \
  && virtualenv venv \
  && ./venv/bin/python setup.py install

# Install plugins
#   Autoscroll
#   Autoselect Plugin
#   Bed Visualizer
#   BetterHeaterTimeout
#   Extra Distance Buttons
#   Fan Speed Control
#   FloatingNavbar
#   Fullscreen Plugin
#   LayerDisplay
#   Octolapse
#   Preheat Button
#   Print History Plugin
#   Printer Stats
#   PrintTimeGenius Plugin
#   Simple Emergency Stop
#   Tab Order
#   Webcam Tab
RUN set -ex \
  && cd /opt/octoprint \
  && ./venv/bin/pip install "https://github.com/MoonshineSG/OctoPrint-Autoscroll/archive/master.zip" \
  && ./venv/bin/pip install "https://github.com/OctoPrint/OctoPrint-Autoselect/archive/master.zip" \
  && ./venv/bin/pip install "https://github.com/jneilliii/OctoPrint-BedLevelVisualizer/archive/master.zip" \
  && ./venv/bin/pip install "https://github.com/jneilliii/OctoPrint-FloatingNavbar/archive/master.zip" \
  && ./venv/bin/pip install "https://github.com/BillyBlaze/OctoPrint-FullScreen/archive/master.zip" \
  && ./venv/bin/pip install "https://github.com/aerickson/layerdisplay/archive/py3_compat/master.zip" \
  && ./venv/bin/pip install "https://github.com/marian42/octoprint-preheat/archive/master.zip" \
  && ./venv/bin/pip install "https://github.com/OllisGit/OctoPrint-PrintJobHistory/archive/master.zip" \
  && ./venv/bin/pip install "https://github.com/benjamin-salchow/OctoPrint-Stats/archive/master.zip" \
  && ./venv/bin/pip install "https://github.com/jneilliii/OctoPrint-StickyPad/archive/master.zip" \
  && ./venv/bin/pip install "https://github.com/eyal0/OctoPrint-PrintTimeGenius/archive/master.zip" \
  && ./venv/bin/pip install "https://github.com/BrokenFire/OctoPrint-SimpleEmergencyStop/archive/master.zip" \
  && ./venv/bin/pip install "https://github.com/jneilliii/OctoPrint-TabOrder/archive/master.zip"

EXPOSE 5000
VOLUME /home/octoprint/.octoprint
WORKDIR /opt/octoprint

CMD ["/opt/octoprint/venv/bin/octoprint", "serve"]
