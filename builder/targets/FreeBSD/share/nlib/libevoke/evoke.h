

typedef int handle;

extern handle acquire(const char * domain, const char * path, int type);
extern int release(handle lockid);
