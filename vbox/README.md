VBox Network
------------

### NAT (Default)

VM is invisible and unreachable from the outside internet; you cannot run a server this way unless you set up port forwarding

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

#### Think about the vftp option for a net boot 