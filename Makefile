IMG_FILE ?= ubuntu.img
IMG_SIZE ?= 10G
IMG_ROOTPW ?= gns3
NBD_DEV ?= /dev/nbd0

$(IMG_FILE): Makefile
	qemu-img create -f qcow2 $(IMG_FILE) $(IMG_SIZE)
	sudo modprobe nbd max_part=8
	sudo qemu-nbd --connect=$(NBD_DEV) $(IMG_FILE)
	sudo parted $(NBD_DEV) -- mklabel msdos mkpart primary 1m -1s toggle 1 boot
	sudo mkfs.ext4 -L root $(NBD_DEV)p1
	sudo mount $(NBD_DEV)p1 /mnt
	sudo debootstrap --variant=minbase --include=linux-image-generic,grub,python,openssh-server,iproute2,ifupdown,dbus,less,vim xenial /mnt
	sudo mount --bind /proc /mnt/proc
	sudo mount --bind /dev /mnt/dev
	sudo mount --bind /sys /mnt/sys
	sudo mkdir -p /mnt/boot/grub
	sudo cp default.grub /mnt/etc/default/grub
	sudo /bin/sh -c 'echo "LABEL=root	/	ext4	defaults		0 0" > /mnt/etc/fstab'
	sudo grub-install --boot-directory=/mnt/boot --modules=part_msdos $(NBD_DEV)
	sudo chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg
	sudo sed -i -r 's;root=/dev/\S*;root=LABEL=root;' /mnt/boot/grub/grub.cfg
	sudo sed -i 's/^PermitRootLogin .*/PermitRootLogin yes/' /mnt/etc/ssh/sshd_config
	sudo sed -i -r "s;root:[^:]*:;root:`echo '$(IMG_ROOTPW)' | mkpasswd -m SHA-256 -s`:;" /mnt/etc/shadow
	sudo /bin/sh -c 'echo ubuntu > /mnt/etc/hostname'
	sudo /bin/sh -c 'echo "deb http://archive.ubuntu.com/ubuntu xenial universe" >> /mnt/etc/apt/sources.list'
	sudo chroot /mnt apt-get clean
	sudo rm -Rf /mnt/var/lib/apt/lists
	sudo umount /mnt/dev /mnt/proc /mnt/sys /mnt
	sudo qemu-nbd --disconnect $(NBD_DEV)
	echo "Image '$(IMG_FILE)' built SUCCESSFULLY!"

archive: $(IMG_FILE)
	bzip2 -k $(IMG_FILE)

clean:
	rm -f $(IMG_FILE) $(IMG_FILE).bz2
