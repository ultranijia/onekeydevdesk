

ncdd
=============

在服务器A上运行，表示nc在10000端口上守护，将接受到的镜像dd进/dev/sda，，双机环境下作为客户端接收端

```
wget -qO- 1keydd.com/inst.sh -t 10000:/dev/sda
```


在服务器B上运行，表示nc连接到服务器A（假设其ip为111.111.111.111）端口10000上向其发送本机/dev/sdb的dd包，，，双机环境作为服务端发送端
```
wget -qO- 1keydd.com/inst.sh -t /dev/sdb:111.111.111.111:10000
```


可以看到AB是一对相逆的过程：A(nc|dd),B(dd|nc)，整个数据路径：B->A,中间通过nc收发
先后运行AB，在A上会有进程显示，就跟wgetdd一样




