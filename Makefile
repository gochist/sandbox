devstack-up:
	cd tool && \
	virsh destroy os-01 ; \
	virsh undefine os-01 ; \
	sudo ./define-image-ubuntu-devstack.sh && \
	sudo ./define-vm-linux.sh devstack 01 && \
	virsh start os-01 && \
	virt-viewer os-01 &
