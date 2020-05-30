# Copyright 2020 John McKenzie
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# archlinux 20200505
ARG ARCH_DIGEST=sha256:cb94be326bcdddf5244016021232dd75d27afe763e2901fadb0d7f09e15383d8

#
# Build image
#
FROM archlinux@${ARCH_DIGEST} as builder

USER root
RUN pacman -Syu --noconfirm --noprogressbar && \
    pacman -Sy --noconfirm --noprogressbar \
    base-devel \
    coreutils \
    git \
    go \
    gsl \
    libpng12 \
    lzo \
    openmpi \
    qt5-base \
    qt5-multimedia \
    qt5-tools

RUN useradd -m builder
USER builder
WORKDIR /home/builder

RUN git clone https://aur.archlinux.org/mandelbulber2.git src && \
    cd src && \
    MAKEFLAGS="-j$(nproc)" makepkg

#
# Final image
#
FROM archlinux@${ARCH_DIGEST}

ENV MANDELBULBER=/usr/sbin/mandelbulber2 \
    USER_UID=1001 \
    USER_NAME=mandelbulber \
    USER_HOME=/home/mandelbulber

USER root
RUN pacman -Syu --noconfirm --noprogressbar && \
    pacman -Sy --noconfirm --noprogressbar \
    gsl \
    libpng12 \
    lzo \
    openmpi \
    qt5-base \
    qt5-multimedia \
    qt5-tools

COPY --from=builder /home/builder/src/*.pkg.tar.xz /tmp/
RUN pacman -U /tmp/*.pkg.tar.xz  --noconfirm --noprogressbar && \
    rm -f /tmp/*.pkg.tar.xz

RUN useradd -m ${USER_NAME}

COPY entrypoint.sh /usr/local/bin/entrypoint
RUN chown "${USER_UID}:0" "${USER_HOME}" && \
    chmod ug+rwx "${USER_HOME}"

USER ${USER_UID}
WORKDIR ${USER_HOME}
ENTRYPOINT ["/usr/local/bin/entrypoint"]
CMD ["--version"]
