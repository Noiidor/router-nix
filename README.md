This is configuration of my NixOS-based router. Yes, im actually using this 24/7.  
It runs on a standart chinese mini-PC, my machine have 2 network ports, one for WAN and other for LAN.  
Im using systemd-networkd for stability reasons...supposedly, [Blocky](https://github.com/0xERR0R/blocky) as a local DNS-proxy and [Kea](https://github.com/isc-projects/kea) as DHCP-server.  
There is a lot of useful telemetry collected by Prometheus which can be viewed in predefined Grafana dashboards.  
My configuration tries to be as simple as possible while getting the job done. 
This is actually reasonable way to manage your router setup, comparable to solutions like OpenWRT and OPNsense.
Altrought there is more manual work and understanding required, but it grants full control of the system(perfect for control-freaks).
  
# TODO
- Proper IPv6 support
