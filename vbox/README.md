The Scripts to generate the ViritualBox VMs automaticly and do some required pro-install.

* Support Both Linux and Windows Host (in Windows Host, need MingW installed)
* Linux Guest use PXELinux and Tftp boot by Using offical ISOs
* Windows Guest use preinstalled VHD file (which provided by mircosoft offically)


| MD5                                | File           | Desc                          |
| ---------------------------------- | -----------    | -----------------------       |
| `1547d2737359fb61ac8346057a735649` | nc.exe         | Personal Build [See][nc] |    |
| `814d1cfd88ca49037cd15680178d1afd` | tftpd32.exe    | 32 version 4.5, seed up FXE/tftp Boot for VBox, the VBox default serivce is too slow to boot in windows host. [From tftpd32 offical site][tftp32] |
| `fe3513a04a8ee48d62f682bb699ed371` | devio.exe      | Version 3.02, use to mount VHD file in Windows Host [From ltr-data.se][devio]|
| `12ccdc652b30c6d1e307c6f7deff5d24` | pcbios.bin     | [From VMLite][pcbios] |


[nc]: TODO
[tftp32]:http://tftpd32.jounin.net/download/tftpd32.450.zip
[devio]:http://www.ltr-data.se/files/devio.exe
[pcbios]:http://www.vmlite.com/images/fbfiles/files/pcbios.zip

XP Mode for Window 7
--------------------

_Windows XP Mode provides a 32-bit virtual Windows XP Professional Service Pack 3 (SP3) environment. This download includes a virtual hard disk (.vhd file) with Windows XP SP3 preinstalled._ 

See More details from [Microsoft offical page](http://www.microsoft.com/en-us/download/details.aspx?id=8002)


* Ver : 1.3.7600.16423
* Date: 10/19/2009

* Name: WindowsXPMode_en-us.exe

  * Down: http://download.microsoft.com/download/7/2/C/72C7BAB7-2F32-4530-878A-292C20E1845A/WindowsXPMode_en-us.exe
  * Size: 469.8 MB

* Name: WindowsXPMode_N_en-us.exe

  * Down: http://download.microsoft.com/download/7/2/C/72C7BAB7-2F32-4530-878A-292C20E1845A/WindowsXPMode_N_en-us.exe
  * Size: 449.0 MB
  * MD5 : 0819059e445efb676e04bd22b3aade3c

Notes About XP Mode EULA:
-------------------------

While a virtual machine created by XP Mode VHD file should also run under OS X and Linux, but running under anything but Windows 7 Professional, Enterprise, or Ultimate would apparently *violate the Windows XP Mode EULA*:

_... You may install, use, access, display and run one copy of the Software in a single virtual machine on a single computer, such as a workstation, terminal or other device ("Workstation Computer"), that contains a licensed copy of Windows 7 Professional, Enterprise or Ultimate edition. Virtualization software is required to use the Software on the Workstation Computer ... 1.2  Activation.  If you are using the Software with a properly licensed copy of Windows 7 Professional, Enterprise or Ultimate, activation of the Software is not required._

So according to the EULA, If You want to use XP mode in a Linux or OSX, the activation of XP Mode is required. And in one Host, only one XP mode VM 
to run in the same time.

VBox Network
------------

### NAT (Default)

VM is invisible and unreachable from the outside internet; you cannot run a server this way unless you set up port forwarding

The network frames sent out by the guest operating system are received by VirtualBox's NAT engine, which extracts the TCP/IP data and resends it using the host operating system. To an application on the host, or to another computer on the same network as the host, it looks like the data was sent by the VirtualBox application on the host, using an IP address belonging to the host. VirtualBox listens for replies to the packages sent, and repacks and resends them to the guest machine on its private network.

Host Network <-> Host (IP) <-> VBox NAT engine <-> Guest (IP)

Details : (http://www.virtualbox.org/manual/ch09.html#changenat)
  *  In NAT mode, the guest network interface is assigned to the IPv4 range 10.0.x.0/24 by default where x corresponds to the instance of the NAT interface +2. (aka. the first card is connected to 10.0.2.0, the second to the network 10.0.3.0 and so on) 
  *  the guest is assigned to the address 10.0.2.15, the gateway 10.0.2.2,  name server 10.0.2.3

```
route -n
netstat -rn
ip route show
```

Set up  a port forwarding
```
VBoxManage list vms
VBoxManage controlvm "VM name" poweroff
VBoxManage modifyvm "VM name" --natpf1 "guestssh,tcp,,2222,,22"
VBoxManage startvm "VM name"
```

So here is 4 ips in a guest's view:
10.0.2.2  : the gateway, aka. the host ip
10.0.2.3  : the dns server, aka. the host ip
10.0.2.4  : built-in TFTP server, aka, the host ip
10.0.2.15 : guest(myself) ip by default

### NAT Network (4.3 above feature)

* guest can access host network
* guest can access each other (the NAT network defined)
* host can't access guest directly (need to add a port forward)

#### Create NAT network

`VBoxManage natnetwork add -t nat-int-network -n "192.168.15.0/24" -e -h on`
`-t --natname -n --network -e --enable -h --dhcp`

Comand above will create a NAT network named `nat-int-network`, the network range `192.168.15.0/255.255.255.0`
The gateway is `192.168.15.1`, and enabled the NAT network and turn on the DHCP.

#### Start NAT network

`VBoxManage natnetwork start -t nat-int-network`

After the NAt network is started, two process is started in background . (VBoxNetDHCP.exe and VBoxNetNAT.exe in Windows Platform)


### host-only network

* host can access guest network ( by the addtional network adpater created in host)
* guset access each other (using the host adapter as gatework)
* guest CANNOT access outside (add a additional guest network adapter, for exmaple, the default NAT)





#### Think about the vftp option for a net boot 