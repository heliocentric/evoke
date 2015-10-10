## Description ##
Convert the build system from primarily bourne, to primarly BSDMake. Part of this work is started in src/Makefile and src/builder/Makefile. Please only use Makefile dependencies that are actual dependencies. If they are not, have it call a script in builder/ to do the work. We don't need to repeat the mistakes in freebsd's src/ repo.


## Status ##

ISO generation and evoke.fs generation complete. Some changes to build.sh to support targetlist broke the Makefile.
