#! /usr/bin/env bash

# config Bash shell for stricter and safer operation
#
#
# Do not tolerate unset variables
set -o nounset
# Exit on any command not returning success
set -o errexit
# Consider command a failure if any command in the pipeline fails
set -o pipefail
# Set Internal Field Seperator to [ TAB or Newline ]
IFS=$'\t\n';

#
#
#
#

test ! -d "/host/ansible/roles/composer_install" && \
  git clone https://github.com/Vinelab/ansible-composer.git /host/ansible/roles/composer_install || true
  
# we need to add the installation role as a dependency for the composer installer
# we will achieve this by moving the meta/ folder 
#    (which holds the dependency data) into the directory of the composer_install directory
cp -R /host/ansible/.composer_install_dep /host/ansible/roles/composer_install