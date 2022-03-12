

debug模式
-----

对于没有后台vnc的厂商，比如独服，dd后，可以用客户端连接ip:5900，无密码登录，，，在网络配置好后，会暂停在格式化硬盘的界面（上面我是退回几格，停在execute a shell点进去的效果），方便手动调试

还比如，需要手动格式分区的情况下。不要一键完成全部安装过程的需求情况

需要脚本和镜像都支持。比如你可以试下这个：https://github.com/minlearn/onekeydevdeskdebug


```
          ## manual vnc
          #sudo sed -i "s/export[[:space:]]tmpINSTEMBEDVNC='0'/export tmpINSTEMBEDVNC='1'/g" ./ci.sh
          #sudo sed -i "s/export[[:space:]]tmpINSTWITHMANUAL='0'/export tmpINSTWITHMANUAL='1'/g" ./ci.sh
          #sudo sed -i "s/export[[:space:]]tmpBUILDDEBUG='0'/export tmpBUILDDEBUG='1'/g" ./ci.sh
          #sudo sed -i "s/gitee.com\/minlearn\/onekeydevdesk/gitee.com\/minlearn\/onekeydevdeskdebug/g" ./ci.sh
          #sudo sed -i "s/github.com\/minlearn\/onekeydevdesk/github.com\/minlearn\/onekeydevdeskdebug/g" ./ci.sh
          #sudo sed -i "s/_build\/onekeydevdesk/_build\/onekeydevdeskdebug/g" ./ci.sh
          #sudo chmod +x ./ci.sh && sudo ./ci.sh -b 0 -h 0 -t onekeydevdesk
```