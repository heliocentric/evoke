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
#include <time.h>
#include <sys/timespec.h>
#include <sys/types.h>
#include <sys/sysctl.h>
#include <string.h>

time_t get_cluster_uptime() {
	time_t uptime;
        struct timespec tp;
	char string[42];
	char * addrstring = string;
	char **newstring;
	int size = 42;
	if (sysctlbyname("kern.evoke_boottime", &string, &size, NULL, 0) != -1) {
		if (strncmp(string, "NULL", 5) != 0) {
			*newstring = strsep(&addrstring, ",");
			if (*newstring != NULL) {
				if (**newstring != '\0') {
					uptime = time(NULL) - (time_t) strtol(string, (char **)NULL , 0);
					
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
