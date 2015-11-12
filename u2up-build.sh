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

comp_home_dir=""
comp_build_dir=""
comp_repo_dir=""
comp_clean_build=0

function usage_help ()
{
	echo
	echo -n "Usage: "
	basename -z $0
	echo " [{-repodir=|-r[=]}REPOSITORY_DIR] [{-buildir=|-b[=]}BUILD_DIR] [--compdir=|-c[=]]COMP_HOME_DIR"
	echo
#	return
	exit 1
}

while [[ $# > 0 ]]
do
#	echo "AAAAAAA:$#"
#	echo "aaaaaaa:$1"
	case $1 in
	-c)
		shift # past argument
		comp_home_dir="${1}"
		;;
	--compdir=*|-c=*)
		comp_home_dir="${1#*=}"
		;;
	-c*)
		comp_home_dir="${1#*c}"
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
		# comp_home_dir or unknown option
		if [ "x"$comp_home_dir == "x" ]
		then
			if [ -d $1 ]
			then
				comp_home_dir=$1
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
#echo "Source dir: "$comp_home_dir
#echo "Build dir: "$comp_build_dir
#echo "Repository dir: "$comp_repo_dir

if [ "x"$comp_home_dir == "x" ]
then
	echo "${pre}ERROR: Setting component home directory is mandatory!"
	usage_help
fi

export pro="> "
export tab="${tab}-"
pre="${tab}${pro}"
echo "${pre}CALLED: "$0
current_work_DIR=$PWD
echo "${pre}from current work dir: "$current_work_DIR
echo "${pre}BUILD.U2UP - version: "$build_u2up_version

# Set absolute U2UP tools directory:
build_u2up_dir=$(dirname $(which $0))
cd $build_u2up_dir
build_u2up_DIR=$PWD
cd - > /dev/null
echo "${pre}U2UP absolute tools dir: "$build_u2up_DIR

# Set absolute COMPONENT HOME directory:
echo "${pre}Using specified component home dir: "$comp_home_dir
cd $comp_home_dir
comp_home_DIR=$PWD
cd - > /dev/null
echo "${pre}component's absolute component home dir: "$comp_home_DIR
comp_home_NAME=$(basename -z $comp_home_DIR)
#echo "${pre}component name: "$comp_home_NAME
comp_u2up_DIR=$comp_home_DIR/u2up
if [ ! -d $comp_u2up_DIR ]
then
	echo "${pre}ERROR: HOME directory of the U2UP component (missing the u2up subdir)!"
	exit 1
fi
echo "${pre}component specifications dir: "$comp_u2up_DIR
if [ ! -f $comp_u2up_DIR/name ]
then
	echo "${pre}ERROR: Missing the u2up/name file!"
	exit 1
fi
. $comp_u2up_DIR/name
echo "${pre}Component requires BUILD.U2UP (minimum compatible) version: "$min_build_u2up_MAJOR.$min_build_u2up_MINOR
echo "${pre}Component NAME: "$comp_name
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

if [ ! -f $comp_u2up_DIR/version ]
then
	echo "${pre}ERROR: Missing the u2up/version file!"
	exit 1
fi
. $comp_u2up_DIR/version
comp_version=$comp_version_MAJOR"."$comp_version_MINOR"."$comp_version_PATCH
echo "${pre}Component VERSION: "$comp_version

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
	comp_build_DIR=$u2up_build_dir/$comp_home_NAME
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

if [ ! -f $comp_u2up_DIR/required ]
then
	echo "${pre}ERROR: Missing the u2up/required file!"
	exit 1
fi
$build_u2up_DIR/import_required.sh $comp_u2up_DIR $comp_build_DIR $comp_repo_DIR

if [ ! -f $comp_u2up_DIR/build ]
then
	echo "${pre}ERROR: Missing the u2up/build file!"
	exit 1
fi
#???Should this be an option too???
#comp_install_DIR=$comp_build_DIR/install
comp_install_dir=
. $comp_u2up_DIR/build
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

if [ ! -f $comp_u2up_DIR/packages ]
then
	echo "${pre}ERROR: Missing the u2up/packages file!"
	exit 1
fi
. $comp_u2up_DIR/packages

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
				$build_u2up_DIR/create_package.sh $comp_package_name-$comp_version files.tgz $comp_u2up_DIR/name $comp_u2up_DIR/version $comp_u2up_DIR/required
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
