default_target: vm
.PHONY: vm clean

stage1/boot.bin: stage1/boot.asm
	nasm -DSTAGE2SIZE=$$(du -b stage2/target/x86-loadnothing/release/stage2 | cut -f1) -f bin -o stage1/boot.bin stage1/boot.asm

magic.bin:
	echo -en "\x55\xAA" > magic.bin

stage2/target/x86-loadnothing/release/stage2: stage2/src/main.rs
	cd stage2 && cargo build --release

nothing.img: magic.bin stage2/target/x86-loadnothing/release/stage2 stage1/boot.bin
	cp -p base.img nothing.img
	dd if=stage1/boot.bin of=nothing.img bs=1 count=446 conv=notrunc
	dd if=magic.bin of=nothing.img bs=1 seek=510 count=2 conv=notrunc
	dd if=stage2/target/x86-loadnothing/release/stage2 of=nothing.img bs=512 seek=1 conv=notrunc

vm: nothing.img
	qemu-system-x86_64 -hda nothing.img

clean:
	rm -f magic.bin stage1/boot.bin nothing.img
	cd stage2 && cargo clean
