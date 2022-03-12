#!/usr/bin/env bash

## build and deploy your cloud hyper/desktop/disk with onekey dd
## Free,Written By MoeClub.org and linux-live.org,moded and enhanced by minlearn (https://github.com/minlearn/onekeydevdesk/) for 1, ddprogress fix in raw/native bash 2, onekeydevdesk remastering and installing (both local install and cloud wgetdd/ncdd) as its recovery 3, and for self-contained git mirror/image hosting (both debian and system img) 4, and for multiple machine type and models supports.
## meant to work/tested under debian family linux with bash > 4, ubuntu less than 20.04
## usage: ci.sh [[-b 0 ] -h 0[,az...]|az|sr|ks|orc|mbp] -t onekeydevdesk[,lxcxxx+/lxcxxx++...]|lxcxxx|tdl|debianbase [-d 1] # lxcxxx no+: pure standalone pack mode,+: mergemode into 01-core,++: packmode into 01-core
## usage: wget -qO- https://github.com/minlearn/onekeydevdesk/raw/master/inst.sh | bash [ -s - [-t deb | your .gz http/https location | port:blkname for nc | port:ip:blkname for nc] [-d]]

# for wget -qO- xxx| bash -s - subsitute manner
[ "$(id -u)" != 0 ] && exec sudo bash -c "`cat -`" -a "$@"
# for bash <(wget -qO- xxx) -t subsitute manner we should:
# [ "$(id -u)" != 0 ] && exec sudo bash -c "`cat "$0"`" -a "$@"
[[ "$EUID" -ne '0' ]] && echo "Error:This script must be run as root!" && exit 1
[[ ! "$(bash --version | head -n 1 | grep -o '[1-9]'| head -n 1)" -ge '4' ]] && echo "Error:bash must be at least 4!" && exit 1
[[ "$(uname -a)" =~ "inux" && "$(uname -a)" =~ "entos" ]] && echo "requires debian 10 or below,ubt 18 or below" && exit 1
[[ "$(uname -a)" =~ "inux" && "$(uname -a)" =~ "ebian" && $(echo $(lsb_release -sr) | awk -F '.' '{print($1)}') -ge '11' ]] && echo "requires debian 10 or below,ubt 18 or below" && exit 1
[[ "$(uname -a)" =~ "inux" && "$(uname -a)" =~ "buntu" && $(echo $(lsb_release -sr) | awk -F '.' '{print($1)}') -ge '20' ]] && echo "requires debian 10 or below,ubt 18 or below" && exit 1
# [[ ! "$(uname -a)" =~ "inux" ]] && echo "unsupported os" && exit 1
# [[ "$(uname)" == "Darwin" ]] && tmpBUILD='1' && read -s -n1 -p "osx detected"

# =================================================================
# globals
# =================================================================

# part I: settings related vars with initrfs,most usually are auto informed,not customable
export AutoNet=''                               # default
export setNet='0'                               # auto informed by judging if forcenetcfgstring are setted and feed
export FORCENETCFGSTR=''                        # sometimes gateway and defroute and not in the same subnet,they shoud be manual set in explict and static manner
                                                # string format: hostname,ipaddr,cidr,mac,netmask,gateway,route,dns1,dns2,should be in order and all field filled
                                                # azure use the hostname and dsm use the mac
                                                # example: NAME:myvps,IPv4:10.211.55.105,CIDR:24,MAC:001C42171017,MASK:255.255.255.0, 
                                                # GATE:10.211.55.1,STATICROUTE:default,DNS1:8.8.8.8,DNS2:1.1.1.1

export autoDEBMIRROR0='https://gitee.com/minlearn/onekeydevdesk/raw/master'
export autoDEBMIRROR1='https://github.com/minlearn/onekeydevdesk/raw/master'
export FORCEMIRROR=''                           # force apply a fixed mirror/targetddurl selection to force override autoselectdebmirror results based on -t -m args given
# export autoIMGMIRROR1=''                      # currently we apply the same mirror for deb and targetimg
export FORCEMIRRORIMGSIZE=''                    # force apply a fixed mirror/targetddimgsize to force checktarget results based on -s args given
export FORCEMIRRORIMGNOSEG=''                   # force apply the imgfile in both debmirrorsrc and imgmirrorsrc as non-seg git repo style,set to 1 to use common one-piece style

export tmpBUILD='0'                             # 0:linux,1:unix,osx,2,lxc
export tmpBUILDGENE='0'                         # 0:biosmbr,1:biosgpt,2:uefigpt
export tmpHOST=''                               # (blank)0,az,servarica(sr),(kimsurf/ovh/sys)ks,orc,spt15g,mbp,pd
export tmpHOSTMODEL='0'                         # 0:kvm,1:hv,2:xen,>2:bearmetal,auto informed,not customable,0:awlays bothmode,1-98:instonlymode,99,mixed build mode
                                                # attention:in mixed mode,we can add modules for 0,1,2,greater than 2 into a initramfs,but we cant add other aspacts applied to initramfs
                                                # we can mixed modules for build mode,and do other aspect installtime job in one-one-unmixed mode
export HOSTMODLIST='0'

export tmpTARGET=''                             # dummy(for -d only),debianbase,tdl,lxcdeepin,lxccloudrevebox,lxccodeserverbox|onekeydevdesk,dsm61715284,win11,osx10146
                                                # if -t were given as port:blkdevname,then enter nc servermode(rever,target)
                                                # if -t were given as port:ip:blkdevname,then enter nc clientmode(sender,src)
export tmpTARGETMODE='0'                        # 0:WGETDD INSTMODE ONLY 1:CLOUDDDINSTALL+BUILD MIXTURE,2,3,nc install mode,defaultly it sholudbe 0

# part II: customables related with 01-core,clients,lxcapps
export tmpBUILDREUSEPBIFS='0'                   # use prebuilt initrfs.img in tmpbuild,0 dont use,1,use initrfs1.img,2,use initrfs2.img,auto informed
export tmpBUILDPUTPVEINIFS='0'                  # put pve building prodcure inside initramfs? 
export custIMGSIZE='20'
export custUSRANDPASS='tdl'
export tmpTGTNICNAME='eth0'
export tmpTGTNICIP='111.111.111.111'            # pve only,input target nic public ip(127.0.0.1 and 127.0.1.1 forbidden,enter to use defaults 111.111.111.111)
export tmpWIFICONNECT='CMCC-Lsl,11111111,wlan0' # input target wifi connecting settings(in valid hotspotname,hotspotpasswd,wifinicname form,passwd 8-63 long,enter to leave blank)

export GENCLIENTS='y' # linux,win,osx
export GENCLIENTSWINOSX='n'
export PACKCLIENTS='n'
export tmpEBDCLIENTURL='t.shalol.com'           # input target ip or domain that will be embeded into client

export GENCONTAINERS='lxcopenwrt'               # list for mergemode into 01-core
export PACKCONTAINERS=''                        # list packmode into 01-core

# part III: ci/cd extra addons
export tmpINSTWITHVNC='0'                       # 0,use native vncserver?
export tmpINSTEMBEDVNC='0'                      # 0,embeded a vncserver?
export tmpINSTWITHMANUAL='0'                    # 0,after networksetup done,enter manual mode? for debugging purpose and for instmode only
export tmpBUILDDEBUG='0'                        # 0,debug=embed a vncserver + manual
export tmpINSTSERIAL='0'                        # 0 with serial console output support
export tmpBUILDCI='1'                           # full ci/cd mode,with git and split post addon actions,0，no ci,1,normal ciaddons for onekeydevdeskbuild 2,ciaddons for lxc*build standalone

# =================================================================
# Below are function libs
# =================================================================


function CheckDependence(){

  FullDependence='0';
  lostdeplist="";

  for BIN_DEP in `[[ "$tmpBUILDFORM" -ne '0' ]] && echo "$1" |sed 's/,/\n/g' || echo "$1" |sed 's/,/\'$'\n''/g'`
    do
      if [[ -n "$BIN_DEP" ]]; then
        Founded='1';
        for BIN_PATH in `[[ "$tmpBUILDFORM" -ne '0' ]] && echo "$PATH" |sed 's/:/\n/g' || echo "$PATH" |sed 's/:/\'$'\n''/g'`
          do
            ls $BIN_PATH/$BIN_DEP >/dev/null 2>&1;
            if [ $? == '0' ]; then
              Founded='0';
              break;
            fi
          done
        echo -en "[ \033[32m $BIN_DEP";
        if [ "$Founded" == '0' ]; then
          echo -en ",ok \033[0m] ";
        else
          FullDependence='1';
          echo -en ",\033[31m not ok \033[0m] ";
          lostdeplist+="$BIN_DEP"
        fi
      fi
  done

  # [[ "$tmpBUILDGENE" == '1' && "$tmpTARGET" == 'onekeydevdesk' && "$tmpTARGETMODE" == '1' ]] && [[ ! -f /usr/lib/grub/x86_64-efi/acpi.mod ]] && echo -en "[ \033[32m grub-efi,\033[31m not ok \033[0m] " && FullDependence='1' && lostdeplist+="grub-efi"

  if [ "$FullDependence" == '1' ]; then

    echo -ne "\n \033[31m Error!!!,some deps not found! \033[0m Please use '\033[33msudo apt-get install `\
      [[ $lostdeplist =~ "sudo" ]] && echo -n ' 'sudo; \
      [[ $lostdeplist =~ "curl" ]] && echo -n ' 'curl; \
      [[ $lostdeplist =~ "ar" ]] && echo -n ' 'binutils; \
      [[ $lostdeplist =~ "cpio" ]] && echo -n ' 'cpio; \
      [[ $lostdeplist =~ "xzcat" ]] && echo -n ' 'xz-utils; \
      [[ $lostdeplist =~ "md5sum" || $lostdeplist =~ "sha1sum" || $lostdeplist =~ "sha256sum" ]] && echo -n ' 'coreutils; \
      [[ $lostdeplist =~ "losetup" ]] && echo -n ' 'util-linux; \
      [[ $lostdeplist =~ "parted" ]] && echo -n ' 'parted; \
      [[ $lostdeplist =~ "mkfs.fat" ]] && echo -n ' 'dosfstools; \
      [[ $lostdeplist =~ "squashfs" ]] && echo -n ' 'squashfs-tools; \
      [[ $lostdeplist =~ "sqlite3" ]] && echo -n ' 'sqlite3; \
      [[ $lostdeplist =~ "unzip" ]] && echo -n ' 'unzip; \
      [[ $lostdeplist =~ "zip" ]] && echo -n ' 'zip; \
      [[ $lostdeplist =~ "7z" ]] && echo -n ' 'p7zip; \
    `\033[0m' to install them.\n"

    exit 1;
  fi
}

SAMPLES=3
BYTES=511999 #1mb
TIMEOUT=1
TESTFILE="/debianbase/1mtest"

function test_mirror() {
  for s in $(seq 1 $SAMPLES) ; do
    time=$(curl -r 0-$BYTES --max-time $TIMEOUT --silent --output /dev/null --write-out %{time_total} ${1}${TESTFILE})
    if [ "$TIME" == "0.000" ] ; then exit 1; fi
    echo $time
  done
}

function mean() {
  len=$#
  echo $* | tr " " "\n" | sort -n | head -n $(((len+1)/2)) | tail -n 1
}


function SelectDEBMirror(){

  [ $# -ge 1 ] || exit 1

  declare -A MirrorTocheck
  MirrorTocheck=(["Debian0"]="" ["Debian1"]="" ["Debian2"]="")
  
  echo "$1" |sed 's/\ //g' |grep -q '^http://\|^https://\|^ftp://' && MirrorTocheck[Debian0]=$(echo "$1" |sed 's/\ //g');
  echo "$2" |sed 's/\ //g' |grep -q '^http://\|^https://\|^ftp://' && MirrorTocheck[Debian1]=$(echo "$2" |sed 's/\ //g');
  #echo "$3" |sed 's/\ //g' |grep -q '^http://\|^https://\|^ftp://' && MirrorTocheck[Debian2]=$(echo "$3" |sed 's/\ //g');

  TimeLog0=''
  TimeLog1=''
  #TimeLog2=''

  for mirror in `[[ "$tmpBUILDFORM" -ne '0' ]] && echo "${!MirrorTocheck[@]}" |sed 's/\ /\n/g' |sort -n |grep "^Debian" || echo "${!MirrorTocheck[@]}" |sed 's/\ /\'$'\n''/g' |sort -n |grep "^Debian"`
    do
      CurMirror="${MirrorTocheck[$mirror]}"

      [ -n "$CurMirror" ] || continue

      # CheckPass1='0';
      # DistsList="$(wget --no-check-certificate -qO- "$CurMirror/dists/" |grep -o 'href=.*/"' |cut -d'"' -f2 |sed '/-\|old\|Debian\|experimental\|stable\|test\|sid\|devel/d' |grep '^[^/]' |sed -n '1h;1!H;$g;s/\n//g;s/\//\;/g;$p')";
      # for DIST in `echo "$DistsList" |sed 's/;/\n/g'`
        # do
          # [[ "$DIST" == "buster" ]] && CheckPass1='1' && break;
        # done
      # [[ "$CheckPass1" == '0' ]] && {
        # echo -ne '\nbuster not find in $CurMirror/dists/, Please check it! \n\n'
        # bash $0 error;
        # exit 1;
      # }

      # CheckPass2=0
      # ImageFile="SUB_MIRROR/releases/linux"
      # [ -n "$ImageFile" ] || exit 1
      # URL=`echo "$ImageFile" |sed "s#SUB_MIRROR#${CurMirror}#g"`
      # wget --no-check-certificate --spider --timeout=3 -o /dev/null "$URL"
      # [ $? -eq 0 ] && CheckPass2=1 && echo "$CurMirror" && break
    # done


      # CheckPass3=0
      mean=$(mean $(test_mirror $CurMirror))
      if [ "$mean" != "-nan" ] ; then
        printf '%-60s %.5f\\n' $CurMirror $mean
      else
        printf '%-60s failed, ignoring\\n' $CurMirror 1>&2
      fi

    done
    
    # final result mirror
    #[[ "$TimeLog0" -gt "$TimeLog1" ]] && echo "${MirrorTocheck[Debian0]}" || echo "${MirrorTocheck[Debian1]}"
    #[[ "$TimeLog2" -lt "$TimeLog0" && "$TimeLog2" -lt "$TimeLog1" ]] && echo "${MirrorTocheck[Debian2]}"


    # [[ $CheckPass2 == 0 ]] && {
      # echo -ne "\033[31m Error! \033[0m the file linux not find in $CurMirror/releases/! \n";
      # bash $0 error;
      # exit 1;
    # }

}


function CheckTarget(){

  if [[ -n "$1" ]]; then
    echo "$1" |grep -q '^http://\|^ftp://\|^https://\|^10000:/dev/\|^/dev/';
    [[ $? -ne '0' ]] && echo 'Invalid generic target given,Only support http://, ftp://, https://, port:/dev/ and /dev/:port schedmas !' && exit 1;

    [[ "$tmpTARGET" =~ "/dev/" ]] && IMGHEADERCHECK="nc" && sleep 3s && echo -e "[ \033[32m nc mode\033[0m ]" || {

      [[ "$tmpTARGET" != "onekeydevdesk" ]] && IMGHEADERCHECK="$(curl -k -IsL "$1")";
      [[ "$tmpTARGET" != "onekeydevdesk" ]] && IMGSIZE=20 || IMGSIZE=20
      #[[ "$tmpTARGET" != "onekeydevdesk" ]] && IMGSIZE="$(echo "$IMGHEADERCHECK" | grep 'Content-Length'|awk '{print $2}')" || IMGSIZE=20
      [[ "$tmpTARGET" != "onekeydevdesk" ]] && IMGTYPECHECK="$(echo "$IMGHEADERCHECK"|grep -E -o '200|302'|head -n 1)" || IMGTYPECHECK='gitrawurl';

      #directurl style,just 1
      [[ "$IMGTYPECHECK" == '200' || "$tmpTARGET" != 'onekeydevdesk' ]] && UNZIP='1' && sleep 3s && echo -e "[ \033[32m x-gzip";
      [[ "$IMGTYPECHECK" == '200' || "$tmpTARGET" == 'onekeydevdesk' ]] && UNZIP='1' && sleep 3s && echo -e "[ \033[32m git-segs";

      # refurl style,(no more imgheadcheck and 1 more imgtypecheck pass needed)
      [[ "$IMGTYPECHECK" == '302' ]] && \
      IMGTYPECHECKPASS_REF="$(echo "$IMGHEADERCHECK"|grep -E -o 'raw|qcow2|gzip|x-gzip'|head -n 1)" && {
        # IMGSIZE
        [[ "$IMGTYPECHECKPASS_REF" == 'raw' ]] && UNZIP='0' && sleep 3s && echo -e "[ \033[32m raw";
        [[ "$IMGTYPECHECKPASS_REF" == 'qcow2' ]] && UNZIP='0' && sleep 3s && echo -e "[ \033[32m qcow2";
        [[ "$IMGTYPECHECKPASS_REF" == 'gzip' ]] && UNZIP='1' && sleep 3s && echo -e "[ \033[32m gzip";
        [[ "$IMGTYPECHECKPASS_REF" == 'x-gzip' ]] && UNZIP='1' && sleep 3s && echo -e "[ \033[32m x-gzip";
        [[ "$IMGTYPECHECKPASS_REF" == 'gunzip' ]] && UNZIP='2' && sleep 3s && echo -e "[ \033[32m gunzip";
      }

      echo -e ",$IMGSIZEG \033[0m ]"

      [[ "$UNZIP" == '' ]] && echo 'didnt got a unzip mode, you may input a incorrect url,or the bad network traffic caused it,exit ... !' && exit 1;
      [[ "$IMGSIZE" == '' ]] && echo 'didnt got img size,or img too small,is there sth wrong? exit ... !' && exit 1;
      [[ "$IMGTYPECHECK" == '' ]] && echo 'not img url are not 301/302 refs or git raw url, exit ... !' && exit 1;

    }

  else
    echo 'Please input vaild image URL! ';
    exit 1;
  fi

}

function getbasics(){

  compositemode="$1"

  # when down was used,only targetmode 0 occurs
  [[ "$1" == 'down' ]] && {

    [[ ! -f $topdir/$downdir/tdl/vmlinuz || ! -s $topdir/$downdir/tdl/vmlinuz ]] && (for i in `seq -w 000 005`;do wget -qO- --no-check-certificate $MIRROR/_build/tdl/vmlinuz_$i; done) > $topdir/$downdir/tdl/vmlinuz & pid=`expr $! + 0`;wait $pid;echo -en "[ \033[32m kernelimage,done \033[0m ]" && [[ $? -ne '0' ]] && echo "download failed" && exit 1
    [[ ! -f $topdir/$downdir/tdl/tdlcore$([[ "$tmpINSTEMBEDVNC" == '1' ]] && echo d).tar.gz || ! -s $topdir/$downdir/tdl/tdlcore$([[ "$tmpINSTEMBEDVNC" == '1' ]] && echo d).tar.gz ]] && (for i in `seq -w 000 060`;do wget -qO- --no-check-certificate $MIRROR/_build/tdl/tdlcore$([[ "$tmpINSTEMBEDVNC" == '1' ]] && echo d).tar.gz_$i; done) > $topdir/$downdir/tdl/tdlcore$([[ "$tmpINSTEMBEDVNC" == '1' ]] && echo d).tar.gz & pid=`expr $! + 0`;wait $pid;echo -en "[ \033[32m tdlcore tarball,done \033[0m ]" && [[ $? -ne '0' ]] && echo "download failed" && exit 1

  }

  # when copy was used,sometimes targetmode 0 and 1 both occurs
  # [[ "$1" == 'copy' ]] && {

    # [[ ! -f $topdir/$downdir/tdl/tdlcore.tar.gz || ! -s $topdir/$downdir/tdl/tdlcore.tar.gz ]] && cat $topdir/$downdir/tdl/tdlcore.tar.gz_* > $topdir/$downdir/tdl/tdlcore.tar.gz && [[ $? -ne '0' ]] && echo "cat failed" && exit 1
    # tdlinitrd.gz only in builddir p/
    # [[ "$tmpTARGETMODE" == "1" ]] && [[ ! -f $topdir/$downdir/tdl/tdlinitrd.tar.gz || ! -s $topdir/$downdir/tdl/tdlinitrd.tar.gz ]] && (for i in `seq -w 000 038`;do wget -qO- --no-check-certificate $MIRROR/$downdir/tdl/tdlinitrd.tar.gz_$i; done) > $topdir/$downdir/tdl/tdlinitrd.tar.gz & pid=`expr $! + 0`;wait $pid;echo -en "[ \033[32m tdlinitrd tarball,done \033[0m ]" && [[ $? -ne '0' ]] && echo "download failed" && exit 1
    # [[ ! -f $kernelimage ]] && cat $kernelimage*  > $kernelimage && [[ $? -ne '0' ]] && echo "cat failed" && exit 1

  # }

}





ipNum()
{
  local IFS='.';
  read ip1 ip2 ip3 ip4 <<<"$1";
  echo $((ip1*(1<<24)+ip2*(1<<16)+ip3*(1<<8)+ip4));
}

SelectMax(){
  ii=0;
  for IPITEM in `route -n |awk -v OUT=$1 '{print $OUT}' |grep '[0-9]\{1,3\}.[0-9]\{1,3\}.[0-9]\{1,3\}.[0-9]\{1,3\}'`
    do
      NumTMP="$(ipNum $IPITEM)";
      eval "arrayNum[$ii]='$NumTMP,$IPITEM'";
      ii=$[$ii+1];
    done
  echo ${arrayNum[@]} |sed 's/\s/\n/g' |sort -n -k 1 -t ',' |tail -n1 |cut -d',' -f2;
}

parsenetcfg(){

  [ -n "$FORCENETCFGSTR" ] && setNet='1';


  [[ -n "$custWORD" ]] && myPASSWORD="$(openssl passwd -1 "$custWORD")";
  [[ -z "$myPASSWORD" ]] && myPASSWORD='$1$4BJZaD0A$y1QykUnJ6mXprENfwpseH0';

  if [[ -n "$interface" ]]; then
    IFETH="$interface"
  else
    IFETH="auto"
  fi

  [[ "$setNet" == '1' ]] && {

    # NAME:myvps,IPv4:10.211.55.105,CIDR:24,MAC:001C42171017,MASK:255.255.255.0,GATE:10.211.55.1,STATICROUTE:default,DNS1:8.8.8.8,DNS2:1.1.1.1

    NAME=`echo "$FORCENETCFGSTR" | awk -F ',' '{ print $1}' | awk -F ':' '{ print $2}'`
    IPv4=`echo "$FORCENETCFGSTR" | awk -F ',' '{ print $2}' | awk -F ':' '{ print $2}'`
    CIDR=`echo "$FORCENETCFGSTR" | awk -F ',' '{ print $3}' | awk -F ':' '{ print $2}'`
    MAC=`echo "$FORCENETCFGSTR" | awk -F ',' '{ print $4}' | awk -F ':' '{ print $2}'`
    MASK=`echo "$FORCENETCFGSTR" | awk -F ',' '{ print $5}' | awk -F ':' '{ print $2}'`
    GATE=`echo "$FORCENETCFGSTR" | awk -F ',' '{ print $6}' | awk -F ':' '{ print $2}'`
    STATICROUTE=`echo "$FORCENETCFGSTR" | awk -F ',' '{ print $7}' | awk -F ':' '{ print $2}'`
    DNS1=`echo "$FORCENETCFGSTR" | awk -F ',' '{ print $8}' | awk -F ':' '{ print $2}'`
    DNS2=`echo "$FORCENETCFGSTR" | awk -F ',' '{ print $9}' | awk -F ':' '{ print $2}'`


  } || {
    DEFAULTNET="$(ip route show |grep -o 'default via [0-9]\{1,3\}.[0-9]\{1,3\}.[0-9]\{1,3\}.[0-9]\{1,3\}.*' |head -n1 |sed 's/proto.*\|onlink.*//g' |awk '{print $NF}')";
    [[ -n "$DEFAULTNET" ]] && IPSUB="$(ip addr |grep ''${DEFAULTNET}'' |grep 'global' |grep 'brd' |head -n1 |grep -o '[0-9]\{1,3\}.[0-9]\{1,3\}.[0-9]\{1,3\}.[0-9]\{1,3\}/[0-9]\{1,2\}')";
    IPv4="$(echo -n "$IPSUB" |cut -d'/' -f1)";
    CIDR="$(echo -n "$IPSUB" |grep -o '/[0-9]\{1,2\}')";
    GATE="$(ip route show |grep -o 'default via [0-9]\{1,3\}.[0-9]\{1,3\}.[0-9]\{1,3\}.[0-9]\{1,3\}' |head -n1 |grep -o '[0-9]\{1,3\}.[0-9]\{1,3\}.[0-9]\{1,3\}.[0-9]\{1,3\}')";
    [[ -n "$CIDR" ]] && MASK="$(echo -n '128.0.0.0/1,192.0.0.0/2,224.0.0.0/3,240.0.0.0/4,248.0.0.0/5,252.0.0.0/6,254.0.0.0/7,255.0.0.0/8,255.128.0.0/9,255.192.0.0/10,255.224.0.0/11,255.240.0.0/12,255.248.0.0/13,255.252.0.0/14,255.254.0.0/15,255.255.0.0/16,255.255.128.0/17,255.255.192.0/18,255.255.224.0/19,255.255.240.0/20,255.255.248.0/21,255.255.252.0/22,255.255.254.0/23,255.255.255.0/24,255.255.255.128/25,255.255.255.192/26,255.255.255.224/27,255.255.255.240/28,255.255.255.248/29,255.255.255.252/30,255.255.255.254/31,255.255.255.255/32' |grep -o '[0-9]\{1,3\}.[0-9]\{1,3\}.[0-9]\{1,3\}.[0-9]\{1,3\}'${CIDR}'' |cut -d'/' -f1)";
  }

  [[ -n "$GATE" ]] && [[ -n "$MASK" ]] && [[ -n "$IPv4" ]] || {
    echo "\`ip command\` Failed to get gate,mask,ipv4 settings, will try using \`route command\`."


    [[ -z $IPv4 ]] && IPv4="$(ifconfig |grep 'Bcast' |head -n1 |grep -o '[0-9]\{1,3\}.[0-9]\{1,3\}.[0-9]\{1,3\}.[0-9]\{1,3\}' |head -n1)";
    [[ -z $GATE ]] && GATE="$(SelectMax 2)";
    [[ -z $MASK ]] && MASK="$(SelectMax 3)";

    [[ -n "$GATE" ]] && [[ -n "$MASK" ]] && [[ -n "$IPv4" ]] || {
      echo "Error! get netcfg auto settings failed. please speficty static netcfg settings";
      exit 1;
    }
  }

  [[ "$setNet" != '1' ]] && [[ -f '/etc/network/interfaces' ]] && {
    [[ -z "$(sed -n '/iface.*inet static/p' /etc/network/interfaces)" ]] && AutoNet='1' || AutoNet='0';
    [[ -d /etc/network/interfaces.d ]] && {
      ICFGN="$(find /etc/network/interfaces.d -name '*.cfg' |wc -l)" || ICFGN='0';
      [[ "$ICFGN" -ne '0' ]] && {
        for NetCFG in `ls -1 /etc/network/interfaces.d/*.cfg`
          do 
            [[ -z "$(cat $NetCFG | sed -n '/iface.*inet static/p')" ]] && AutoNet='1' || AutoNet='0';
            [[ "$AutoNet" -eq '0' ]] && break;
          done
      }
    }
  }

}


parsegrub(){

  if [[ "$LoaderMode" == "0" ]]; then
    [[ -f '/boot/grub/grub.cfg' ]] && GRUBVER='0' && GRUBDIR='/boot/grub' && GRUBFILE='grub.cfg';
    [[ -z "$GRUBDIR" ]] && [[ -f '/boot/grub2/grub.cfg' ]] && GRUBVER='0' && GRUBDIR='/boot/grub2' && GRUBFILE='grub.cfg';
    [[ -z "$GRUBDIR" ]] && [[ -f '/boot/grub/grub.conf' ]] && GRUBVER='1' && GRUBDIR='/boot/grub' && GRUBFILE='grub.conf';
    [ -z "$GRUBDIR" -o -z "$GRUBFILE" ] && echo -ne "Error! \nNot Found grub.\n" && exit 1;
  else
    tmpTARGETINSTANTWITHOUTVNC='0'
  fi

  if [[ "$LoaderMode" == "0" ]]; then
    [[ ! -f $GRUBDIR/$GRUBFILE ]] && echo "Error! Not Found $GRUBFILE. " && exit 1;

    [[ ! -f $GRUBDIR/$GRUBFILE.old ]] && [[ -f $GRUBDIR/$GRUBFILE.bak ]] && mv -f $GRUBDIR/$GRUBFILE.bak $GRUBDIR/$GRUBFILE.old;
    mv -f $GRUBDIR/$GRUBFILE $GRUBDIR/$GRUBFILE.bak;
    [[ -f $GRUBDIR/$GRUBFILE.old ]] && cat $GRUBDIR/$GRUBFILE.old >$GRUBDIR/$GRUBFILE || cat $GRUBDIR/$GRUBFILE.bak >$GRUBDIR/$GRUBFILE;
  else
    GRUBVER='2'
  fi


  [[ "$GRUBVER" == '0' ]] && {

    # we also offer a efi here
    mkdir -p $remasteringdir/boot $remasteringdir/boot/grub/i386-pc $remasteringdir/boot/EFI/boot/x86_64-efi

    READGRUB=''$remasteringdir'/boot/grub.read'
    cat $GRUBDIR/$GRUBFILE |sed -n '1h;1!H;$g;s/\n/%%%%%%%/g;$p' |grep -om 1 'menuentry\ [^{]*{[^}]*}%%%%%%%' |sed 's/%%%%%%%/\n/g' >$READGRUB
    LoadNum="$(cat $READGRUB |grep -c 'menuentry ')"
    if [[ "$LoadNum" -eq '1' ]]; then
      cat $READGRUB |sed '/^$/d' >$remasteringdir/boot/grub.new;
    elif [[ "$LoadNum" -gt '1' ]]; then
      CFG0="$(awk '/menuentry /{print NR}' $READGRUB|head -n 1)";
      CFG2="$(awk '/menuentry /{print NR}' $READGRUB|head -n 2 |tail -n 1)";
      CFG1="";
      for tmpCFG in `awk '/}/{print NR}' $READGRUB`
        do
          [ "$tmpCFG" -gt "$CFG0" -a "$tmpCFG" -lt "$CFG2" ] && CFG1="$tmpCFG";
        done
      [[ -z "$CFG1" ]] && {
        echo "Error! read $GRUBFILE. ";
        exit 1;
      }

      sed -n "$CFG0,$CFG1"p $READGRUB >$remasteringdir/boot/grub.new;
      [[ -f $remasteringdir/boot/grub.new ]] && [[ "$(grep -c '{' $remasteringdir/boot/grub.new)" -eq "$(grep -c '}' $remasteringdir/boot/grub.new)" ]] || {
        echo -ne "\033[31m Error! \033[0m Not configure $GRUBFILE. \n";
        exit 1;
      }
    fi
    [ ! -f $remasteringdir/boot/grub.new ] && echo "Error! $GRUBFILE. " && exit 1;
    sed -i "/menuentry.*/c\menuentry\ \'DI PE \[debian\ buster\ amd64\]\'\ --class debian\ --class\ gnu-linux\ --class\ gnu\ --class\ os\ --unrestricted\ \{" $remasteringdir/boot/grub.new
    sed -i "/echo.*Loading/d" $remasteringdir/boot/grub.new;
    INSERTGRUB="$(awk '/menuentry /{print NR}' $GRUBDIR/$GRUBFILE|head -n 1)"
  }

  [[ "$GRUBVER" == '1' ]] && {
    CFG0="$(awk '/title[\ ]|title[\t]/{print NR}' $GRUBDIR/$GRUBFILE|head -n 1)";
    CFG1="$(awk '/title[\ ]|title[\t]/{print NR}' $GRUBDIR/$GRUBFILE|head -n 2 |tail -n 1)";
    [[ -n $CFG0 ]] && [ -z $CFG1 -o $CFG1 == $CFG0 ] && sed -n "$CFG0,$"p $GRUBDIR/$GRUBFILE >$remasteringdir/boot/grub.new;
    [[ -n $CFG0 ]] && [ -z $CFG1 -o $CFG1 != $CFG0 ] && sed -n "$CFG0,$[$CFG1-1]"p $GRUBDIR/$GRUBFILE >$remasteringdir/boot/grub.new;
    [[ ! -f $remasteringdir/boot/grub.new ]] && echo "Error! configure append $GRUBFILE. " && exit 1;
    sed -i "/title.*/c\title\ \'DebianNetboot \[buster\ amd64\]\'" $remasteringdir/boot/grub.new;
    sed -i '/^#/d' $remasteringdir/boot/grub.new;
    INSERTGRUB="$(awk '/title[\ ]|title[\t]/{print NR}' $GRUBDIR/$GRUBFILE|head -n 1)"
  }

  if [[ "$LoaderMode" == "0" ]]; then
    [[ -n "$(grep 'linux.*/\|kernel.*/' $remasteringdir/boot/grub.new |awk '{print $2}' |tail -n 1 |grep '^/boot/')" ]] && Type='InBoot' || Type='NoBoot';

    LinuxKernel="$(grep 'linux.*/\|kernel.*/' $remasteringdir/boot/grub.new |awk '{print $1}' |head -n 1)";
    [[ -z "$LinuxKernel" ]] && echo "Error! read grub config! " && exit 1;
    LinuxIMG="$(grep 'initrd.*/' $remasteringdir/boot/grub.new |awk '{print $1}' |tail -n 1)";
    [ -z "$LinuxIMG" ] && sed -i "/$LinuxKernel.*\//a\\\tinitrd\ \/" $remasteringdir/boot/grub.new && LinuxIMG='initrd';

    if [[ "$setInterfaceName" == "1" ]]; then
      Add_OPTION="net.ifnames=0 biosdevname=0";
    else
      Add_OPTION="";
    fi

    if [[ "$setIPv6" == "1" ]]; then
      Add_OPTION="$Add_OPTION ipv6.disable=1";
    fi

    # $([[ "$tmpINSTEMBEDVNC" == '1' ]] && echo DEBIAN_FRONTEND=gtk) is not needed,will be forced in debug mode
    BOOT_OPTION="console=ttyS0,115200n8 console=tty0 debian-installer/framebuffer=false $([[ "$tmpINSTSSHONLY" == '1' ]] && echo DEBIAN_FRONTEND=text) auto=true $Add_OPTION hostname=debian domain= -- quiet";

    [[ "$Type" == 'InBoot' ]] && {
      sed -i "/$LinuxKernel.*\//c\\\t$LinuxKernel\\t\/boot\/vmlinuz $BOOT_OPTION" $remasteringdir/boot/grub.new;
      sed -i "/$LinuxIMG.*\//c\\\t$LinuxIMG\\t\/boot\/initrfs.img" $remasteringdir/boot/grub.new;
    }

    [[ "$Type" == 'NoBoot' ]] && {
      sed -i "/$LinuxKernel.*\//c\\\t$LinuxKernel\\t\/vmlinuz $BOOT_OPTION" $remasteringdir/boot/grub.new;
      sed -i "/$LinuxIMG.*\//c\\\t$LinuxIMG\\t\/initrfs.img" $remasteringdir/boot/grub.new;
    }

    sed -i '$a\\n' $remasteringdir/boot/grub.new;

    # this is the install-stage efi dir filling which differs in the similar processing imagegen-stage (the one in ci2.sh),the gptNO should be judged in a more cleverer manner
    # [[ "$tmpBUILDGENE" == '1' ]] && cp -a /usr/lib/grub/x86_64-efi/* $remasteringdir/boot/EFI/boot/x86_64-efi
    # [[ "$tmpBUILDGENE" == '1' ]] && grub-mkimage -C xz -O x86_64-efi -o $remasteringdir/boot/grub/bootx64.efi -p "(hd0,gpt15)/grub" -d $remasteringdir/boot/EFI/boot/x86_64-efi part_msdos part_gpt exfat ext2 fat iso9660 btrfs lvm dm_nv mdraid09_be mdraid09 mdraid1x raid5rec raid6rec

    # [[ "$tmpBUILDGENE" == '1' ]] && cat >$remasteringdir/boot/grub/grub.cfg<<EOF
# redirect only the grub files to let two set of grub shedmas coexists
# search --label "ROM" --set root
# configfile (\$root)/grub/grubmain.cfg
# EOF

  fi


}

patchgrub(){

  GRUBPATCH='0';

  if [[ "$LoaderMode" == "0" && "$tmpBUILD" != "1" && "$tmpTARGETMODE" != '1' ]]; then
    [ -f '/etc/network/interfaces' ] || {
      echo "Error, Not found interfaces config.";
      exit 1;
    }

    sed -i ''${INSERTGRUB}'i\\n' $GRUBDIR/$GRUBFILE;
    sed -i ''${INSERTGRUB}'r '$remasteringdir'/boot/grub.new' $GRUBDIR/$GRUBFILE;

    sed -i 's/timeout_style=hidden/timeout_style=menu/g' $GRUBDIR/$GRUBFILE;
    sed -i 's/timeout=[0-9]*/timeout=30/g' $GRUBDIR/$GRUBFILE;

    [[ -f  $GRUBDIR/grubenv ]] && sed -i 's/saved_entry/#saved_entry/g' $GRUBDIR/grubenv;
  fi



}


function processbasics(){

  kernelimage=$topdir/p/21.get/debianbase/dists/buster/main/binary-amd64/deb/linux-image-4.19.0-14-amd64_4.19.171-2_amd64.deb
  mkdir -p $remasteringdir/initramfs/usr/bin $remasteringdir/initramfs/hehe0 $remasteringdir/01-core

  cd $remasteringdir/initramfs;
  CWD="$(pwd)"
  echo -en "[ \033[32m cd to ${CWD##*/} \033[0m ]"

  if [[ "$tmpTARGETMODE" != '1' ]]; then
    #echo -en " - busy unpacking tdlcore.tar.gz ..."
    tar zxf $topdir/$downdir/tdl/tdlcore$([[ "$tmpINSTEMBEDVNC" == '1' ]] && echo d).tar.gz -C . >>/dev/null 2>&1
  fi  


  #cp -aR $topdir/$downdir/tdl/debian-live ./lib >>/dev/null 2>&1
  #chmod +x ./lib/debian-live/*
  #cp -aR $topdir/$downdir/tdl/updates ./lib/modules/4.19.0-14-amd64 >>/dev/null 2>&1


}


preparepreseed(){


  cat >$topdir/$remasteringdir/initramfs/preseed.cfg<<EOF
d-i preseed/early_command string anna-install
#pass the lowmem note,but still it may have problems
d-i debian-installer/language string en
d-i debian-installer/country string US
d-i debian-installer/locale string en_US.UTF-8
d-i lowmem/low note
# $([[ "$tmpINSTEMBEDVNC" != '1' ]] && echo d-i debian-installer/framebuffer boolean false) is not needed,we also mentioned and moved it to bootcode before
d-i debian-installer/framebuffer boolean false
d-i console-setup/layoutcode string us
d-i keyboard-configuration/xkb-keymap string us
d-i hw-detect/load_firmware boolean true
d-i netcfg/choose_interface select $IFETH
d-i netcfg/disable_autoconfig boolean true
d-i netcfg/dhcp_failed note
d-i netcfg/dhcp_options select Configure network manually
# d-i netcfg/get_ipaddress string $custIPADDR
d-i netcfg/get_ipaddress string $IPv4
d-i netcfg/get_netmask string $MASK
d-i netcfg/get_gateway string $GATE
d-i netcfg/get_nameservers string 8.8.8.8
d-i netcfg/no_default_route boolean true
d-i netcfg/confirm_static boolean true
d-i mirror/country string manual
#d-i mirror/http/hostname string $IPv4
d-i mirror/http/hostname string $MIRROR
d-i mirror/http/directory string /_build/debianbase
d-i mirror/http/proxy string
d-i apt-setup/services-select multiselect
d-i debian-installer/allow_unauthenticated boolean true
d-i debian-installer/allow_unauthenticated_ssl boolean true
d-i passwd/root-login boolean ture
d-i passwd/make-user boolean false
d-i passwd/root-password-crypted password \$1\$8ASOKotc\$AlIunLy3WT1OjLI85ON7i0
d-i user-setup/allow-password-weak boolean true
d-i user-setup/encrypt-home boolean false
d-i clock-setup/utc boolean true
d-i time/zone string US/Eastern
d-i clock-setup/ntp boolean true
EOF


  [[ "$tmpTARGETMODE" == '0' && "$tmpTARGET" == 'deb' && "$tmpINSTWITHMANUAL" != '1' ]] && cat >>$topdir/$remasteringdir/initramfs/preseed.cfg<<EOF

d-i partman/early_command string chmod 755 /usr/lib/patchudebsonthefly/baseinstaller.sh /usr/lib/patchudebsonthefly/debootstrap.sh /usr/lib/patchudebsonthefly/apt-install.sh /usr/lib/patchudebsonthefly/pkgsel.sh;/usr/lib/patchudebsonthefly/baseinstaller.sh;/usr/lib/patchudebsonthefly/debootstrap.sh;/usr/lib/patchudebsonthefly/apt-install.sh;/usr/lib/patchudebsonthefly/pkgsel.sh;debconf-set partman-auto/disk "\$(list-devices disk | head -n1)"

d-i partman-auto/method string regular
d-i partman-auto/expert_recipe string boot-root :: \
    1 1 1     free  $primary{ } method{ biosgrub } $bios_boot{ } . \
    210 2 210 fat32 $primary{ } method{ efi }    format{ } $bootable{ } label{ ROM } mountpoint{ /boot/efi } . \
    1 9999 -1 ext4  $primary{ } method{ format } format{ } use_filesystem{ } filesystem{ ext4 } mountpoint{ / } .

d-i partman-basicfilesystems/no_swap boolean false
#d-i partman-basicmethods/method_only boolean false

#d-i partman-efi/non_efi_system boolean true
d-i partman-partitioning/choose_label string gpt
d-i partman-partitioning/default_label string gpt

d-i partman-md/device_remove_md boolean true
d-i partman-lvm/device_remove_lvm boolean true

d-i partman-partitioning/confirm_write_new_label boolean true
d-i partman/choose_partition select finish
d-i partman/confirm boolean true
d-i partman/confirm_nooverwrite boolean true

d-i base-installer/kernel/image string linux-image-4.19.0-14-amd64

tasksel tasksel/first multiselect minimal
d-i pkgsel/update-policy select none
d-i pkgsel/include string openssh-server
d-i pkgsel/upgrade select none

popularity-contest popularity-contest/participate boolean false

d-i grub-installer/only_debian boolean true
d-i grub-installer/bootdev string default
d-i grub-installer/force-efi-extra-removable boolean true

d-i finish-install/reboot_in_progress note
d-i debian-installer/exit/reboot boolean true
EOF


  # wget -qO- '$DDURL' |gunzip -dc |dd of=$(list-devices disk |head -n1)|(pv -s \$IMGSIZE -n) 2&>1|dialog --gauge "progress" 10 70 0

  # azure hd need bs=10M or it will fail
  [[ "$UNZIP" == '0' ]] && PIPECMDSTR='wget -qO- '$TARGETDDURL' |stdbuf -oL dd of=$(list-devices disk |head -n1) bs=10M 2> /run/some_log.log & pid=`expr $! + 0`;echo $pid';
  [[ "$UNZIP" == '1' && "$tmpTARGET" != 'onekeydevdesk' ]] && PIPECMDSTR='wget -qO- '$TARGETDDURL' |gunzip -dc |stdbuf -oL dd of=$(list-devices disk |head -n1) bs=10M 2> /run/some_log.log & pid=`expr $! + 0`;echo $pid';
  [[ "$UNZIP" == '2' ]] && PIPECMDSTR='wget -qO- '$TARGETDDURL' |tar zOx |stdbuf -oL dd of=$(list-devices disk |head -n1) bs=10M 2> /run/some_log.log & pid=`expr $! + 0`;echo $pid';
  [[ "$tmpTARGET" == 'onekeydevdesk' ]] && PIPECMDSTR='(for i in `seq -w 0 999`;do wget -qO- --no-check-certificate '$TARGETDDURL'_$i; done)|gunzip -dc |stdbuf -oL dd of=$(list-devices disk |head -n1) bs=10M 2> /run/some_log.log & pid=`expr $! + 0`;echo $pid';


  [[ "$tmpTARGETMODE" == '0' && "$tmpTARGET" != 'deb' && "$tmpINSTWITHMANUAL" != '1' ]] && cat >>$topdir/$remasteringdir/initramfs/preseed.cfg<<EOF
# kill -9 (ps |grep debian-util-shell | awk '{print 1}')
# debconf-set partman-auto/disk "\$(list-devices disk |head -n1)"
d-i partman/early_command string chmod 755 /usr/lib/ddprogress/longrunpipebgcmd_redirectermoniter.sh;/usr/lib/ddprogress/longrunpipebgcmd_redirectermoniter.sh '$PIPECMDSTR'
EOF


  ## srv,rever,target
  [[ "$tmpTARGETMODE" == '2' && "${tmpTARGET:0:11}" == '10000:/dev/' && "$tmpINSTWITHMANUAL" != '1' ]] && PIPECMDSTR='nc -l -p 10000|gunzip -dc|stdbuf -oL dd of='${tmpTARGET##10000:}' bs=10M 2> /run/some_log.log & pid=`expr $! + 0`;echo $pid' && cat >>$topdir/$remasteringdir/initramfs/preseed.cfg<<EOF
d-i partman/early_command string chmod 755 /usr/lib/ddprogress/longrunpipebgcmd_redirectermoniter.sh;/usr/lib/ddprogress/longrunpipebgcmd_redirectermoniter.sh '$PIPECMDSTR'
EOF

  ## cli,sender,src
  [[ "$tmpTARGETMODE" == '3' && "${tmpTARGET:8}" == ':10000' && "$tmpINSTWITHMANUAL" != '1' ]] && PIPECMDSTR='dd if='${tmpTARGET%%:10000}' bs=10M|gzip|nc '$IPv4' 10000 2> /run/some_log.log & pid=`expr $! + 0`;echo $pid' && cat >>$topdir/$remasteringdir/initramfs/preseed.cfg<<EOF
d-i partman/early_command string chmod 755 /usr/lib/ddprogress/longrunpipebgcmd_redirectermoniter.sh;/usr/lib/ddprogress/longrunpipebgcmd_redirectermoniter.sh '$PIPECMDSTR'
EOF

}


patchpreseed(){

  # buildmode, set auto net
  [[ "$setNet" == '0' || "$LoaderMode" != "0" || "$tmpTARGETMODE" == '1' ]] && echo -en "[ \033[32m auto dhcp mode \033[0m ]" || echo -en "[ \033[32m static mode \033[0m ]"

  [[ "$AutoNet" == '1' ]] && {
    sed -i '/netcfg\/disable_autoconfig/d' $topdir/$remasteringdir/initramfs/preseed.cfg
    sed -i '/netcfg\/dhcp_options/d' $topdir/$remasteringdir/initramfs/preseed.cfg
    sed -i '/netcfg\/get_.*/d' $topdir/$remasteringdir/initramfs/preseed.cfg
    sed -i '/netcfg\/confirm_static/d' $topdir/$remasteringdir/initramfs/preseed.cfg
  }

  #[[ "$GRUBPATCH" == '1' ]] && {
  #  sed -i 's/^d-i\ grub-installer\/bootdev\ string\ default//g' $topdir/$remasteringdir/initramfs/preseed.cfg
  #}
  #[[ "$GRUBPATCH" == '0' ]] && {
  #  sed -i 's/debconf-set\ grub-installer\/bootdev.*\"\;//g' $topdir/$remasteringdir/initramfs/preseed.cfg
  #}
  # vncserver need this?
  #[[ "$GRUBPATCH" == '0' ]] && {
  #  sed -i 's/debconf-set\ grub-installer\/bootdev.*\"\;//g' /tmp/boot/preseed.cfg
  #}

  sed -i '/user-setup\/allow-password-weak/d' $topdir/$remasteringdir/initramfs/preseed.cfg
  sed -i '/user-setup\/encrypt-home/d' $topdir/$remasteringdir/initramfs/preseed.cfg
  #sed -i '/pkgsel\/update-policy/d' $topdir/$remasteringdir/initramfs/preseed.cfg
  #sed -i 's/umount\ \/media.*true\;\ //g' $topdir/$remasteringdir/initramfs/preseed.cfg

}






# . p/999.utils/ci2.sh

# =================================================================
# Below are main routes
# =================================================================

export PATH=.:./tools:../tools:/usr/sbin:/usr/bin:/sbin:/bin:/
CWD="$(pwd)"
topdir=$CWD
cd $topdir
echo "Changing current directory to $CWD"

# dir settings
downdir='_tmpdown'
remasteringdir='_tmpremastering'
targetdir='_build'

if [[ $# -eq 0 ]]; then echo none args given,will force wgetdd instmode and use onekeydevdesk as target && tmpTARGETMODE='0' && tmpTARGET='onekeydevdesk'; fi

while [[ $# -ge 1 ]]; do
  case $1 in
    -n|--forcenetcfgstr)
      shift
      FORCENETCFGSTR="$1"
      [[ -n "$FORCENETCFGSTR" ]] && echo "netcfgstr forced to some value,will force setnet mode"
      shift
      ;;
    -m|--forcemirror)
      shift
      FORCEMIRROR="$1"
      [[ -n "$FORCEMIRROR" ]] && echo "mirror forced to some value,will override autoselectdebmirror results"
      shift
      ;;
    -b|--build)
      shift
      tmpBUILD="$1"
      #[[ "$tmpBUILD" == '2' ]] && echo "lxc given,will auto inform tmpBUILDCI and tmpBUILDREUSEPBIFS as 1,this is not by customs" && tmpBUILDCI='1' && tmpBUILDREUSEPBIFS='1' && tmpTARGETMODE='1' && echo -en "\n" && [[ -z "$tmpBUILDCI" ]] && echo "buildci were empty" && exit 1
      #[[ "$tmpBUILD" != '2' ]] && tmpBUILDCI='0' && tmpBUILDREUSEPBIFS='0' && tmpTARGETMODE='1'
      shift
      ;;
    -h|--host)
      shift
      tmpHOST="$1"
      case $tmpHOST in
        ''|spt|orc) tmpHOSTMODEL='0' ;;
        az) tmpHOSTMODEL='1' ;;
        sr) tmpHOSTMODEL='2' ;;
        ks|mbp) tmpHOSTMODEL='3' ;; # && [[ -z "$tmpHOSTMODEL" ]] && echo "hostmodel should be 3 but not set" && exit 1 ;;
        0*)

          for ht in `[[ "$tmpBUILDFORM" -ne '0' ]] && echo "${1##0}" |sed 's/,/\n/g' || echo "${1##0}" |sed 's/,/\'$'\n''/g'`
          do
            HOSTMODLIST+=",""${ht}"
          done
          [[ "$tmpHOST" == '0' ]] && tmpHOSTMODEL='0'
          [[ "$tmpHOST" =~ '0,' ]] && tmpHOSTMODEL='99' && echo "with host modules to be inc in:""$HOSTMODLIST"",will force hostmodel as 99" ;;

        *) echo "unknown host" && exit 1 ;;
      esac
      shift
      ;;

      # the targetmodel are auto deduced finally here (with hostmodel and tmptarget determined it)
      # for hostmodel,if -h are < 99,it must be in instmode and given as invidude,in buildmode = 99,it is always mixed with 0,and goes after it
    -t|--target)
      shift
      tmpTARGET="$1"
      case $tmpTARGET in
        '') tmpTARGETMODE='0' && tmpTARGET='onekeydevdesk' && echo "target not defined,will force wgetdd instmode and onekeydevdesk target" ;;
        debianbase|tdl) tmpTARGETMODE='1' ;;
        deb) tmpTARGETMODE='0' && echo "deb given,will force wgetdd instmode and debian10 target" ;;
        lxcdeepin|lxccloudrevebox|lxccodeserverbox) tmpTARGETMODE='1';GENCONTAINERS="$1";PACKCONTAINERS="$1";echo "standalone lxc pack mode without building initfs and 01-core" ;;
        dsm61715284|win11|osx10146) tmpTARGETMODE='0' ;;
        onekeydevdesk*)

          for tgt in `[[ "$tmpBUILDFORM" -ne '0' ]] && echo "${1##onekeydevdesk}" |sed 's/,/\n/g' || echo "${1##onekeydevdesk}" |sed 's/,/\'$'\n''/g'`
          do
          [[ $tgt =~ "++" ]] && { GENCONTAINERS+=",""${tgt##++}";PACKCONTAINERS+=",""${tgt##++}"; } || GENCONTAINERS+=",""${tgt##+}"
          done
          [[ "$tmpHOSTMODEL" -lt '99' && "$tmpTARGET" == 'onekeydevdesk' ]] && tmpTARGETMODE='0' && echo "wgetdd instonly mode detected"
          [[ "$tmpHOSTMODEL" == '99' && "$tmpTARGET" == 'onekeydevdesk' ]] && tmpTARGETMODE='1' && echo "fullgen mode detected"
          [[ "$tmpHOSTMODEL" == '99' && "$tmpTARGET" =~ 'onekeydevdesk,' ]] && tmpTARGETMODE='1' && echo "fullgen mode detected,with lxc merge/pack addons:""$GENCONTAINERS" ;;
          #[[ "$tmpHOST" != '2' && "$tmpTARGET" == 'onekeydevdesk' ]] && tmpTARGETMODE=1 || tmpTARGETMODE='0' ;;

        *) echo "$tmpTARGET" |grep -q '^http://\|^ftp://\|^https://\|^10000:/dev/\|^/dev/';[[ $? -ne '0' ]] && echo "targetname not known or in blank" && exit 1 || { 
          echo "$tmpTARGET" |grep -q '^http://\|^ftp://\|^https://';[[ $? -eq '0' ]] && echo "raw urls detected,will override autotargetddurl results and force wgetdd instmode" && tmpTARGETMODE=0;echo "$tmpTARGET" |grep -q '^10000:/dev/';[[ $? -eq '0' ]] && echo "port:blkdevname detected,will force ncsrv,rever+dd instmode" && tmpTARGETMODE=2;echo "$tmpTARGET" |grep -q '^/dev/';[[ $? -eq '0' ]] && echo "port:ip:blkdevname detected,will force nccli,sender+dd instmode" && tmpTARGETMODE=3; } ;;
      esac
      shift
      ;;
    -s|--serial)
      shift
      tmpINSTSERIAL="$1"
      [[ "$tmpINSTSERIAL" == '1' ]] && echo "serial forced,will process serial console after booting"
      shift
      ;;
    -g|--gene)
      shift
      tmpBUILDGENE="$1"
      [[ "$tmpBUILDGENE" == '1' || "$tmpBUILDGENE" == '' ]] && echo "biosgpt forced,will process efi booting"
      shift
      ;;
    -d|--debug)
      shift
      tmpBUILDDEBUG="$1"
      [[ ("$tmpBUILDDEBUG" == '1' || "$tmpBUILDDEBUG" == '') && "$tmpTARGETMODE" != '1' ]] && tmpTARGET='dummy' && tmpINSTEMBEDVNC='1' && tmpINSTWITHMANUAL='1' && echo "debug supports enabled in instmode,will force target as dummy, and force embeding a vncserver + manual stop"
      [[ ("$tmpBUILDDEBUG" == '1' || "$tmpBUILDDEBUG" == '') && "$tmpTARGETMODE" == '1' ]] && tmpINSTEMBEDVNC='1' && tmpINSTWITHMANUAL='1' && echo "debug supports enabled in buildmode,will keep target as its, and force embeding a vncserver + manual stop"
      shift
      ;;
    --help|*)
      if [[ "$1" != 'error' ]]; then echo -ne "\nInvaild option: '$1'\n\n"; fi
      echo -ne "Usage(args are self explained):\n\t-m/--forcemirror\n\t-n/--forcenetcfgstr\n\t-b/--build\n\t-h/--host\n\t-t/--target\n\t-s/--serial\n\t-g/--gene\n\t-d/--debug\n\n"
      exit 1;
      ;;
    esac
  done

#clear

echo -e "\n \033[36m # Checking Prerequisites: \033[0m"

echo -en "\n - Checking deps: ......"
if [[ "$tmpTARGET" == 'debianbase' && "$tmpTARGETMODE" == '1' ]]; then
  CheckDependence sudo,wget,ar,awk,grep,sed,cut,cat,cpio,curl,gzip,find,dirname,basename,xzcat,zcat,md5sum,sha1sum,sha256sum;
elif [[ "$tmpTARGET" == 'onekeydevdesk' && "$tmpTARGETMODE" == '1' && "$tmpBUILD" == '1' ]] ; then
  CheckDependence sudo,wget,ar,awk,grep,sed,cut,cat,cpio,curl,gzip,find,dirname,basename,xzcat,zcat,diskutil;
else
  CheckDependence sudo,wget,ar,awk,grep,sed,cut,cat,cpio,curl,gzip,find,dirname,basename,xzcat,zcat;
fi

echo -en "\n - Selecting Mirrors and Targets from/embededinto: ......" 

AUTOMIRROR=`echo -e $(SelectDEBMirror $autoDEBMIRROR0 $autoDEBMIRROR1)|sort -n -k 2 | head -n2 | grep http | sed  -e 's#[[:space:]].*##'`
[[ -n "$AUTOMIRROR" && -z "$FORCEMIRROR" ]] && MIRROR=$AUTOMIRROR && echo -en "[ \033[32m ${MIRROR} \033[0m ]"  # || exit 1
[[ -n "$AUTOMIRROR" && -n "$FORCEMIRROR" ]] && MIRROR=$FORCEMIRROR && echo -en "[ \033[32m ${MIRROR} \033[0m ]"  # || exit 1

UNZIP=''
IMGSIZE=''
case $tmpTARGET in
  dummy|debianbase|tdl|deb) TARGETDDURL=''
    TARGETDDIMGSIZE='' ;;
  onekeydevdesk) TARGETDDURL=$MIRROR/_build/onekeydevdesk/onekeydevdesk
    [[ "$tmpTARGETMODE" == '0' ]] && CheckTarget $TARGETDDURL
    [[ -n "$IMGSIZE" && -z "$FORCEMIRRORIMGSIZE" ]] && TARGETDDIMGSIZE=$IMGSIZE
    [[ -n "$IMGSIZE" && -n "$FORCEMIRRORIMGSIZE" ]] && TARGETDDIMGSIZE=$FORCEMIRRORIMGSIZE ;;
  dsm61715284|win11|osx10146) TARGETDDURL=$MIRROR/$tmpTARGET".gz"
    [[ "$tmpTARGETMODE" == '0' ]] && CheckTarget $TARGETDDURL
    [[ -n "$IMGSIZE" && -z "$FORCEMIRRORIMGSIZE" ]] && TARGETDDIMGSIZE=$IMGSIZE
    [[ -n "$IMGSIZE" && -n "$FORCEMIRRORIMGSIZE" ]] && TARGETDDIMGSIZE=$FORCEMIRRORIMGSIZE ;;
  *) TARGETDDURL=$tmpTARGET
    # wedont check "$tmpTARGETMODE" == '1'
    [[ "$tmpTARGETMODE" != '1' ]] && CheckTarget $TARGETDDURL
    [[ -n "$IMGSIZE" && -z "$FORCEMIRRORIMGSIZE" ]] && TARGETDDIMGSIZE=$IMGSIZE
    [[ -n "$IMGSIZE" && -n "$FORCEMIRRORIMGSIZE" ]] && TARGETDDIMGSIZE=$FORCEMIRRORIMGSIZE ;;
esac

sleep 2s

echo -e "\n\n \033[36m # Parepare Res: \033[0m"

# under GENMODE we reuse the downdir,but not for INSTMODE
[[ "$tmpTARGETMODE" != '1' ]] && [[ -d $downdir ]] && rm -rf $downdir;
mkdir -p $downdir $downdir/tdl

sleep 2s && echo -en "\n - Get linux-image and initrfs-tarball,please wait: ......"
[[ "$tmpTARGETMODE" != '1' ]] && getbasics down && echo -en "[ \033[32m inst mode,down!! \033[0m ]" || getbasics copy && echo -en "[ \033[32m gen mode,copy!! \033[0m ]"
echo -en "\n - Get optional/necessary deb pkg files to build a debianbase: ...... "
[[ "$tmpBUILD" != '1' && "$tmpTARGET" == 'debianbase' ]] && getoptpkgs libc,common,wgetssl,extendhd,ddprogress || echo -en "[ \033[32m not debianbase,skipping!! \033[0m ]"
echo -en "\n - Get full debs pkg files to build a debianbase: ..... "
[[ "$tmpBUILD" != '1' && "$tmpTARGET" == 'debianbase' ]] && getfullpkgs || echo -en "[ \033[32m not debianbase,skipping!! \033[0m ]"


echo -e "\n\n \033[36m # Remastering all up... \033[0m"

# lsattr and cont delete,then you shoud restart
umount --force $remasteringdir/initramfs/{dev/pts,dev,proc,sys} >/dev/null 2>&1
umount --force $remasteringdir/01-core/initrd/{dev/pts,dev,proc,sys} >/dev/null 2>&1
[[ -d $remasteringdir ]] && rm -rf $remasteringdir;

sleep 2s && echo -en "\n - save and set the netcfg: ......"

interface=''

[[ "$tmpBUILD" != '1' && "$tmpTARGET" != 'debianbase' ]] && parsenetcfg || echo -en "[ \033[32m auto mode!! \033[0m ]"


sleep 2s && echo -en "\n - processing grub: ......"

LoaderMode='0'
setInterfaceName='0'
setIPv6='0'

[[ "$tmpBUILD" != '1' && "$tmpTARGETMODE" != '1' && "$tmpTARGET" != 'debianbase' ]] && parsegrub && sleep 2s && echo -en "[ \033[32m $remasteringdir/boot/grub.new \033[0m ]"
[[ "$tmpTARGETMODE" == '1' ]] && [[ "$tmpTARGET" == "onekeydevdesk" ]] && preparegrub && sleep 2s && echo -en "[ \033[32m prepare $remasteringdir/boot/* \033[0m ]"
    
# cp the efi files for inst ci mode
# we need determine the target machine's efi partition like below,but we just mkdir a efi here and use hd0,gpt15 instead
# [ -e /boot/grub/grub.cfg ] && df -P /boot/grub/grub.cfg  | awk '/^\/dev/ {print $1}' || echo "not found"
# [[ "$tmpBUILDGENE" == '1' ]] && mkdir -p /EFI/boot && cp -a --no-preserve=all $remasteringdir/boot/EFI/boot/{bootx64.efi,x86_64-efi} /EFI/boot



[[ "$tmpINSTWITHVNC" == '0' ]] && {

  patchgrub
  sleep 2s && echo -en "\n - unpacking linux-image and initrfs tar-ball: ......"
  processbasics

  [[ "$tmpTARGETMODE" != '1' || "$tmpTARGETMODE" == '1' && "$tmpBUILDREUSEPBIFS" == '0' ]] && {

    if [[ "$tmpTARGETMODE" != '1' ]]; then

      sleep 2s && echo -en "\n - instmode,perform below instmodeonly remastering tasks: ......"

      sleep 2s && echo -en "\n - make and patch /preseed: ......."
      preparepreseed
      patchpreseed

      cd $topdir/$remasteringdir/initramfs
      CWD="$(pwd)"
      echo -en "[ \033[32m cd to ${CWD##*/} \033[0m ]"    
      KERNEL=4.19.0-14-amd64
      LMK="lib/modules/$KERNEL"

    fi


  }


  echo -e "\n\n \033[36m # finishing... \033[0m"

  # rewind the $(pwd)
  cd $topdir
  mkdir -p $targetdir


  echo -en "\n - copying vmlinuz to the target/mnt: ......"
  [[ -d /boot ]] && [[ "$tmpBUILD" != "1" ]] && [[ "$tmpTARGETMODE" != "1" ]] && cp -v -f $topdir/$downdir/tdl/vmlinuz /boot/vmlinuz


  # now we can safetly del the hehe0,no use anymore (both in genmod+instmod or instonlymode)
  [[ "$tmpBUILDREUSEPBIFS" == '0' ]] && rm -rf $topdir/$remasteringdir/initramfs/hehe0


  [[ "$tmpTARGETMODE" != '1' ]] && sleep 2s && echo -en "\n - packaging initrfs to the target/mnt: ....." && [[ "$tmpBUILD" != '1' ]] && ( cd $topdir/$remasteringdir/initramfs; find . | cpio -H newc --create --quiet | gzip -9 > /boot/initrfs.img ) # || ( cd $topdir/$remasteringdir/initramfs; find . | cpio -H rpax --create --quiet | gzip -9 > /Volumes/TMPVOL/initrfs.img )


  #rm -rf $remasteringdir/initramfs;

}


# for manualvnc debug mode
[[ "$tmpINSTEMBEDVNC" == '1' && "$tmpINSTWITHMANUAL" == '1' ]] && {
  echo -e "\n \033[33m \033[04m It will reboot! \nPlease connect VNC! \n \033[04m\n\n \033[31m \033[04m There is some information for you.\nDO NOT CLOSE THE WINDOW! \033[0m\n"
  echo -e "\033[36m \033[04m use a vnccleint to connect to $IPv4:5900 \033[0m to reach the embeded vnc server \033[0m \n\n"

  read -n 1 -p "Press Enter to reboot..." INP
  [[ "$INP" != '' ]] && echo -ne '\b \n\n';
}

chown root:root $GRUBDIR/$GRUBFILE
chmod 444 $GRUBDIR/$GRUBFILE


if [[ "$LoaderMode" == "0" ]]; then
  echo -en "\n - packaging finished,and all done! auto rebooting after 20s" && sleep 20s && clear && reboot >/dev/null 2>&1
else
  rm -rf "$HOME/loader"
  mkdir -p "$HOME/loader"
  cp -rf "/boot/initrfs.img" "$HOME/loader/initrfs.img"
  cp -rf "/boot/vmlinuz" "$HOME/loader/vmlinuz"
  [[ -f "/boot/initrfs.img" ]] && rm -rf "/boot/initrfs.img"
  [[ -f "/boot/vmlinuz" ]] && rm -rf "/boot/vmlinuz"
  echo && ls -AR1 "$HOME/loader"
fi
