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

#include "evoke.h"

time_t get_cluster_uptime() {
	time_t uptime;
        struct timespec tp;
	char string[42];
	char *addrstring = string;
	char *newstring;
	int size = 42;
	if (sysctlbyname("kern.evoke_boottime", &string, &size, NULL, 0) != -1) {
		if (strncmp(string, "NULL", 5) != 0) {
			newstring = strsep(&addrstring, ",");
			if (newstring != NULL) {
				if (newstring != '\0') {
					long temptime = strtol(newstring, (char **)NULL , 0);
					time_t boottime = _long_to_time(temptime);
					uptime = time(NULL) - boottime;

				} else {
					if (clock_gettime(CLOCK_MONOTONIC, &tp) != -1) {
						uptime = tp.tv_sec;
					}
				}
			} else {
				if (clock_gettime(CLOCK_MONOTONIC, &tp) != -1) {
					uptime = tp.tv_sec;
				}
			}
		} else {
			if (clock_gettime(CLOCK_MONOTONIC, &tp) != -1) {
				uptime = tp.tv_sec;
			}
		}
	} else {
		if (clock_gettime(CLOCK_MONOTONIC, &tp) != -1) {
			uptime = tp.tv_sec;
		}
	}
	return uptime;
}

/* 
	function to create a handle with a data size as specified in 'size', fully initialized.
*/

handle * new_handle(size_t size, char * type) {
	size_t allocsize;
	size_t type_length = strlen(type) + 1;
	size_t handle_length = sizeof(handle);

	allocsize = handle_length + type_length + size;
	handle * temp = malloc(allocsize);


	temp->type = (char *) ((size_t) temp + handle_length);
	strncpy(temp->type, type, type_length);

	temp->data = (void *) ((size_t) temp->type + type_length);
	temp->size = size;
	bzero(temp->data, size);

	return temp;
};

int close_handle(handle * handle) {
	free(handle);
	return 0;
}


/* 
	Function specification:

		address = a character string containing a plan9ish address specification.
			Currently the following formats are valid:

				net!host!port
				- 'Network' specification, ie, tcp/udp. You can specify tcp or udp, which will force it to use that protocol. 'net' is a basic specification, to find the 'best' protocol to use.
				- The host and port specification may be either symbolic or numeric.

				unix!/path/name
				- 'AF_UNIX' socket specification.

				nnet!key=value!key=value!key=value
				- key and value MUST NOT contain the characters '=', '!', or '\0'; all others are valid.
				- This method is the reason for MIMO semantics, because it is a 'search' rather then a specification. Multiple can be returned, and must be handled.

		local = Identical to address in format, but specifies the local address, local port, etc, when a socket is bound.
		fdlist = A 'handle' referring to the fdlist dial creates. In error, this handle remains NULL.
*/

handle * dial(char *address, char *local) {
	handle * tempfd;
	char buffer[256];

	handle * dp;
	dp = dialparse(address);
	struct dialparse_v1 * hostspec = dp->data;

	handle * dp2;

	dp2 = dialparse(local);
	if (dp2 != NULL) {
		struct dialparse_v1 * localaddress = dp2->data;
		printf("%s\n", localaddress->host);
		printf("%s\n", localaddress->protocol);
		printf("%s\n", localaddress->port);
	}

	if (strlen(hostspec->protocol) >= 3) {
		if (strncmp(hostspec->protocol,"net",4) == 0 || strncmp(hostspec->protocol,"tcp",4) == 0 || strncmp(hostspec->protocol,"udp",4) == 0) {
			tempfd = new_handle(sizeof(int), "com.googlecode.evoke.FDLIST.v1.0");

			struct sockaddr_in targetaddress;

			int * fdlist;
			fdlist = tempfd->data;
			fdlist[0] = 2334;


			struct hostent * realserver;
			realserver = gethostbyname(hostspec->host);
			if (realserver == NULL) {
				strerror(65);
				return NULL;
			}
			struct servent * realport;
			int portnum;
			if (hostspec->port == NULL) {
				portnum = 21221;
			} else {
				if (hostspec->port == '\0') {
					portnum = 21221;
				} else {
					realport = getservbyname(hostspec->port, "tcp");
					if(!realport) {
						portnum = strtonum(hostspec->port, 1, 65535, NULL);
						if (portnum == 0) {
							portnum = 21221;
						}
					} else {
						portnum = ntohs(realport->s_port);
					}
				}
			}
			if (strncmp(hostspec->protocol,"udp",4) == 0) {
				fdlist[0] = socket(PF_INET, SOCK_DGRAM, 0);
			} else {
				fdlist[0] = socket(PF_INET, SOCK_STREAM, 0);
			}
			if (strncmp(local, "0", 3) == 0) {
		
			} else {
			}
		}
	}
	return tempfd;
}
handle * dialparse(char *address) {
	handle * pointer;
	pointer = NULL;
	char *tempaddress;
	tempaddress = strdup(address);

	char *protocol;
	protocol = strsep(&tempaddress, "!");

	if (protocol == '\0' || protocol == NULL) {
		strerror(22);
		return NULL;
	}

	size_t structsize = sizeof(struct dialparse_v1);

	printf("protocol = %s\n", protocol);


	if (strlen(protocol) >= 3) {
		if (strncmp("net", protocol,4) == 0 || strncmp("tcp", protocol, 4) == 0 || strncmp("udp",protocol,4) == 0) {
			char *host;
			host = strsep(&tempaddress, "!");

			char *port;
			port = strsep(&tempaddress, "!");

			if (host == '\0') {
				strerror(22);
				return NULL;
			}

			printf("host = %s\n", host);
			size_t portsize = 0;
			if (port != '\0') {
				portsize = strlen(port) + 1;
				printf("port = %s\n", port);
			}
			size_t protocolsize = strlen(protocol) + 1;
			size_t hostsize = strlen(host) + 1;
			size_t totalsize = structsize + protocolsize + hostsize + portsize;
			pointer = new_handle(totalsize, "com.googlecode.evoke.DIALPARSE.v1.0");
			struct dialparse_v1 * temp;
			temp = pointer->data;
	
			temp->protocol = (char *) ((size_t) temp + structsize);
			strncpy(temp->protocol, protocol, protocolsize);

			temp->host = (char *) ((size_t) temp + structsize + protocolsize);
			strncpy(temp->host, host, hostsize);
			temp->size = hostsize;
			temp->port = NULL;
			if (port != '\0') {
				temp->port = (char *) ((size_t) temp + structsize + protocolsize + hostsize);
				strncpy(temp->port, port, portsize);
			}
		}
	}

	free(tempaddress);
	return pointer;
}
