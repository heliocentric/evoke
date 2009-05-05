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

int setctty(const char *);

int main() {
	if (getpid() == 1) {

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
