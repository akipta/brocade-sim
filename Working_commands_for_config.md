The following commands can be used in the running config (and can be written via write memory);

Enable level
  * boot system flash pri/sec
  * Config terminal
  * show

Config level
  * arp 'ip' 'mac' inspection
  * aggregated-vlan command
  * boot system flash pri/sec
  * cdp run
  * console timeout
  * cpu-limit addr-msgs command
  * fdp run
  * hostname
  * interface ethernet {num/num]
  * jumbo command
  * lldp run
  * logging consoel
  * logging host
  * logging persistence
  * router rip
  * router vrrp
  * snmp-server host
  * snmp-server location
  * sntp server
  * sntp poll-interval
  * show
  * username xxx password yyy
  * write memory

Interface level
  * spanning-tree root-protect
  * stp-bpdu-guard
  * port-name
  * enable/disable of interface port

VLAN level
  * tag ethernet slot/port
  * untag ethernet slot/port

The no commands for the same as well.