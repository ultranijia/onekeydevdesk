
乌龟壳的特点是uefi，不过你其实帐号在60天内可以使用免费对象存储和自定义镜像，开一台bios的x86机
过了这个期限，就只能uefi了

网络在dd那个界面是正常，只是如果你D的是那种当初没按uefi的boot文件夹布局的镜像或系统，就会出现grub引导处菜单失败的情况。

正常的逻辑是，grub的bootx64.efi和prefix dir，prefix dir/grub.cfg一定要处在你mk-grubimg时指定prefix的目录中，比如/efi/boot/中。你定制的镜像一定要这样放置efi和配置文件。这是固件规定的。没法变。


利用inst.sh在oracle上dd
-----

自动方法：

```
wget -qO- 1keydd.com/inst.sh | bash -s - -t deb或你的gz直链
```

手动方法：

```
wget -qO- 1keydd.com/inst.sh | bash -s - -d

用vnc客户端连接ip:5900，密码为空
```


利用ci.sh定制oracle上的dd
-----


```
          ## orc
          #sudo sed -i "s/export[[:space:]]tmpBUILDGENE='0'/export tmpBUILDGENE='1'/g" ./ci.sh
          #sudo sed -i "s/gitee.com\/minlearn\/onekeydevdesk/gitee.com\/minlearn\/onekeydevdeskorc/g" ./ci.sh
          #sudo sed -i "s/github.com\/minlearn\/onekeydevdesk/github.com\/minlearn\/onekeydevdeskorc/g" ./ci.sh
          #sudo sed -i "s/_build\/onekeydevdesk/_build\/onekeydevdeskorc/g" ./ci.sh
          #sudo sed -i "s/remasteringdir\/grub2\/boot\/grub\/grub.cfg/remasteringdir\/grub2\/efi\/boot\/grub.cfg/g" ./p/31.remaster/ci2.sh
          #sudo sed -i "s/\[\[ \"\$tmpBUILDGENE\"[[:space:]]==[[:space:]]'1'[[:space:]]\]\][[:space:]]\&\&[[:space:]]cp/# \[\[ \"\$tmpBUILDGENE\" == '1' \]\] \&\& cp/g" ci.sh
          #sudo chmod +x ./ci.sh && sudo ./ci.sh -b 0 -h 0 -t onekeydevdesk
```

