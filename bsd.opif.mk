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

ARCH ?= ${MACHINE}

#
# Global path locations
#
PROFDIR ?= ${.CURDIR}/profiles
SCRIPTSDIR ?= ${.CURDIR}/scripts
PROFILE_MTREE ?= ${SCRIPTSDIR}/profile.mtree
PROFFULLDIR := ${PROFDIR}
WRKDIR ?= ${.CURDIR}/w-sets
FAKEDIR ?= ${WRKDIR}/fake-${ARCH}


.if defined(P)
PROFILE = ${P}
.endif

.if defined(PROFILE) && exists(${PROFDIR}/${PROFILE}.profile)
PROFILE_FILE != ${FIND} ${PROFFULLDIR} -type f -name ${PROFILE}.profile
PLIST_FILE != ${FIND} ${PROFFULLDIR} -type f -name ${PROFILE}.plist

${PROFILE}_SOURCES != ${SCRIPTSDIR}/find-profile-frags ${PROFILE_FILE}
${PROFILE}_PLIST_SOURCES != ${SCRIPTSDIR}/find-profile-frags ${PLIST_FILE}
.endif

PROFILE_NORM = ${WRKDIR}/${PROFILE}.profile
PLIST_NORM = ${WRKDIR}/${PROFILE}.plist

_PROFILE_FILES != \
	${FIND} ${PROFFULLDIR} -type f -name '*.profile' -print | \
	${AWK} -F'/' '{ print $$NF }' | ${SORT}
PROFILE_FILES = ${_PROFILE_FILES:T}
PROFILES = ${PROFILE_FILES:C/\.profile$//}

WRKINST = ${FAKEDIR}/${PROFILE}

_WRKDIR_COOKIE = ${WRKDIR}/.wrkdir_done
_FAKE_MTREE_COOKIE = ${WRKDIR}/.${PROFILE}-fake_mtree_done


#
# Common commands and operations
#
_MAKE_COOKIE = ${TOUCH}

_CREATE_PROFILE = ${SCRIPTSDIR}/create-profile ${PROFILE_FILE}
_CREATE_PLIST = ${SCRIPTSDIR}/create-profile ${PLIST_FILE}

# Used to print all the '===>' style prompts -- override this to turn them off
ECHO_MSG ?= ${ECHO}

.if defined(verbose-show)
.MAIN: verbose-show
.elif defined(show)
.MAIN: show
.elif defined(clean)
.MAIN: clean
.elif defined(_internal-clean)
clean = ${_internal-clean}
.MAIN: _internal-clean
.else
.MAIN: all
.endif

# need to go through an extra var because clean is set in stone,
# on the cmdline.
_clean = ${clean}
.if empty(_clean)
_clean += work
.endif
.if ${_clean:L:Mwork}
_clean += fake
.endif
# check that clean is clean
_okay_words = work fake dist packages
.for _w in ${_clean:L}
.  if !${_okay_words:M${_w}}
ERRORS += "Fatal: unknown clean command: ${_w}"
.  endif
.endfor

# Top-level targets redirect to the real _internal-target
.for _t in build clean
${_t}: _internal-${_t}
.endfor


${_WRKDIR_COOKIE}:
	@${RM} -rf ${WRKDIR}
	@${MKDIR} -p ${WRKDIR}
	@${_MAKE_COOKIE} $@


#####################################################
# Building a normalized .profile and .plist
#####################################################
${PROFILE_NORM}: ${_WRKDIR_COOKIE} ${${PROFILE}_SOURCES}
	@${ECHO_MSG} "===> Creating normalized profile for ${PROFILE}"
	@${_CREATE_PROFILE} > $@

${PLIST_NORM}: ${_WRKDIR_COOKIE} ${${PROFILE}_PLIST_SOURCES}
	@${ECHO_MSG} "===> Creating normalized plist for ${PROFILE}"
	@${_CREATE_PLIST} > $@

_internal-build:
.if !defined(PROFILE) && !defined(_PROFILES_RECURS)
.  for _profile in ${PROFILES}
	@cd ${.CURDIR} && \
		exec ${MAKE} build PROFILE=${_profile} _PROFILES_RECURS=true
.  endfor
.else
	@cd ${.CURDIR} && exec ${MAKE} _check-profile PROFILE=${PROFILE}
	@cd ${.CURDIR} && exec ${MAKE} ${PROFILE_NORM} PROFILE=${PROFILE}
	@cd ${.CURDIR} && exec ${MAKE} ${PLIST_NORM} PROFILE=${PROFILE}
.endif


#####################################################
# 
#####################################################
${_FAKE_MTREE_COOKIE}:
	@cd ${.CURDIR} && exec ${MAKE} _check-profile PROFILE=${PROFILE}
	@${SUDO} install -d -m 755 -o root -g wheel ${WRKINST}
	${CAT} ${PROFILE_MTREE} | \
		${SUDO} /usr/sbin/mtree -U -e -d -n -p ${WRKINST} >/dev/null
	@${_MAKE_COOKIE} $@



#####################################################
# Checking for profile files existance
#####################################################
_check-profile:
.if !defined(PROFILE) || ${PROFILE} == ""
	@${ECHO_MSG}
	@${ECHO_MSG} ">> Variable PROFILE (or P) not defined!"
	@${ECHO_MSG} ">> usage: make PROFILE=<profile> <action>"
	@exit 1
.else
	@if [ ! -e "${PROFILE_FILE}" -o ! -e "${PLIST_FILE}" ]; then \
		${ECHO_MSG} ">> A profile with name \"${PROFILE}\" could not be found."; \
		${ECHO_MSG} ">> To list all profiles, run: make list-profiles"; \
		${ECHO_MSG} ">> Two files called ${PROFDIR}/${PROFILE}.profile and"; \
		${ECHO_MSG} ">> ${PROFDIR}/${PROFILE}.plist must exist."; \
		${ECHO_MSG}; \
		exit 1; \
	fi
.endif


#####################################################
# Cleaning up
#####################################################
_internal-clean:
	@${ECHO_MSG} "===>  Cleaning"
.if ${_clean:L:Mwork}
	@if [ -L ${WRKDIR} ]; then ${RM} -rf `readlink ${WRKDIR}`; fi
	@${RM} -rf ${WRKDIR}
.endif
.if ${_clean:L:Mfake}
.  if defined(PROFILE)
	@cd ${.CURDIR} && exec ${MAKE} _check-profile PROFILE=${PROFILE}
	@${RM} -rf ${FAKEDIR}/${PROFILE}
.  else
	@${RM} -rf ${FAKEDIR}
.  endif
.endif
.if ${_clean:L:Mpackages}
	@${ECHO_MSG} "===>  Packages cleaning"
	@${RM} -rf ${PACKAGE_REPOSITORY}
.endif

#####################################################
# Convenience targets
#####################################################
_internal-list-profiles:
	@${ECHO_MSG} "===> Listing profiles";
	@for file in ${PROFILES}; do\
		${ECHO_MSG} "$$file"; \
	done

list-profiles:
	@cd ${.CURDIR} && exec ${MAKE} _internal-list-profiles
