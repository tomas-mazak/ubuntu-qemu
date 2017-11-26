IMG_FILE ?= ubuntu.img
IMG_SIZE ?= 10G
IMG_ROOTPW ?= gns3

$(IMG_FILE): Makefile
	qemu-img create -f qcow2 $(IMG_FILE) $(IMG_SIZE)
	sudo modprobe nbd max_part=8
	sudo qemu-nbd --connect=/dev/nbd0 $(IMG_FILE)
	sudo parted /dev/nbd0 -- mklabel msdos mkpart primary 1m -1s toggle 1 boot
	sudo mkfs.ext4 -L root /dev/nbd0p1
	sudo mount /dev/nbd0p1 /mnt
	sudo debootstrap --variant=minbase --include=linux-image-generic,grub,python,openssh-server xenial /mnt
	sudo mount --bind /proc /mnt/proc
	sudo mount --bind /dev /mnt/dev
	sudo  mount --bind /sys /mnt/sys
	sudo mkdir -p /mnt/boot/grub
	sudo chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg
	sudo sed -i -r 's;root=/dev/\S*;root=LABEL=root;' /mnt/boot/grub/grub.cfg
	sudo grub-install --boot-directory=/mnt/boot --modules=part_msdos /dev/nbd0
	sudo sed -i 's/^PermitRootLogin .*/PermitRootLogin yes/' /mnt/etc/ssh/sshd_config
	sudo sed -i -r "s;root:[^:]*:;root:`echo '$(IMG_ROOTPW)' | mkpasswd -m SHA-256 -s`:;" /mnt/etc/shadow
	sudo /bin/sh -c 'echo ubuntu > /mnt/etc/hostname'
	sudo umount /mnt/dev /mnt/proc /mnt/sys /mnt
	sudo qemu-nbd --disconnect /dev/nbd0
	echo "Image '$(IMG_FILE)' built SUCCESSFULLY!"

archive: $(IMG_FILE)
	bzip2 -k $(IMG_FILE)

clean:
	rm -f $(IMG_FILE) $(IMG_FILE).bz2
