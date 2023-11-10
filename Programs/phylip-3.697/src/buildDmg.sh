#!/bin/sh

usage () {
cat << buildDmgUsageInfo
*****************************************************************
USAGE: buildDmg <topdir> [<builddir>]

      	<topdir> 	full path to the directory to package
	<builddir>	directory to do the build in
*****************************************************************
buildDmgUsageInfo
}

doCommand () {
	if [ -z "$1" ]
	then
		echo "INTERNAL ERROR: no arg to doCommand"
		exit 2
	else
		echo "COMMAND: $1"
		$1
	fi
}

#
localbuild="build"

# find out where we've started
invokedir=`pwd`

###################################################################
# required first argument -- full path to package directory
packagetop=$1
if test X$packagetop = "X" ; then
	echo "ERROR: missing required first argument."
	usage
	exit 1
fi
if [ ! -e ${packagetop} ] ; then
	echo "ERROR: couldn't find package directory "${packagetop}\""
	usage
	exit 1
fi
if [ ! -d ${packagetop} ] ; then
	echo "ERROR: "${packagetop}\" not a directory"
	usage
	exit 1
fi
fullPathPackageTop=`(cd ${packagetop} 2> /dev/null && pwd ;)`

###################################################################
# optional second argument, place to build the .dmg
# if not given, make in current directory and report
#
# $2 is where to do the build
if test X$2 = "X" ; then
	builddir=${invokedir}/${localbuild}
else
	builddir=$2
fi
if [ ! -e ${builddir} ] ; then
	if ! mkdir ${builddir} 2> /dev/null
	then
		echo "ERROR: couldn't create ${builddir}"
		usage
		exit 2
	fi
fi
if [ ! -d ${builddir} ] ; then
	echo "ERROR: <builddir> \"$builddir\" missing or not a directory"
	usage
	exit 2
fi
fullPathBuildDir=`(cd ${builddir} 2> /dev/null && pwd ;)`

###################################################################
# Now we have full path names ${fullPathPackageTop} and 
# ${fullPathBuildDir}
#
# We have to extract the last part of ${fullPathPackageTop} to
# get the current package name
packageName=`basename ${fullPathPackageTop}`
imageName=${packageName}-osx
volumeName=${packageName}-vol

## debugging stuff
echo "full path to package : ${fullPathPackageTop}"
echo "full path to build   : ${fullPathBuildDir}"
echo "package name         : ${packageName}"
echo "image name           : ${imageName}"
echo "volume name          : ${volumeName}"

## ewfix -- get real value
imageSize=45

###################################################################
# ready to rumble!

cd ${fullPathBuildDir}

# remove old dmg if it exists
rm -f ${imageName}.dmg

# make the blank image
hdiutil create ${imageName}.dmg -size ${imageSize}m -fs HFS+ -volname ${volumeName}

# mount the image and store the device name into dev_handle
hfsLoc=`hdid ${imageName}.dmg | grep Apple_HFS | perl -e '\$_=<>; /^\\/dev\\/(disk.)/; print \$1'`

echo "HFS LOC:${hfsLoc}"

# copy the software onto the disk
# remove the trailing ${packageName} if you don't want a level
# of indirection (in form of a folder) between the open volume
# and the various executables and documents
ditto -rsrcFork ${fullPathPackageTop} /Volumes/${volumeName}/${packageName}

# unmount the volume
hdiutil detach ${hfsLoc}

# compress the image
hdiutil convert ${imageName}.dmg -format UDZO -o ${imageName}.udzo.dmg

# remove the uncompressed image
rm -f ${imageName}.dmg

# move the compressed image to take its place
mv ${imageName}.udzo.dmg ${imageName}.dmg

# flatten -- ensure resource forks (if any) aren't lost when we copy 
# this over to a linux system
hdiutil flatten ${imageName}.dmg

exit 0
