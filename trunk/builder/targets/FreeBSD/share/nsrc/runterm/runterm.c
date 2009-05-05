/* $Id$ */


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
	int tty;
	if (pid < 0) {
		err(4,"fork()");
	}
	if (pid == 0) {
		if (setsid() < 0) {
			err(1,"setsid()");
		}
		if (setlogin("CONSOLE") < 0) {
			err(2,"setlogin()");
		}
		if (tty = open(argv[1], O_RDWR) < 0) {
			err(3,"open()");
		}
		
		if (login_tty(tty) < 0) {
			err(5,"login_tty(%s)",argv[1]);
		}

		if (execvp(argv[2], &argv[2]) < 0) {
			err(6,"execvp()");	
		}
	}
	exit(0);
}
