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
INSTALL = /usr/bin/install
KSH = /bin/ksh
LS = /bin/ls
MD5 = /bin/md5
MKDIR = /bin/mkdir
MOUNT_MFS = /sbin/mount_mfs
MV = /bin/mv
NAWK = /usr/bin/nawk
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
FILESDIR ?= ${.CURDIR}/files
PROFILE_MTREE ?= ${SCRIPTSDIR}/profile.mtree
PROFFULLDIR := ${PROFDIR}
WRKDIR ?= ${.CURDIR}/w-sets
FAKEDIR ?= ${WRKDIR}/fake-${ARCH}

KEY_HOSTNAME = hostname
KEY_OSREV = osrev


.if defined(P)
PROFILE = ${P}
.endif


_PROFILE_FILES != \
	${FIND} ${PROFFULLDIR} -type f -name '*.profile' -print | \
	${AWK} -F'/' '{ print $$NF }' | ${SORT}
PROFILE_FILES = ${_PROFILE_FILES:T}
PROFILES = ${PROFILE_FILES:C/\.profile$//}


.if defined(PROFILE) && exists(${PROFDIR}/${PROFILE}.profile)
PROFILE_FILE != ${FIND} ${PROFFULLDIR} -type f -name ${PROFILE}.profile
PLIST_FILE != ${FIND} ${PROFFULLDIR} -type f -name ${PROFILE}.plist

${PROFILE}_SOURCES != ${SCRIPTSDIR}/find-profile-frags ${PROFILE_FILE}
${PROFILE}_PLIST_SOURCES != ${SCRIPTSDIR}/find-profile-frags ${PLIST_FILE}

PROFILE_NORM = ${WRKDIR}/${PROFILE}.profile
PLIST_NORM = ${WRKDIR}/${PROFILE}.plist

WRKINST = ${FAKEDIR}/${PROFILE}
WRKINSTPATCHES = ${WRKINST}/tmp/patchfiles

.  if exists(${PLIST_NORM})
_PLIST_ALL_FILES != \
	${NAWK} 'BEGIN { FS = "[ \t]+" } \
		{ if ( $$1 == "file" )  printf "${FILESDIR}/%s\n",$$2 }' $(PLIST_NORM)

_PLIST_ALL_PATCHES != \
	${NAWK} 'BEGIN { FS = "[ \t]+" } \
		{ if ( $$1 == "patch" )  printf "${FILESDIR}/%s\n",$$2 }' $(PLIST_NORM)

_PLIST_INSTALLED_FILES_AR != \
	${NAWK} 'BEGIN { FS = "[ \t]+" } \
		{ if ( $$1 == "file" ) { filename = $$2; sub(/.*\//, "", filename); \
		printf "${FILESDIR}/%s|${WRKINST}%s/%s@%s:%s:%s\n", \
		$$2, $$3, filename, $$4, $$5, $$6 } }' $(PLIST_NORM)

_PLIST_INSTALLED_PATCHES_AR != \
	${NAWK} 'BEGIN { FS = "[ \t]+" } \
		{ if ( $$1 == "patch" ) { filename = $$2; sub(/.*\//, "", filename); \
		printf "${FILESDIR}/%s|${WRKINSTPATCHES}/%s\n", \
		$$2, filename } }' $(PLIST_NORM)

_PLIST_INSTALLED_DIRS_AR != \
	${NAWK} 'BEGIN { FS = "[ \t]+" } \
		{ if ( $$1 == "dir" ) { printf "${WRKINST}%s@%s:%s:%s\n", \
		$$2, $$3, $$4, $$5 } }' $(PLIST_NORM)
.  endif
.endif


_WRKDIR_COOKIE = ${WRKDIR}/.wrkdir_done
_FAKE_MTREE_COOKIE = ${WRKINST}


#
# Common commands and operations
#
_MAKE_COOKIE = ${TOUCH}

_CREATE_PROFILE = ${SCRIPTSDIR}/create-profile ${PROFILE_FILE}
_CREATE_PLIST = ${SCRIPTSDIR}/create-profile ${PLIST_FILE}

_PROFILE_REPLACE_TOKENS = ${SED} 's?$${OSREV}?${OSREV}?g'

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
.for _t in build fake package clean
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
	@${_CREATE_PROFILE} | ${_PROFILE_REPLACE_TOKENS} > $@

${PLIST_NORM}: ${_WRKDIR_COOKIE} ${${PROFILE}_PLIST_SOURCES}
	@${ECHO_MSG} "===> Creating normalized plist for ${PROFILE}"
	@${_CREATE_PLIST} | ${_PROFILE_REPLACE_TOKENS} > $@

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
	@cd ${.CURDIR} && exec ${MAKE} _check-profile-syntax PROFILE=${PROFILE}
.endif


#####################################################
# Creating a fake install directory tree with files
#####################################################
${_FAKE_MTREE_COOKIE}:
	@cd ${.CURDIR} && exec ${MAKE} _check-profile PROFILE=${PROFILE}
	@${SUDO} ${INSTALL} -d -m 755 -o root -g wheel ${WRKINST}
	@${CAT} ${PROFILE_MTREE} | \
		${SUDO} /usr/sbin/mtree -U -e -d -n -p ${WRKINST} >/dev/null

.for _file in ${_PLIST_INSTALLED_FILES_AR}
${_file:C/^.*\|//:C/@.*$//}: ${_file:C/\|.*$//}
	@echo ">> Installing ${_file:C/^.*\|//:C/@.*$//}"
	@perms=`echo "${_file:C/^.*@//}" | awk -F':' '{ print $$1 }'`; \
	user=`echo "${_file:C/^.*@//}" | awk -F':' '{ print $$2 }'`; \
	group=`echo "${_file:C/^.*@//}" | awk -F':' '{ print $$3 }'`; \
	${INSTALL} -m $$perms -o $$user -g $$group ${_file:C/\|.*$//} \
	`dirname ${_file:C/^.*\|//:C/@.*$//}`
.endfor

.for _file in ${_PLIST_INSTALLED_PATCHES_AR}
${_file:C/^.*\|//}: ${_file:C/\|.*$//}
	@echo ">> Installing ${_file:C/^.*\|//}"
	@${INSTALL} -m 0644 -o 0 -g 0 ${_file:C/\|.*$//} `dirname ${_file:C/^.*\|//}`
.endfor

.for _file in ${_PLIST_INSTALLED_DIRS_AR}
${_file:C/@.*$//}:
	@echo ">> Making directory ${_file:C/@.*$//}"
	@perms=`echo "${_file:C/^.*@//}" | awk -F':' '{ print $$1 }'`; \
	user=`echo "${_file:C/^.*@//}" | awk -F':' '{ print $$2 }'`; \
	group=`echo "${_file:C/^.*@//}" | awk -F':' '{ print $$3 }'`; \
	${INSTALL} -d -m $$perms -o $$user -g $$group ${_file:C/@.*$//}
.endfor

${WRKINST}/${PROFILE}.profile: ${PROFILE_NORM}
	@echo ">> Installing ${WRKINST}/${PROFILE}.profile"
	@${INSTALL} -m 0444 -o 0 -g 0 ${PROFILE_NORM} ${WRKINST}/site.profile
	
_install-dirs-and-files:
.for _f in ${_PLIST_INSTALLED_DIRS_AR}
	@cd ${.CURDIR} && exec ${MAKE} ${_f:C/@.*$//} PROFILE=${PROFILE}
.endfor
	@cd ${.CURDIR} && exec ${MAKE} _check-plist-file-dirs PROFILE=${PROFILE}
.for _f in ${_PLIST_INSTALLED_FILES_AR}
	@cd ${.CURDIR} && exec ${MAKE} ${_f:C/^.*\|//:C/@.*$//} PROFILE=${PROFILE}
.endfor
.for _f in ${_PLIST_INSTALLED_PATCHES_AR}
	@cd ${.CURDIR} && exec ${MAKE} ${_f:C/^.*\|//} PROFILE=${PROFILE}
.endfor
	@cd ${.CURDIR} && exec ${MAKE} ${WRKINST}/${PROFILE}.profile \
		PROFILE=${PROFILE}

_internal-fake:
.if !defined(PROFILE) && !defined(_PROFILES_RECURS)
.  for _profile in ${PROFILES}
	@cd ${.CURDIR} && \
		exec ${MAKE} fake PROFILE=${_profile} _PROFILES_RECURS=true
.  endfor
.else
	@cd ${.CURDIR} && exec ${MAKE} build PROFILE=${PROFILE}
	@cd ${.CURDIR} && exec ${MAKE} ${_FAKE_MTREE_COOKIE} PROFILE=${PROFILE}
	@cd ${.CURDIR} && exec ${MAKE} _install-dirs-and-files PROFILE=${PROFILE}
.endif


#####################################################
# 
#####################################################
_internal-package:
.if !defined(PROFILE) && !defined(_PROFILES_RECURS)
.  for _profile in ${PROFILES}
	@cd ${.CURDIR} && \
		exec ${MAKE} package PROFILE=${_profile} _PROFILES_RECURS=true
.  endfor
.else
	@cd ${.CURDIR} && exec ${MAKE} fake PROFILE=${PROFILE}
.endif



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

_check-profile-syntax:
	@if ! grep '^${KEY_OSREV}[[:space:]]\{1,\}' ${PROFILE_NORM} > /dev/null; then \
		${ECHO_MSG} ">> Keyword "${KEY_OSREV}" must be defined in profile ${PROFILE}."; \
		exit 1; \
	fi
	@if ! grep '^${KEY_HOSTNAME}[[:space:]]\{1,\}' ${PROFILE_NORM} > /dev/null; then \
		${ECHO_MSG} ">> Keyword "${KEY_HOSTNAME}" must be defined in profile ${PROFILE}."; \
		exit 1; \
	fi

_check-plist-files:
	@for file in ${_PLIST_ALL_FILES}; do \
		if [ ! -f "$$file" ]; then \
			${ECHO_MSG} ">> File $$file in plist ${PLIST_NORM} does not exist."; \
			exit 20; \
		fi; \
	done

_check-plist-patchfiles:
	@for file in ${_PLIST_ALL_PATCHES}; do \
		if [ ! -f "$$file" ]; then \
			${ECHO_MSG} ">> Patchfile $$file in plist ${PLIST_NORM} does not exist."; \
			exit 21; \
		fi; \
	done

_check-plist-file-dirs:
	@for dir in `${NAWK} 'BEGIN { FS = "[ \t]+" } \
		{ if ( $$1 == "file" )  printf "%s\n",$$3 }' $(PLIST_NORM)`; do \
		if [ ! -d "${WRKINST}$$dir" ]; then \
			${ECHO_MSG} ">> Directory $$dir needs to be defined in plist ${PLIST_NORM}."; \
			exit 22; \
		fi; \
	done


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

