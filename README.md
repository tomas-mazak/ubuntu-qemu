Ubuntu for GNS3 qemu image
==========================

Build an Ubuntu image to be used with GNS3.

Prerequisites
-------------

```shell
sudo apt-get install quemu-utils parted debootstrap
```

Build image
-----------

```shell
make IMG_ROOTPW=mysecret
```

`ubuntu.img` will be created
