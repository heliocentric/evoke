#include <sys/param.h>
#include <sys/types.h>
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

#define HEX_DIGEST_LENGTH 65	

int setctty(const char *);

int fmount(const char *fstype, const char *sourcepath, const char *destpath, int flags);

int realmain(void);

int checkhash(void);

#define SYSTART "/system/share/bin/systart"
#define SYSTOP "/system/share/bin/systop"

#define SINGLEUSER 1
#define MULTIUSER 5


#define BINPATH "/system/%%ABI%%/%%ARCH%%/bin"
#define SHELLPATH "/system/%%ABI%%/%%ARCH%%/bin/sh"
#define LIBPATH "/system/%%ABI%%/%%ARCH%%/lib"
#define LIBEXECPATH "/system/%%ABI%%/%%ARCH%%/libexec"
#define BOOTPATH "/system/%%ABI%%/%%ARCH%%/boot"

int main(int argc, char *argv[], char *envp[]);

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
	printf("%d\n", mode);
	ret = realmain();
	/* How the hell did we get here? */
	return (ret);
}

int realmain() {
	int ret;
	if (getpid() == 1) {
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


		ret = checkhash();
		if (ret != 0) {
			return (ret);
		}

                openlog("init", LOG_CONS|LOG_ODELAY, LOG_AUTH);

		if (setsid() < 0) {
			return 2;
		}

		if (setlogin("root") < 0) {
			return 2;
		}



		fmount("nullfs", BINPATH, "/bin", MNT_NOATIME|MNT_RDONLY|MNT_UNION);
		fmount("nullfs", LIBPATH, "/lib", MNT_NOATIME|MNT_RDONLY|MNT_UNION);
		fmount("nullfs", LIBEXECPATH, "/libexec", MNT_NOATIME|MNT_RDONLY|MNT_UNION);
		fmount("nullfs", BOOTPATH, "/boot", MNT_NOATIME|MNT_RDONLY|MNT_UNION);
		fmount("nullfs", "/system/share/bin", "/bin", MNT_NOATIME|MNT_RDONLY|MNT_UNION);

		printf("system initialized");
	} 
	return 0;
}

int checkhash() {
	char buffer[HEX_DIGEST_LENGTH];
	char *realhash;
	realhash = SHA256_File("/dev/md0", buffer);

	if (!realhash) {
		return 3;
	} else {
		char storedhash[HEX_DIGEST_LENGTH];
		int ret;
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
}

int setctty(const char *name) {
        int fd;

        revoke(name);

        if ((fd = open(name, O_RDWR)) == -1) {
                return 1;
        }

        if (login_tty(fd) == -1) {
                return 1;
        } else {
		return 0;
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
