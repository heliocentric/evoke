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

#include <evoke.h>
#include <sys/queue.h>
#include <stdio.h>
#include <stdlib.h>
#include <limits.h>
#include <time.h>
#include <string.h>

struct host {
	LIST_ENTRY(host) hosts;
	int addresscount;
	char * address;
	short port;
	int mode;
	time_t boottime;
};

LIST_HEAD(hostlist, host) mainlist = LIST_HEAD_INITIALIZER(mainlist);
struct hostlist *headp;

int find_nodes(int searchmode, char *host, unsigned short port);


/*
	Host connect modes.
*/

#define direct 1
#define stun 2
#define ssh 3

/*
	Search modes.
*/

#define direct 1
#define global 2
#define google 3

int main(int argc, char *argv[]) {
	if (argc == 4) {
		LIST_INIT(&mainlist);
		find_nodes(direct, argv[2], (unsigned short) strtol(argv[3], (char **)NULL , 0));

		struct host *current_host, *temp;
		int count = 1;
		LIST_FOREACH_SAFE(current_host, &mainlist, hosts, temp) {
			printf("Node %d:\n", count);
			printf("\taddress = \t%s:\n", current_host->address);
			printf("\tsizeof(address) = \t%d bytes:\n", current_host->addresscount);
			printf("\tport = \t\t%u:\n", current_host->port);
			printf("\tmode = \t\t%d:\n", current_host->mode);
		}
		return 0;
	} else {
		printf("netd needs three options:\n");
		printf("\t1:\tlisten port\n");
		printf("\t2:\tconnect host\n");
		printf("\t3:\tconnect port\n");
		return 23;
	}
}

int find_nodes(int searchmode, char *address, unsigned short port) {
	struct host *only_host;

	only_host = malloc(sizeof(struct host));

	only_host->addresscount = strlen(address);
	only_host->address = address;
	only_host->port = port;
	only_host->mode = direct;

	LIST_INSERT_HEAD(&mainlist, only_host, hosts);

	return 0;
}
