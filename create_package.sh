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

pkg_filename=$1.u2up
sha_filename=$1.sha
echo "Creating U2UP installation package: "$pkg_filename
cat > $pkg_filename << EOF
#!/bin/bash

echo "Running U2UP installation package: "\$0
sed '0,/^__ARCHIVE_TGZ__$/d' \$0 | tar xzv
exit 0
__ARCHIVE_TGZ__
EOF
chmod 755 $pkg_filename
cat $2 >> $pkg_filename
echo "Creating U2UP package SHA-512 hash: "$sha_filename
sha512sum -b $pkg_filename > $sha_filename

exit 0
