#!/bin/bash
#
# The "build.u2up" project build script
#
# Copyright (C) 2014 Samo Pogacnik <samo_pogacnik@t-2.net>
# All rights reserved.
#
# This file is part of the "build.u2up software project.
# This file is provided under the terms of the BSD 3-Clause license,
# available in the LICENSE file of the "build.u2up" software project.
#

set -e

# U2UP build version:
build_u2up_MAJOR=0
build_u2up_MINOR=1
build_u2up_PATCH=1
build_u2up_version=$build_u2up_MAJOR.$build_u2up_MINOR.$build_u2up_PATCH

export pro="> "
export tab="${tab}-"
pre="${tab}${pro}"

comp_source_dir=""
comp_build_dir=""
comp_repo_dir=""
comp_clean_build=0

function usage_help ()
{
	echo
	echo -n "Usage: "
	basename -z $0
	echo " [{-repodir=|-r[=]}REPOSITORY_DIR] [{-buildir=|-b[=]}BUILD_DIR] [--srcdir=|-s[=]]SOURCE_DIR"
	echo
#	return
	exit 1
}

while [[ $# > 0 ]]
do
#	echo "AAAAAAA:$#"
#	echo "aaaaaaa:$1"
	case $1 in
	-s)
		shift # past argument
		comp_source_dir="${1}"
		;;
	--srcdir=*|-s=*)
		comp_source_dir="${1#*=}"
		;;
	-s*)
		comp_source_dir="${1#*s}"
		;;
	-b)
		shift # past argument
		comp_build_dir="${1}"
		;;
	--buildir=*|-b=*)
		comp_build_dir="${1#*=}"
		;;
	-b*)
		comp_build_dir="${1#*b}"
		;;
	-r)
		shift # past argument
		comp_repo_dir="${1}"
		;;
	--repodir=*|-r=*)
		comp_repo_dir="${1#*=}"
		;;
	-r*)
		comp_repo_dir="${1#*r}"
		;;
	*)
		# source dir or unknown option
		if [ "x"$comp_source_dir == "x" ]
		then
			if [ -d $1 ]
			then
				comp_source_dir=$1
			else
				echo "${pre}ERROR: Unknown option: "$1
				usage_help
			fi
		else
			echo "${pre}ERROR: Unknown option: "$1
			usage_help
		fi
		;;
	esac
	set +e; shift; set -e # to the next token, if any
done
#echo "Source dir: "$comp_source_dir
#echo "Build dir: "$comp_build_dir
#echo "Repository dir: "$comp_repo_dir

if [ "x"$comp_source_dir == "x" ]
then
	echo "${pre}ERROR: Setting source directory is mandatory!"
	usage_help
fi

export pro="> "
export tab="${tab}-"
pre="${tab}${pro}"
echo "${pre}CALLED: "$0
build_u2up_DIR=`dirname $0`
current_work_DIR=$PWD
echo "${pre}from current work dir: "$current_work_DIR
echo "${pre}BUILD.U2UP - version: "$build_u2up_version

# Set absolute SOURCE directory:
echo "${pre}Using specified component source dir: "$comp_source_dir
cd $comp_source_dir
comp_source_DIR=$PWD
cd - > /dev/null
echo "${pre}component's absolute source dir: "$comp_source_DIR
comp_source_NAME=$(basename -z $comp_source_DIR)
#echo "${pre}component source name: "$comp_source_NAME
comp_specs_DIR=$comp_source_DIR/comp_specs
if [ ! -d $comp_specs_DIR ]
then
	echo "${pre}ERROR: Source directory is not an U2UP component (missing comp_specs dir)!"
	exit 1
fi
echo "${pre}component specifications dir: "$comp_specs_DIR
if [ ! -f $comp_specs_DIR/name ]
then
	echo "${pre}ERROR: Missing comp_specs/name file!"
	exit 1
fi
. $comp_specs_DIR/name
echo "${pre}Component name: "$comp_name
echo "${pre}minimum required BUILD.U2UP: "$min_build_u2up_MAJOR.$min_build_u2up_MINOR
if [ "x"$min_build_u2up_MAJOR != "x" ]
then
	if [ $min_build_u2up_MAJOR -eq $build_u2up_MAJOR ]
	then
		if [ "x"$min_build_u2up_MINOR != "x" ]
		then
			if [ $min_build_u2up_MINOR -gt $build_u2up_MINOR ]
			then
				echo "${pre}ERROR: Incompatible minimal build.u2up version required (min_build_u2up_MINOR=${min_build_u2up_MINOR})!"
				exit 1
			fi
		else
			echo "${pre}ERROR: Missing minimal build.u2up version required (min_build_u2up_MINOR)!"
			exit 1
		fi
	else
		echo "${pre}ERROR: Incompatible minimal build.u2up version required (min_build_u2up_MAJOR=${min_build_u2up_MAJOR})!"
		exit 1
	fi
else
	echo "${pre}ERROR: Missing minimal build.u2up version required (min_build_u2up_MAJOR)!"
	exit 1
fi

if [ ! -f $comp_specs_DIR/version ]
then
	echo "${pre}ERROR: Missing comp_specs/version file!"
	exit 1
fi
. $comp_specs_DIR/version
comp_version=$comp_version_MAJOR"."$comp_version_MINOR"."$comp_version_PATCH
echo "${pre}Component version: "$comp_version

conf_u2up_FILE="u2up-conf"
if [ -f $build_u2up_DIR"/"$conf_u2up_FILE ]
then
	. $build_u2up_DIR"/"$conf_u2up_FILE
	echo "${pre}Using configuration file: "$build_u2up_DIR"/"$conf_u2up_FILE
	#cat $build_u2up_DIR"/"$conf_u2up_FILE
else
	echo "${pre}Without "$conf_u2up_FILE" configuration file expected at: "$build_u2up_DIR"/"
fi

# Set absolute BUILD directory:
if [ "x"$comp_build_dir == "x" ]
then
	echo "${pre}Using predefined U2UP build dir: "$u2up_build_dir
	comp_build_DIR=$u2up_build_dir/$comp_source_NAME
	mkdir -p $comp_build_DIR
	cd $comp_build_DIR
else
	echo "${pre}Using specified U2UP build dir: "$comp_build_dir
	mkdir -p $comp_build_dir
	cd $comp_build_dir
	comp_build_DIR=$PWD
fi
echo "${pre}component's absolute build dir: "$comp_build_DIR

if [ "x"$comp_repo_dir == "x" ]
then
	echo "${pre}Using predefined U2UP repository dir: "$u2up_repo_dir
	comp_repo_DIR=$u2up_repo_dir
	mkdir -p $comp_repo_DIR
else
	echo "${pre}Using specified U2UP repository dir: "$comp_repo_dir
	mkdir -p $comp_repo_dir
	cd $comp_repo_dir
	comp_repo_DIR=$PWD
	cd - > /dev/null
fi
echo "${pre}absolute repository dir: "$comp_repo_DIR

if [ ! -f $comp_specs_DIR/required ]
then
	echo "${pre}ERROR: Missing comp_specs/required file!"
	exit 1
fi
$build_u2up_DIR/import_required.sh $comp_specs_DIR $comp_build_DIR $comp_repo_DIR

if [ ! -f $comp_specs_DIR/build ]
then
	echo "${pre}ERROR: Missing comp_specs/build file!"
	exit 1
fi
#???Should this be an option too???
#comp_install_DIR=$comp_build_DIR/install
comp_install_dir=
. $comp_specs_DIR/build
if [ "x"$comp_install_dir == "x" ]
then
	echo "${pre}ERROR: Internal installation directory not set/provided by the component!"
	exit 1
else
	echo "${pre}Component provided internal installation dir: "$comp_install_dir
	cd $comp_install_dir
	comp_install_DIR=$PWD
	cd - > /dev/null
fi
echo "${pre}absolute internal component installation dir: "$comp_install_DIR
#exit 55

if [ ! -f $comp_specs_DIR/packages ]
then
	echo "${pre}ERROR: Missing comp_specs/packages file!"
	exit 1
fi
. $comp_specs_DIR/packages

for package_name in "${COMP_PACKAGES[@]}"
do
	echo "${pre}Component's package_name: "$package_name
	if [ "x"$package_name != "x" ]
	then
		subst="COMP_PACKAGE_${package_name}[@]"
		for package_type in "${!subst}"
		do
			echo "${pre}package_type: "$package_type
			if [ "x"$package_type != "x" ]
			then
				case $package_type in
				runtime)
					comp_package_name=${package_name}
					;;
				devel)
					comp_package_name=${package_name}-${package_type}
					;;
				*)
					exit 1
					;;
				esac
				subsubst="COMP_PACKAGE_${package_name}_${package_type}[@]"
				echo "${pre}package \""$comp_package_name"\" content: "${!subsubst}
#set -x
				cd $comp_install_DIR
				tar czvf $comp_build_DIR/files.tgz ${!subsubst}
				cd - > /dev/null
				cd $comp_build_DIR
				$build_u2up_DIR/create_package.sh $comp_package_name-$comp_version files.tgz $comp_specs_DIR/name $comp_specs_DIR/version $comp_specs_DIR/required
				if [ "x"$comp_repo_DIR != "x" ]
				then
					echo "${pre}Copy package to the common repository: "$comp_repo_DIR
					cp -pf $comp_package_name-$comp_version* $comp_repo_DIR/
				else
					echo "${pre}The second parameter (a common repository path) not provided (package not copied)!"
				fi
				cd - > /dev/null
				echo "${pre}Package DONE!"
			fi
		done
	fi
done
