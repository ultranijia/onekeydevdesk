
这是个大盘鸡，仓库主要是用了xen pv的guest驱动和gpt/efi支持


利用inst.sh在serverica上dd
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


利用ci.sh定制serverica上的dd
-----

```
          ## sr
          #sudo sed -i "s/gitee.com\/minlearn\/onekeydevdesk/gitee.com\/minlearn\/onekeydevdesksr/g" ./ci.sh
          #sudo sed -i "s/github.com\/minlearn\/onekeydevdesk/github.com\/minlearn\/onekeydevdesksr/g" ./ci.sh
          #sudo sed -i "s/_build\/onekeydevdesk/_build\/onekeydevdesksr/g" ./ci.sh
          #sudo chmod +x ./ci.sh && sudo ./ci.sh -b 0 -h sr -t onekeydevdesk
```
