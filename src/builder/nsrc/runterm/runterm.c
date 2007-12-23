# $Id$


#include <sys/param.h>
#include <sys/ioctl.h>
#include <sys/mount.h>
#include <sys/sysctl.h>
#include <sys/wait.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <sys/uio.h>

#include <stdlib.h>
#include <stdio.h>
#include <fcntl.h>
#include <libutil.h>
#include <unistd.h>
#include <errno.h>

int main(int argc, char *argv[]) {
	pid_t pid = fork();
	if (pid = 0) {
		if (setsid() < 0) {
			exit(1);
		}
		if (setlogin("CONSOLE") < 0) {
			exit(2);
		}
		int tty = open(argv[1], O_RDWR);
		close(0);
		close(1);
		close(2);
		login_tty(tty);
		close(tty);
		execvp(argv[1], &argv[1]);
	} else if (pid = -1) {
		exit(errno);
	}
}
