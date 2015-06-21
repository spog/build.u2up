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
export pro="> "
export tab="${tab}-"
pre="${tab}${pro}"
echo "${pre}CALLED: "$0
build_u2up_DIR=`dirname $0`
echo "${pre}from build dir: "$PWD
comp_build_DIR=$PWD

if [ "x"$1 != "x" ]
then
	cd $1
	comp_source_DIR=$PWD
	cd - > /dev/null
	echo "${pre}source dir: "$comp_source_DIR
else
	echo "${pre}ERROR: The first parameter must be source dir!"
	exit 1
fi

comp_specs_DIR=$comp_source_DIR/comp_specs
echo "${pre}comp_specs dir: "$comp_specs_DIR
comp_install_DIR=$comp_build_DIR/install
echo "${pre}install dir: "$comp_install_DIR

if [ "x"$2 != "x" ]
then
	cd $2
	comp_repos_DIR=$PWD
	cd - > /dev/null
	mkdir -p $comp_repos_DIR
	echo "${pre}repository dir: "$comp_repos_DIR
else
	comp_repos_DIR=
fi

. $comp_specs_DIR/name

echo "${pre}Component name: "$comp_name

. $comp_specs_DIR/version

comp_version=$comp_version_MAJOR"."$comp_version_MINOR"."$comp_version_PATCH
echo "${pre}Component version: "$comp_version

$build_u2up_DIR/import_required.sh $comp_specs_DIR $comp_build_DIR $comp_repos_DIR

. $comp_specs_DIR/build

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
				if [ "x"$comp_repos_DIR != "x" ]
				then
					echo "${pre}Copy package to the common repository: "$comp_repos_DIR
					cp -pf $comp_package_name-$comp_version* $comp_repos_DIR/
				else
					echo "${pre}The second parameter (a common repository path) not provided (package not copied)!"
				fi
				cd - > /dev/null
				echo "${pre}Package DONE!"
			fi
		done
	fi
done
