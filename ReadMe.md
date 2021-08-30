# multiarch-on-aarch64

**multiarch-on-aarch64** is to enable an execution of different multi-architecture containers / programs by QEMU [1] and binfmt_misc [2]. It is very similar to multiarch/qemu-user-static [3]. The main difference is that *multiarch-on-aarch64* works on aarch64 hosts while *multiarch/qemu-user-static* works on x86_64 hosts.

Here are examples with Docker [4].


## Getting started

Check host arch:
```
$ uname -m
aarch64
```

Currently, amd64 docker containers could not run
```
$ docker run -it --rm amd64/centos:8 uname -m
WARNING: The requested image's platform (linux/amd64) does not match the detected host platform (linux/arm64/v8) and no specific platform was requested
standard_init_linux.go:228: exec user process caused: exec format error
```

Other executable binaries such as busybox-s390x also could not run
```
$ curl -LO https://busybox.net/downloads/binaries/1.31.0-defconfig-multiarch-musl/busybox-s390x
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100 1349k  100 1349k    0     0   949k      0  0:00:01  0:00:01 --:--:--  949k

$ chmod +x busybox-s390x && ./busybox-s390x uname -m
-bash: ./busybox-s390x: cannot execute binary file: Exec format error
```

Now we build & run the multiarch-on-aarch64 container once 
```
$ docker build -t multiarch-on-aarch64:latest -f Dockerfile .
(... output ...)

$ docker run -it --rm --privileged multiarch-on-aarch64:latest
Setting /opt/qemu-user-static/bin/qemu-i386 as binfmt interpreter for i386
Setting /opt/qemu-user-static/bin/qemu-i386 as binfmt interpreter for i486
Setting /opt/qemu-user-static/bin/qemu-alpha as binfmt interpreter for alpha
Setting /opt/qemu-user-static/bin/qemu-armeb as binfmt interpreter for armeb
Setting /opt/qemu-user-static/bin/qemu-sparc as binfmt interpreter for sparc
Setting /opt/qemu-user-static/bin/qemu-sparc32plus as binfmt interpreter for sparc32plus
Setting /opt/qemu-user-static/bin/qemu-sparc64 as binfmt interpreter for sparc64
Setting /opt/qemu-user-static/bin/qemu-ppc as binfmt interpreter for ppc
Setting /opt/qemu-user-static/bin/qemu-ppc64 as binfmt interpreter for ppc64
Setting /opt/qemu-user-static/bin/qemu-ppc64le as binfmt interpreter for ppc64le
Setting /opt/qemu-user-static/bin/qemu-m68k as binfmt interpreter for m68k
Setting /opt/qemu-user-static/bin/qemu-mips as binfmt interpreter for mips
Setting /opt/qemu-user-static/bin/qemu-mipsel as binfmt interpreter for mipsel
Setting /opt/qemu-user-static/bin/qemu-mipsn32 as binfmt interpreter for mipsn32
Setting /opt/qemu-user-static/bin/qemu-mipsn32el as binfmt interpreter for mipsn32el
Setting /opt/qemu-user-static/bin/qemu-mips64 as binfmt interpreter for mips64
Setting /opt/qemu-user-static/bin/qemu-mips64el as binfmt interpreter for mips64el
Setting /opt/qemu-user-static/bin/qemu-sh4 as binfmt interpreter for sh4
Setting /opt/qemu-user-static/bin/qemu-sh4eb as binfmt interpreter for sh4eb
Setting /opt/qemu-user-static/bin/qemu-s390x as binfmt interpreter for s390x
Setting /opt/qemu-user-static/bin/qemu-aarch64_be as binfmt interpreter for aarch64_be
Setting /opt/qemu-user-static/bin/qemu-hppa as binfmt interpreter for hppa
Setting /opt/qemu-user-static/bin/qemu-riscv32 as binfmt interpreter for riscv32
Setting /opt/qemu-user-static/bin/qemu-riscv64 as binfmt interpreter for riscv64
Setting /opt/qemu-user-static/bin/qemu-xtensa as binfmt interpreter for xtensa
Setting /opt/qemu-user-static/bin/qemu-xtensaeb as binfmt interpreter for xtensaeb
Setting /opt/qemu-user-static/bin/qemu-microblaze as binfmt interpreter for microblaze
Setting /opt/qemu-user-static/bin/qemu-microblazeel as binfmt interpreter for microblazeel
Setting /opt/qemu-user-static/bin/qemu-or1k as binfmt interpreter for or1k
Setting /opt/qemu-user-static/bin/qemu-x86_64 as binfmt interpreter for x86_64
Setting /opt/qemu-user-static/bin/qemu-hexagon as binfmt interpreter for hexagon

```

Check again, amd64/centos:8 & i686/ubuntu:20.04 container run correctly.
```
$ docker run -it --rm amd64/centos:8 uname -m
WARNING: The requested image's platform (linux/amd64) does not match the detected host platform (linux/arm64/v8) and no specific platform was requested
x86_64

$ docker run --rm -t i386/ubuntu:20.04 uname -m
WARNING: The requested image's platform (linux/386) does not match the detected host platform (linux/arm64/v8) and no specific platform was requested
i686
```

The busybox-s390x binary also works now
```
$ ./busybox-s390x uname -m
s390x
```

## Simple benchmark
Simple benchmark run on an Oracle Cloud ARM instance with 4C4T CPU + 24GB RAM, which is 4 CPU of 'VM.Standard.A1.Flex'.

Compressed bzip2 data file is 156MB, uncompressed to 9.6G raw text files
```
$ ls -l 2021-08-13_08-50-01.tar.bz2
-rw-r--r-- 1 root root 163405614 Aug 30 14:38 2021-08-13_08-50-01.tar.bz2
```

Decomress on the aarch64 host, 4C4T VM.Standard.A1.Flex on Oracle Cloud free tier.
```
$ time pbzip2 -k -c -d 2021-08-13_08-50-01.tar.bz2 > /dev/null

real    0m19.739s
user    1m17.713s
sys     0m0.372s
```

Run an docker container with amd64/centos:8
```
docker run -it --rm amd64/centos:8
```

Decomress on the amd64 container run on aarch64 host, emulated by this *multiarch-on-aarch64* project.
```
$ time pbzip2 -k -c -d 2021-08-13_08-50-01.tar.bz2 > /dev/null

real    2m23.367s
user    9m29.631s
sys     0m0.707s
```

The same data file unpacked on a single Intel E5-2667v2 (8C16T 4.0GHz) + 128GB RAM computer, which running CentOS7
```
$ time pbzip2 -k -c -d 2021-08-13_08-50-01.tar.bz2 > /dev/null

real    0m9.044s
user    1m52.792s
sys     0m10.674s
```

## References

* [1] QEMU: https://www.qemu.org/
* [2] binfmt_misc: https://www.kernel.org/doc/html/latest/admin-guide/binfmt-misc.html
* [3] multiarch/qemu-user-static: https://github.com/multiarch/qemu-user-static/
* [4] Docker: https://www.docker.com/
