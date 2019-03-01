#! /usr/bin/env bash

# Author: Hebron Watson
# Purpose: Carry out somewhat messy configuration actions after ansible has finished its run

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


# MY PERSONAL INFORMATION
COMMITER_EMAIL='hebronwatson@gmail.com'
COMMITER_NAME='Hebron Watson'

# PROJECT DIR
projdir='/host/www/hoopscore';

# HOST DIR
hostdir='/host';

# MYSQL SECRETS CONFIGURATION
passdir='secret';
passfile='mysql_pass';




# MORE CONFIG
dbconf_file='db.ini';
dbconf_common_path="config/db/$dbconf_file";
dbconf_src="$hostdir/$dbconf_common_path";
dbconf_dest="$projdir/$dbconf_common_path";


# Produce a hash and save it as a password in a file
pass=`php -r "echo(md5(\"TODO: add random string\" . date_format(new DateTime(), 'Y-m-d h:i:s')));"`;
echo "$pass" > "$projdir/$passdir/$passfile"
