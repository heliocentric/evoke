# Target Environment #

This is a description of the target environment of evoke. While we may not be able to implement it, we should not
do anything to prevent it's implementation.


## Boot Server ##

Contains a 'typical' evoke installation. This includes a 500MB->1GB boot filesystem, a 2MB sysconfig partition, a 4k entropy partition, a nice sized swap partition, and a datastore partition.

It boots off of the boot filesystem, reads the sysconfig partition to get it's configuration information, reads in the entropy, and then uses the sysconfig's configuration and starts a dhcpd and tftpd to provide pxe boot functionality, or it's equivalent in other architectures. The tftpd exports the boot filesystem verbatim.

Key features are:

  * It boots off of the same drive that tftp then serves out for pxe functionality.
  * All configuration is kept in a seperate sysconfig partition/drive/etc.
  * The version of evoke the boot server boots is determined by it's boot.config.
  * The version of evoke the clients boot is determined by the dhcp configuration, so the version can be host or network specific.

In this way there is one namespace for the evoke binaries, which can then be safely replicated.

## Installing New Hosts ##

Installing a new host should be as simple as enabling DHCP boot services, and uploading the boot server's public key into the firmware. This step is necessary to ensure that the boot code recieved by the dhcp server is signed and verified as being legitimate.

## Public Terminals ##

Public terminals on evoke are more independent then classical thin terminals. While they boot off the network, they do contain disks. These disks tend to contain an  entropy partition, and a swap partition containing the rest of the space. They are stuck with getting bootcode from the network, and they use encrypted swap.

They are restricted to netbooting only, and use of the public key for the bootserver to prevent malicious use. (Though if the bootcode signing could possibly work on disk booting, then they could support a boot filesystem as a fallback)

## Private Terminals ##

A physically secured workstation will most likely netboot primarily, but contain a boot filesystem as a fallback. Both a workstation and a laptop will also contain entropy, swap, and encrypted datastores. The sysconfig partition for both will be contained on a thumbdrive carried by the user, and in the case of a laptop, the boot filesystem will also be on the thumb drive (optimally, this should be the primary boot method for a workstation, but it may not).

## Services ##

A machine providing a service (ie, a server) will typically contain a boot filesystem, a sysconfig partition, entropy, and an unencrypted datastore. They will netboot primarily, and fallback to the bootfilesystem. They are configured to use a specific sysconfig partition, just like the boot server. In fact, the only difference between a boot server and a normal service is that a boot server /always/ boots off it's own disk, while a service will attempt to use the boot server.

## Upgrading/Updating ##

New versions of evoke are merely copied to the boot server. When a machine needs to be upgraded/updated, the dhcp config is changed to point to a more recent version, or boot.config for hard drive installs. 'Upgrades' do not exist in the classical sense. You merely activate the version to be used at boot.

## Switching architectures and kernels ##

Switching to an architecture, or a new kernel abi (Ie, from FreeBSD 6.3 i386 to Linux 2.6 amd64) is the same as upgrading, you just activate the abi and architecture for the next boot. Each release supports multiple targets.