

# The Evoke Platform #

## Evoke Library ##

**WARNING, THE EVOKE API IS NOT SET IN STONE YET**

### V\_Object ###

The basic composite data-type for the Evoke library is the 'V\_Object'. A V\_Object is a data structure very similar in spirit to the [BMessage](http://www.haiku-os.org/legacy-docs/bebook/BMessage.html) of BeOS and Haiku. They are a data structure which are typed, and which contain one or more data fields, all with a unique name, and all typed. It is meant to allow passing of composite data types from one function to another, without resorting to blind pointer dereferencing.

Functions should also not access the V\_Object directly, but instead use the following functions:

  * V\_ObjectNew(V\_String type);

Programs must always use the function error() and evaluate the return value on any V\_Object they recieve. This function checks for NULL pointers, and looks for the general error datatype.

For example:
```
   V_Object * socket = V_Dial("invalid string", 0);
   if (V_ErrorPrint(socket)) {
      V_ErrorPrint(socket);
      V_Exit(socket);
   }
```

This should be self explanatory, if the V\_Dial call returns an error, the message string is printed, and the process exits with the proper errno.

### `V_ObjectData` ###

### V\_String ###

A V\_String is a composite 'string' data type, containing a pointer to the string, and it's length. The following are the public elements:

  * text - char pointer - For compatibility, must always be terminated with a '\0' byte
  * length - size\_t, full length of the string, including terminator.

### Object Types ###

Object types are typically expressed in three ways. Currently there is only one hard restriction on types, which is that mime types cannot be used for the application signature.

#### Mime Types ####

The ubiquitous mime-type, which is conventionally used for V\_ObjectData types, and file types.

ex.

  * text/plain
  * application/octet-stream
  * image/png

#### Signature Types ####

Signature style types, which are inverted domain name style types, typically used for application signatures and V\_Object types. The / character is explicitly disallowed. Occasionally used for V\_ObjectData.

ex.

  * com.googlecode.evoke.libevoke.error
  * com.googlecode.evoke.libevoke.fdlist

#### Quick Types ####

These are used internally by V\_Object. Since they are all 4 bytes in size (or less), they replace the pointer. They are almost always basic data types.

ex.

  * SI8
  * SI16
  * SI32
  * SI64
  * UI8
  * UI16
  * UI32
  * UI64
  * FL16
  * FL32

## Evoke program guide ##

Default OPTIONS values:

  * recurse - if a directory is specified, walk it.
  * norecurse - opposite of recurse
  * quiet - only return the absolutely necessary output.
  * verbose - opposite of quiet
  * seperatemount - Restrict operations to this filesystem only, if a mountpoint is discovered, ignore it.
  * nowrite - Don't write anything. This makes sense only for fileops
  * write - Opposite of nowrite. Force write, if the default is nowrite.

### Command based programs ###
Example:
  * [userconfig](Userconfig.md)
  * [sysconfig](Sysconfig.md)
  * [mounter](Mounter.md)

### Search UI programs ###

Example:
  * [doc](Doc.md)

### File operation based programs ###

File operation programs must take a list of files as their argument list, each file in a seperate argv[.md](.md) entry in the array. All options are based via OPTIONS.

Example:
  * [verify](Verify.md)
  * [filetype](Filetype.md)
  * [consolidate](Consolidate.md)

# Using the SVN Repo #

## Checkout ##

It is highly recommended that you at least check out the tools, and add them to your PATH, before any other paths.

> `svn https://evoke.googlecode.com/svn/tools evoke-tools`

## Commit Log format ##

```
* Item A
* Item B
* Item C
```

For certain commits, a short description line is necessary, like so.

```
Description

* Item A
* Item B
* Item C
```

## Special Commits ##

### Issue ###

Any commit directly or indirectly resulting from an issue, must have the following form:

```
Issue from id1 id2 id3 ...

* Item A
* Item B
* Item C
```

The third field, and every field till the end of line MUST be a valid issue id number. Make sure to check the issue tracker for any issues that may be directly or indirectly related to the commit in question. This is so that in the future, we can trigger automatic hints to test possible fixes.

### AQA ###

AQA's are automated quality assurance tests. They get a special description, when a fix for a bug discovered through one of these tests. Note that right now the AQA's don't live up to the 'A' portion, but they will soon.

The commit message is as follows:

```
AQA from HPAT run number: 6daae55f-f516-4afd-8a95-59e02fb8d830

* Item A
* Item B
* Item C
```

The sixth field /must/ be the uuid of the run. This is done for accounting purposes.

The third field is the test short name, one of the following:

| Short Name | Full Name | Description | Technical Notes |
|:-----------|:----------|:------------|:----------------|
| AFRT       | Automated Functionality Regression Test | Runs the contents of each src/share/bin and each tools under both the 'run' environment, and the iso environment. Will only pick up bugs that have existing regression tests to check. | [[AQA\_AFRT](AQA_AFRT.md)] |
| HPAT       | Haiku Portability Acid Test | The same as AFRT, but run under a haiku environment to test the portability. The haiku environment is both a) alien enough to trigger portability bugs, but b) modern enough that the environment is useful for us. | [[AQA\_HPAT](AQA_HPAT.md)] |
| MFRT       | Manual Functionality Regression Test | Explicitly not automated. A human being runs the iso in a qemu or a bare metal machine, or uses the run script. As not all concievable regressions can be tested, this is done on the build machine after large changesets. | [[AQA\_MFRT](AQA_MFRT.md)] |

# Release Engineering Guide #

## Creating a Release Branch ##

(All commands relevant to /, not /trunk)

To initially create a release branch, always use the following steps:

> `svn copy trunk branches/releases/0.2/R1`

[R1](https://code.google.com/p/evoke/source/detail?r=1) is always the first revision.

Next, add a release page:
> `svn add wiki/Release02.wiki`

There is only one release page per release, so ignore the revision.

The first thing to do is fill out the release page with the todo list:

```
#summary 0.2 Release Notes

== Todo ==

 * any items that need to be done before R1
```

Now, we commit:

> `svn commit`

The format of the commit message is similar to 'Merge', except the items are not commit logs that apply, rather, it is the contents of the initial Todo list.

```
Branch /trunk rREVISION to /branches/releases/0.2/R1

 * any items that need to be done before R1

```

Then, we need to copy the wiki into the branch, like so:

> `svn copy wiki branches/releases/0.2/R1/doc`

Finally, we commit:

> `svn commit`

The format of the commit message is similar to 'Merge', however, the item list should be a todo list for the documents.

```
Branch /wiki rREVISION to /branches/releases/0.2/R1/doc

 * any items that need to be done before R1

```

## 'Setting' a release branch ##

When the binaries for a revision of a release branch are finished, and placed on the http mirror, you must set a property on the copy of the release
tree. After this point, NO more commits may happen to that revision. You must create a new revision of the release branch and work on that.

You should set it with this command:

> `svn propset evoke-binaries-built "" https://evoke.googlecode.com/svn/branches/releases/0.2/R1`

## Back merging changes into a release branch ##

Use the backmerge utility in tools/, like so.

> `cd branches/releases/0.1/R1/`
> `backmerge`

Note that there is no options to the utility yet. When we need them, I will add them.


## Creating a new revision ##

As stated earlier, you cannot commit to a revision after the binaries have been built, therefore you must do a copy, like so:

> `svn copy https://evoke.googlecode.com/svn/branches/releases/0.2/R1 https://evoke.googlecode.com/svn/branches/releases/0.2/R2`

The rules for creating binaries apply to every revision, not just the first revision. In this way, our boot versioning system can be used by the users effectively.