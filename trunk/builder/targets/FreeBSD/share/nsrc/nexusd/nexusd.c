/*
# Copyright 2007-2009 Dylan Cochran
# All rights reserved
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted providing that the following conditions
# are met:
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
# IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY
# DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
# OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
# HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
# STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING
# IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.

# $Id$

*/
#include <sys/param.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <sys/rtprio.h>
#include <sys/watchdog.h>
#include <fcntl.h>
#include <libutil.h>
#include <stdio.h>
#include <unistd.h>
#include <syslog.h>
#include <stdarg.h>
#include <string.h>
#include <sys/mount.h>
#include <sys/uio.h>
#include <signal.h>
#include <sha256.h>
#include <kenv.h>
#include <stdlib.h>
#include <sys/reboot.h>
#include <errno.h>

#define HEX_DIGEST_LENGTH 65	

typedef int handle;

int main(int argc, char *argv[], char *envp[]);

int setctty(const char *);

int fmount(const char *fstype, const char *sourcepath, const char *destpath, int flags);

int realmain(int mode);

int checkhash(void);

int startpowerd(pid_t * powerdpid);

int startwatchdogd(pid_t * watchdogdpid);
int watchdoginit(int * fd);
int watchdogpat(int fd, u_int timeout);

int startdevd(pid_t * devdpid);

int startsystem(pid_t * systartpid, int mode);

handle acquire(const char * domain, const char * path, int type);
int release(handle lockid);

#define SYSTART "/system/share/bin/systart"
#define SYSTOP "/system/share/bin/systop"

#define SINGLEUSER 1
#define MULTIUSER 5


#define BINPATH "/system/%%ABI%%/%%ARCH%%/bin"
#define SHPATH "/system/%%ABI%%/%%ARCH%%/bin/sh"
#define TCSHPATH "/system/%%ABI%%/%%ARCH%%/bin/tcsh"
#define LIBPATH "/system/%%ABI%%/%%ARCH%%/lib"
#define LIBEXECPATH "/system/%%ABI%%/%%ARCH%%/libexec"
#define BOOTPATH "/system/%%ABI%%/%%ARCH%%/boot"


#define LOCK_NULL 0
#define LOCK_CONCURRENT_READ 1
#define LOCK_PROTECTED_READ 2
#define LOCK_CONCURRENT_WRITE 3
#define LOCK_PROTECTED_WRITE 4
#define LOCK_EXCLUSIVE 5
 

int main(int argc, char *argv[], char *envp[]) {


	int mode = MULTIUSER;
	int ret;
	char c;

	while ((c = getopt(argc, argv, "s")) != -1) {
		switch (c) {
			case 's':
				mode = SINGLEUSER;
			break;
		}
	}
	ret = realmain(mode);
	/* How the hell did we get here? */
	return (ret);
}

int realmain(int mode) {
	int ret;
	if (getpid() == 1) {
		struct sigaction init_handler;
		sigemptyset(&init_handler.sa_mask);
		init_handler.sa_flags = 0;
		init_handler.sa_handler = SIG_IGN;
		sigaction(SIGTSTP, &init_handler, (struct sigaction *)0);
		sigaction(SIGSYS, &init_handler, (struct sigaction *)0);
		sigaction(SIGABRT, &init_handler, (struct sigaction *)0);
		sigaction(SIGFPE, &init_handler, (struct sigaction *)0);
		sigaction(SIGILL, &init_handler, (struct sigaction *)0);
		sigaction(SIGSEGV, &init_handler, (struct sigaction *)0);
		sigaction(SIGBUS, &init_handler, (struct sigaction *)0);
		sigaction(SIGALRM, &init_handler, (struct sigaction *)0);
		sigaction(SIGXCPU, &init_handler, (struct sigaction *)0);
		sigaction(SIGXFSZ, &init_handler, (struct sigaction *)0);
		sigaction(SIGHUP, &init_handler, (struct sigaction *)0);
		sigaction(SIGINT, &init_handler, (struct sigaction *)0);
		sigaction(SIGTERM, &init_handler, (struct sigaction *)0);
		sigaction(SIGUSR1, &init_handler, (struct sigaction *)0);
		sigaction(SIGUSR2, &init_handler, (struct sigaction *)0);
		sigprocmask(SIG_SETMASK, &init_handler.sa_mask, (sigset_t *) 0);

		close(0);
		close(1);
		close(2);

		setctty("/dev/console");


		/* Set some important environment variables */
		setenv("EVOKE_SYSTEM_OS", "FreeBSD", 1);
		setenv("EVOKE_SYSTEM_ABI", "%%ABI%%", 1);
		setenv("EVOKE_SYSTEM_ARCH", "%%ARCH%%", 1);
		setenv("TERM", "cons25", 1);
		setenv("DEVICES", "/dev", 1);
		setenv("DISPLAY", ":-0", 1);
		setenv("PATH", "/bin", 1);


		printf("Verifying root filesystem\n");
		ret = checkhash();
		if (ret != 0) {
			return (ret);
		}

                openlog("init", LOG_CONS|LOG_ODELAY, LOG_AUTH);

		if (setlogin("root") < 0) {
			return 2;
		}



		printf("Merging directories\n");
		fmount("nullfs", BINPATH, "/bin", MNT_NOATIME|MNT_RDONLY|MNT_UNION);
		fmount("nullfs", LIBPATH, "/lib", MNT_NOATIME|MNT_RDONLY|MNT_UNION);
		fmount("nullfs", LIBEXECPATH, "/libexec", MNT_NOATIME|MNT_RDONLY|MNT_UNION);
		fmount("nullfs", BOOTPATH, "/boot", MNT_NOATIME|MNT_RDONLY|MNT_UNION);
		fmount("nullfs", "/system/share/bin", "/bin", MNT_NOATIME|MNT_RDONLY|MNT_UNION);
		fmount("nullfs", "/system/share/lib", "/config", MNT_NOATIME|MNT_RDONLY|MNT_UNION);


		printf("Starting the watchdog timer daemon\n");
		pid_t watchdogd_pid;
		startwatchdogd(&watchdogd_pid);

		printf("Starting the power manager daemon\n");
		pid_t powerd_pid;
		startpowerd(&powerd_pid);

		printf("Starting the device manager daemon\n");
		pid_t devd_pid;
		startdevd(&devd_pid);

		pid_t systart_pid;
		startsystem(&systart_pid, mode);

		printf("process %d has left the building\n", getpid());
		reboot(RB_AUTOBOOT);
	} 
	return 0;
}

int checkhash() {
	char buffer[HEX_DIGEST_LENGTH];
	char *realhash;
	char storedhash[HEX_DIGEST_LENGTH];
	int ret;
	handle devicelock;

	devicelock = acquire("hostfs", "/dev/md0", LOCK_PROTECTED_READ);
	if (devicelock != -1) {
		realhash = SHA256_File("/dev/md0", buffer);
		release(devicelock);

		if (!realhash) {
			return 3;
		} else {
		        ret = kenv(KENV_GET, "evoke.fingerprint", storedhash, sizeof(storedhash));
			if (ret == -1) {
				return (ret);
			} else {
				if (storedhash[64] != '\0') {
					return 4;
				} else {
					if (strncmp(realhash, storedhash, 64) == 0) {
						return 0;
					} else {
						return 5;
					}
				}
			}
		}
	} else {
		return 6;
	}
}

int setctty(const char *name) {
        int fd;
	handle devicelock;

	devicelock = acquire("hostfs", name, LOCK_CONCURRENT_WRITE);

	if (devicelock != -1) {

	        revoke(name);

	        if ((fd = open(name, O_RDWR)) == -1) {
	                return 1;
	        }

	        if (login_tty(fd) == -1) {
	                return 1;
	        } else {
			return 0;
		}
	} else {
 		return 2;
	}
}

int fmount(const char *fstype, const char *sourcepath, const char *destpath, int flags) {
	struct iovec iov[4];

	char _fstype[] = "fstype";
	char _fspath[] = "fspath";

	iov[0].iov_base = strdup(_fstype);
	iov[0].iov_len = strlen(_fstype) + 1;

	iov[1].iov_base = strdup(fstype);
	iov[1].iov_len = strlen(fstype) + 1;

	iov[2].iov_base = strdup(_fspath);
	iov[2].iov_len = strlen(_fspath) + 1;

	iov[3].iov_base = strdup(destpath);
	iov[3].iov_len = strlen(destpath) + 1;

	if (strncmp("nullfs", fstype, 7) == 0) {
		char _target[] = "target";

		iov[4].iov_base = strdup(_target);
		iov[4].iov_len = strlen(_target) + 1;
	} else {
		char _target[] = "from";

		iov[4].iov_base = strdup(_target);
		iov[4].iov_len = strlen(_target) + 1;		
	}
	iov[5].iov_base = strdup(sourcepath);
	iov[5].iov_len = strlen(sourcepath) + 1;

	return nmount(iov, 6, flags);
}

int startpowerd(pid_t * powerdpid) {
	return 0;
}

int startwatchdogd(pid_t * watchdogdpid) {
	struct rtprio rtp;
	int watchdog_fd;

	*watchdogdpid = fork();
	switch (*watchdogdpid) {
		case 0:
			rtp.type = RTP_PRIO_REALTIME;
			rtp.prio = 0;
			if (rtprio(RTP_SET, 0, &rtp) == -1) {
				printf("watchdogd: Unable to set realtime mode\n");
				exit(3);
			}
			if (watchdoginit(&watchdog_fd) == -1) {
				printf("watchdogd: Mommy, where's Fluffy?.\n");
				exit(4);
			}
			
			exit(2);
		break;
		case -1:
			return 2;
		break;
	}
	return 0;
}

int watchdoginit(int * fd) {
	handle devicelock = acquire("hostfs", "/dev/" _PATH_WATCHDOG, LOCK_EXCLUSIVE);
        *fd = open("/dev/" _PATH_WATCHDOG, O_RDWR);
        if (*fd >= 0) {
                return (0);
	}
        printf("Could not open watchdog device");
        return (-1);
}

int watchdogpat(int fd, u_int timeout) {
	return ioctl(fd, WDIOCPATPAT, &timeout);
}

int startdevd(pid_t * devdpid) {
	return 0;
}

int startsystem(pid_t * systartpid, int mode) {
	int status;
	int ret;
	*systartpid = fork();

	switch (*systartpid) {
		case 0:
			if (mode == MULTIUSER) {
				static char * shell = SHPATH;
				static char * nargv[4];
				struct sigaction systart_sa;
				sigemptyset(&systart_sa.sa_mask);
				systart_sa.sa_flags = 0;
				systart_sa.sa_handler = SIG_IGN;
				sigprocmask(SIG_SETMASK, &systart_sa.sa_mask, (sigset_t *) 0);
				setctty("/dev/ttyv0");
				nargv[0] = "sh";
				nargv[1] = "/system/share/bin/systart";
				nargv[2] = "autoboot";
				nargv[3] = "0";
				ret = execv(shell, nargv);
				perror(shell);
				exit(5);
			}
			if (mode == SINGLEUSER) {
				static char * shell = TCSHPATH;
				static char * nargv[1];
				struct sigaction systart_sa;
				sigfillset(&systart_sa.sa_mask);
				systart_sa.sa_flags = 0;
				systart_sa.sa_handler = SIG_IGN;
				sigprocmask(SIG_SETMASK, &systart_sa.sa_mask, (sigset_t *) 0);
				setctty("/dev/ttyv0");
				nargv[0] = "tcsh";
				ret = execv(shell, nargv);
				perror(shell);
				exit(5);
			}

		break;
		case -1:
			printf("Fork error, bailing out before we do any damage\n");
			return 4;
		break;
		default:
			while (1) {
				pid_t returnpid = wait(&status);
				if (returnpid == systartpid) {
					if (WIFSIGNALED(status)) {
						return status;
					}
				}
			}
		break;
	}
	return 1;
}

/*
	This is stub code to support a lock manager we don't have, but will eventually have to.

	Notes: domain is per-cluster, and refers to the namespace the path is relative to. 
	Right now we only use domain = "hostfs", which is typically mapped differently on each node,
	to the 'local' filesystem.

	'type' is defined previously.

*/

handle acquire(const char * domain, const char * path, int type) {
	return 0;
}

int release(handle lockid) {
	return 0;
}

