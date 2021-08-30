FROM arm64v8/ubuntu:18.04 as builder
WORKDIR /root

ARG QEMU_FILE="qemu-6.1.0"
ARG QEMU_SHA1="aae5ef7761b5f2fc45f0076219f1249da86f94b5"
ARG TIME_ZONE="Asia/Shanghai"

ENV QEMU_URL="https://download.qemu.org/${QEMU_FILE}.tar.xz"

RUN rm -fv /etc/localtime && \
    ln -s /usr/share/zoneinfo/${TIME_ZONE} /etc/localtime && \
    apt update -yq && \
    apt install -yq build-essential curl ninja-build pbzip2 pigz zlib1g-dev libncurses-dev flex bison libssl-dev libglib2.0-dev

# download & unpack qemu executables
RUN curl -o "${QEMU_FILE}.tar.xz" -L ${QEMU_URL} && \
    echo "${QEMU_SHA1} *${QEMU_FILE}.tar.xz" | sha1sum -c - && \
    tar xf "${QEMU_FILE}.tar.xz" && cd ${QEMU_FILE} && rm -f "${QEMU_FILE}.tar.xz" && \
    \
    ./configure \
            --prefix=/opt/qemu-user-static \
            --sysconfdir=/opt/qemu-user-static/etc \
            --localstatedir=/opt/qemu-user-static/var \
            --libexecdir=/opt/qemu-user-static/libexec \
            --enable-linux-user \
            --disable-debug-info \
            --disable-bsd-user \
            --disable-werror \
            --disable-system \
            --disable-tools \
            --disable-docs \
            --disable-gtk \
            --disable-gnutls \
            --disable-nettle \
            --disable-gcrypt \
            --disable-glusterfs \
            --disable-libnfs \
            --disable-libiscsi \
            --disable-vnc \
            --disable-kvm \
            --disable-libssh \
            --disable-libxml2 \
            --disable-vde \
            --disable-sdl \
            --disable-opengl \
            --disable-xen \
            --disable-fdt \
            --disable-vhost-net \
            --disable-vhost-crypto \
            --disable-vhost-user \
            --disable-vhost-vsock \
            --disable-vhost-scsi \
            --disable-tpm \
            --disable-qom-cast-debug \
            --disable-capstone \
            --disable-zstd \
            --disable-linux-io-uring \
            --static \
    && \
    make -j 8 && make install && cp scripts/qemu-binfmt-conf.sh /opt/qemu-user-static/ && \
    chmod +x /opt/qemu-user-static/qemu-binfmt-conf.sh && \
    cd /opt && tar -I pbzip2 -cf qemu-user-static_ubuntu18.04_v6.10.tar.bz2 qemu-user-static/

FROM arm64v8/ubuntu:18.04

COPY --from=builder /opt/qemu-user-static/ /opt/qemu-user-static/
COPY --from=builder /opt/qemu-user-static_ubuntu18.04_v6.10.tar.bz2 /opt/qemu-user-static_ubuntu18.04_v6.10.tar.bz2

ADD ./register.sh /register.sh
RUN chmod 755 /register.sh /opt/qemu-user-static/qemu-binfmt-conf.sh -v

ENTRYPOINT ["/register.sh"]
CMD ["--reset", "-p", "yes"]
