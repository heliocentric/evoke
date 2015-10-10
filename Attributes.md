## Description ##

Evoke is a modern system, so it uses extended attributes wherever logical. This is a list of all attributes we are currently using, organized by namespace.

## System ##

| Name		| Type		| Used?	| Value					|
|:------|:------|:------|:----------|
| creator	| UUID		| No		  | UUID of the user that created the file	|

## User ##

| Name		| Type		| Used?	| Value								|
|:------|:------|:------|:-------------|
| mime\_type	| String	| Yes		 | Override mime-type. |
| cache\_mime\_type	| String	| Yes		 | Cached mime-type for filetype. |
| cache\_mtime	| String	| Yes		 | Mtime the cache was last updated |
| sha256	| String	| Yes		 | SHA256 hash of the file contents, used by verify. Not reliable	|
| md5		 | String	| Yes		 | MD5 hash of the file contents, used by verify. Not reliable		|
| icon		| Binary	| No		  | An icon image for the file. Not currently used by anything		|
| thumbnail	| Binary	| No		  | A thumbnail image of the file. Not currently used by anything	|