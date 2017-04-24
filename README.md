# raspberry-backup 
## 介绍
该脚本是用于自动备份树莓派系统的shell脚本，优点是备份出的映像文件小于SD卡的容量，节省存储空间
## 使用指导
直接运行脚本默认生成的备份文件为“raspberrypi.img”，放在当前目录下，文件大小为3.8G，如果待备份的系统占用空间大于3.8G，则会备份失败
该脚本支持传递两个参数，第一个参数为备份文件的存放路径，第二个为生成的备份文件的大小（单位：M）。

```
bash backup.sh /mnt/raspberrypi.img 5000
```
以上命令表示备份文件存放在/mnt/raspberrypi.img，文件大小为5G

## 适用系统
- raspberrypi
- ubuntu
- debian
