all: run

build/kernel: build/startup | build/
	cargo xbuild --target x86_64-rusty_l4.json
	cp target/x86_64-rusty_l4/debug/librusty_l4.a build/
	ld.lld -Tsrc/linker.ld -o build/kernel-nonstripped build/startup build/librusty_l4.a
	objcopy -g build/kernel-nonstripped build/kernel

build/startup: src/linker.ld src/startup.S | build/
	clang -c -fno-pic -no-pie -nostdlib -o build/startup src/startup.S 

build/os.iso: build/kernel grub.cfg
	mkdir -p build/isofiles/boot/grub
	cp build/kernel build/isofiles/boot/kernel.bin
	cp grub.cfg build/isofiles/boot/grub/
	grub-mkrescue -o build/os.iso build/isofiles

build/:
	mkdir build

build: build/kernel

run: build/os.iso
	qemu-system-x86_64 -cdrom build/os.iso -serial stdio -cpu Haswell,+pdpe1gb -no-reboot 

gdb: build/os.iso
	qemu-system-x86_64 -cdrom build/os.iso -serial stdio -cpu Haswell,+pdpe1gb -no-reboot -s -S

debug: build/os.iso
	qemu-system-x86_64 -cdrom build/os.iso -serial stdio -cpu Haswell,+pdpe1gb -no-reboot -d int

clean:
	rm -rf build
	cargo clean

.PHONY: run all clean build/kernel build
