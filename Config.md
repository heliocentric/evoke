## kenv variables ##

| variable		| description									|
|:----------|:--------------------|
| evoke.fingerprint	| sha256 hash of the root filesystem.						|
| evoke.trackfile	| Trackfile device node for the release.					|
| evoke.moused		| If 'yes', run moused.							|
| evoke.version	| Version of the evoke release we are running.					|
| evoke.sysconfig	| The UUID of the sysconfig partitions.					|
| evoke.ntpd	| If 'no', disable ntpd				|
| evoke.userconfig	| The UUID of the auto-logged in user.						|
| evoke.sshkey		| SSH public key (warning, do not use in an untrusted pxeboot environment).	|
| evoke.useonly	| If there is only one sysconfig or userconfig to specify, use that.		|
| evoke.synclocal	| Sync the local disks to the evoke version we are running, if we are booting from a boot server.		|
| evoke.autoactivate	| Automatically activate a version if installed by either the local sync, or pushed from a network host with the privileges to do so. |
| evoke.monitor	| If 'yes'. enable the monitoring daemon (ganglia).				|
| boot.netif.name	| Interface to set the static ip address on.					|
| boot.netif.ip	| Static IP address.								|
| boot.netif.netmask	| Netmask for static IP address.						|
| boot.netif.gateway	| Gateway for static IP address.						|
| boot.netif.dns	| DNS Server to use.								|
| dhcp.tz.pcode	| Timezone PCode,  ex. EST5EDT.						|
| dhcp.tz-tcode	| Timezone TCode, ex. America/New\_York.					|

## DHCP options ##

| variable		| value		| description							|
|:----------|:-------|:------------------|
| option-100		| Timezone PCode	| ex. EST5EDT.							|
| option-101		| Timezone TCode	| ex. America/New\_York.					|
| ip-forwarding	| Bool			| 'true' if the host should forward packets.			|
| ntp-servers		| IP list		| list of ntp servers, the order is precendence		|