

more docs on feature,manual of onekeydevdesk：
=====
 
inst.sh is a script which installs onekeydevdesk (and other os) to various targets and help maintain it as onekeydevdesk os's recovery, like web assistant for synology's dsm  

ci.sh is a ci/cd builder script,which can construct up all "your own ddhub" (including inst.sh),ci.sh is also referred to as onekeydevdesk's codebase,which was made up of ci.sh, and other well-arranged asserts and src, they formed all the onekeydevdesk's codebase  

+ inst.sh
     +  [inst介绍：什么是inst.sh及它与onekeydevdesk ci.sh的关系](../instintro/readme_en.md)
     +  [inst使用：利用inst.sh安装onekeydevdesk，安装自定义镜像](../instusage/readme_en.md)
     +  [高级：对接inst.sh使用gitee,github建立你自己的镜像托管源，组装一体ddhub仓库](../howtohost/readme_en.md)
     +  [高级：wgetdd vs ncdd - 双机对拷和dump镜像,及简单制造打包镜像](../ncdd/readme_en.md)
     +  [高级：debug mode](../debugmode/readme_en.md)
+ ci.sh
     +  [ci介绍](../ciintro/readme_en.md)
     +  [ci使用：跑github actions编译inst.sh和onekeydevdesk](../ciusage/readme_en.md)
     +  高级和例子：扩展ci.sh，手动加入驱动,加入复杂机型网络及非DHCP支持的机型支持
          +  [azure](../ddexpandcicustom/az/readme_en.md)
          +  [servarica](../ddexpandcicustom/sr/readme_en.md)
          +  [oracle](../ddexpandcicustom/orc/readme_en.md)
          +  [kimsurf](../ddexpandcicustom/ks/readme_en.md)
          +  [spartan](../ddexpandcicustom/spt15g/readme_en.md)
+  onekeydevdesk
     +  [什么是onekeydevdesk os](../devdeskintro/readme_en.md)
     +  [设置onekeydevdesk](../devdeskusage/readme_en.md)
     +  [设置和使用云黑群镜像]
     +  [设置和使用deepin](../dpiusage/readme_en.md)
     +  [设置和使用cloudrevebox](../cloudreveboxusage/readme_en.md)
     +  [直接把pve面板当web面板和探针面板]
     +  [todo高级：使用openwrt容器打造云软路由]
     +  [todo高级：使用osx/win打造本地mac/win的mateos桌面]
     +  [todo高级：利用onekeydevdesk中的pve封装制造硬盘镜像]
     +  [todo高级：利用onekeydevdesk汇聚闲置机打造你的个人IDC]
