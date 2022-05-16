# sd-fuse_rk3568
Create bootable SD card for NanoPi-R2S/NanoPi-NEO3

## How to find the /dev name of my SD Card
Unplug all usb devices:
```
ls -1 /dev > ~/before.txt
```
plug it in, then
```
ls -1 /dev > ~/after.txt
diff ~/before.txt ~/after.txt
```

## Build friendlycore bootable SD card
```
git clone https://github.com/friendlyarm/sd-fuse_rk3568.git
cd sd-fuse_rk3568
sudo ./fusing.sh /dev/sdX friendlycore-focal-arm64
```
You can build the following OS: friendlycore-focal-arm64, friendlywrt.  
Because the android system has to run on the emmc, so you need to make eflasher img to install Android.  

Notes:  
fusing.sh will check the local directory for a directory with the same name as OS, if it does not exist fusing.sh will go to download it from network.  
So you can download from the netdisk in advance, on netdisk, the images files are stored in a directory called images-for-eflasher, for example:
```
cd sd-fuse_rk3568
tar xvzf ../images-for-eflasher/friendlycore-focal-arm64-images.tgz
sudo ./fusing.sh /dev/sdX friendlycore-focal-arm64
```

## Build an sd card image
First, download and unpack:
```
git clone https://github.com/friendlyarm/sd-fuse_rk3568.git
cd sd-fuse_rk3568
wget http://112.124.9.243/dvdfiles/RK3568/images-for-eflasher/friendlycore-focal-arm64-images.tgz
tar xvzf friendlycore-focal-arm64-images.tgz
```
Now,  Change something under the friendlycore-focal-arm64 directory, 
for example, replace the file you compiled, then build friendlycore-focal-arm64 bootable SD card: 
```
sudo ./fusing.sh /dev/sdX friendlycore-focal-arm64
```
or build an sd card image:
```
./mk-sd-image.sh friendlycore-focal-arm64
```
The following file will be generated:  
```
out/rk3568-sd-friendlycore-focal-5.10-arm64-YYYYMMDD.img
```
You can use dd to burn this file into an sd card:
```
dd if=out/rk3568-sd-friendlycore-focal-5.10-arm64-YYYYMMDD.img of=/dev/sdX bs=1M
```
