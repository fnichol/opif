# $Id$

# Copyright (c) 2007, Fletcher Nichol
# All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
# 
# THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
# IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
# OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
# IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT,
# INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
# NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
# DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
# THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
# THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

#
# Path to common commands
#
AWK = /usr/bin/awk
BASENAME = /usr/bin/basename
CAT = /bin/cat
CHMOD = /bin/chmod
CHROOT = /usr/sbin/chroot
CP = /bin/cp
DIRNAME = /usr/bin/dirname
ECHO = /bin/echo
EGREP = /usr/bin/egrep
FIND = /usr/bin/find
FTP = /usr/bin/ftp
GREP = /usr/bin/grep
HEAD = /usr/bin/head
KSH = /bin/ksh
LS = /bin/ls
MD5 = /bin/md5
MKDIR = /bin/mkdir
MOUNT_MFS = /sbin/mount_mfs
MV = /bin/mv
PATCH_CMD = /usr/bin/patch
RM = /bin/rm
SED = /usr/bin/sed
SORT = /usr/bin/sort
SUDO = /usr/bin/sudo
TAR = /bin/tar
TOUCH = /usr/bin/touch
UMOUNT = /sbin/umount
UNAME = /usr/bin/uname
XARGS = /usr/bin/xargs

#
# Global path locations
#
PROFDIR ?= ${.CURDIR}/profiles
SCRIPTSDIR ?= ${.CURDIR}/scripts
PROFFULLDIR := ${PROFDIR}
WRKDIR ?= ${.CURDIR}/w-sets


.if defined(P)
PROFILE = ${P}
.endif

.if defined(PROFILE)
.  if exists(${PROFDIR}/${PROFILE}.profile)
PROFILE_FILE != ${FIND} ${PROFFULLDIR} -type f -name ${PROFILE}.profile

${PROFILE}_SOURCES != ${SCRIPTSDIR}/find-profile-frags ${PROFILE_FILE}

PROFILE_NORM = ${WRKDIR}/${PROFILE}.profile
.  endif
.endif

FAKEDIR ?= ${WRKDIR}/fake-${PROFILE}


CREATE_PROFILE = ${SCRIPTSDIR}/create-profile ${PROFILE_FILE}


test:
	@echo "PROFDIR is [${PROFDIR}]"
	@echo "PROFFULLDIR is [${PROFFULLDIR}]"
	@echo "WRKDIR is [${WRKDIR}]"
	@echo "PROFILE is [${PROFILE}]"
	@echo "PROFILE_FILE is [${PROFILE_FILE}]"
	@echo "FAKEDIR is [${FAKEDIR}]"
	@echo "${PROFILE}_source is [${${PROFILE}_SOURCES}]"

${PROFILE_NORM}: ${${PROFILE}_SOURCES}
	@echo "i need rebuilding: ${PROFILE_NORM}"
	@mkdir -p ${WRKDIR}
	${CREATE_PROFILE} > $@
