#include <sys/param.h>
#include <sys/types.h>
#include <fcntl.h>
#include <libutil.h>
#include <stdio.h>
#include <unistd.h>
#include <syslog.h>
#include <stdarg.h>
#include <sys/mount.h>
#include <sys/uio.h>
#include <signal.h>

int setctty(const char *);

#define SYSTART "/system/share/bin/systart"
#define SYSTOP "/system/share/bin/systop"

#define BINPATH "/system/%%ABI%%/%%ARCH%%/bin"
#define SHELLPATH "/system/%%ABI%%/%%ARCH%%/bin/sh"
#define LIBPATH "/system/%%ABI%%/%%ARCH%%/lib"
#define LIBEXECPATH "/system/%%ABI%%/%%ARCH%%/libexec"
#define BOOTPATH "/system/%%ABI%%/%%ARCH%%/boot"

int main() {
	if (getpid() == 1) {
		printf("blah\n");
	}
	/* How the hell did we get here? */
	return 1;
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
