#include <time.h>
#include <sys/timespec.h>
#include <sys/types.h>
#include <timeconv.h>
#include <sys/sysctl.h>
#include <stdlib.h>
#include <limits.h>
#include <string.h>
#include <stdio.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <netdb.h>

struct _handle {
	char * type;
	size_t size;
	void * data;
	void * private; /* Currently unused */
};

typedef struct _handle handle;

struct dial_search_pairs {
	char * key;
	char * value;
};

struct dialparse_v1 {
	char * protocol;
	int size;
	union {
		struct {
			char * host;
			char * port;
		};
		char * path;
		struct dial_search_pairs * key;
	};
};
/*
       This is stub code to support a lock manager we don't have, but will eventually have to.

       Notes: domain is per-cluster, and refers to the namespace the path is relative to.
       Right now we only use domain = "hostfs", which is typically mapped differently on each node,
       to the 'local' filesystem.

*/

#define LOCK_NULL 0
#define LOCK_CONCURRENT_READ 1
#define LOCK_PROTECTED_READ 2
#define LOCK_CONCURRENT_WRITE 3
#define LOCK_PROTECTED_WRITE 4
#define LOCK_EXCLUSIVE 5


extern handle * acquire(const char * domain, const char * path, int type);
extern int release(handle lockid);
extern time_t get_cluster_uptime(void);
extern handle * new_handle(size_t size, char * type);

struct _string {
	char * text;
	int length;
};

typedef struct _string string;

extern handle * dial(char *address, char *local);

extern handle * dialparse(char *address);

extern int close_handle(handle * realhandle);
