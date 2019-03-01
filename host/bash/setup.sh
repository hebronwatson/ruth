# setup.sh
# Purpose: carry out tasks to configure the vagrant image for development
#			especially complicated tasks not suited to ansible

# set no unset variables for the script
set -o nounset

# set automatic exit on error for the script
set -o errexit



# MY PERSONAL INFORMATION
COMMITER_EMAIL='hebronwatson@gmail.com'
COMMITER_NAME='Hebron Watson'

# FILE TO HOLD INFORMATION ON INSTALLED PACKAGES
PACKAGES_INFO_DIR='/host';
INSTALLED_PACKAGES_FILENAME="$PACKAGES_INFO_DIR/tmp-pkg-install";
AVAILABLE_PHP_PACKAGES_FILENAME="$PACKAGES_INFO_DIR/tmp-pkg-php.txt";
AVAILABLE_APACHE_PACKAGES_FILENAME="$PACKAGES_INFO_DIR/tmp-pkg-apache.txt";
AVAILABLE_MYSQL_PACKAGES_FILENAME="$PACKAGES_INFO_DIR/tmp-pkg-mysql.txt";

# PROJECT DIR
PROJECT_DIR='/host/www/hoopscore';

# PROJECT REPOSITORY HOST
PROJECT_REPO_HOST='bitbucket.org'

# MYSQL SECRETS CONFIGURATION
MYSQL_SECRETS_DIR='secret';
MYSQL_SECRETS_FILENAME='mysql_pass';
MYSQL_GENR8D_PASSWORD='';

# MORE CONFIG
DB_CONFIG_FILEPATH='/host/config/db.ini';
HOOPSCORE_DB_CONFIG_FILEPATH='/host/www/hoopscore/db/config/db.ini';

# PHP VERSION ( 7.0 -> 7.3 => RECOMMENDED)
PHP_VERSION='7.3';

# MYSQL SERVER PACKAGE
MYSQL_SERVER_PACKAGE='mysql-server';

# Update Package Records
function UpdatePackageRecords(){
	echo $( apt list --installed ) > "$INSTALLED_PACKAGES_FILENAME";
	echo $( apt-cache search | grep ^php7 ) > "$AVAILABLE_PHP_PACKAGES_FILENAME";
	echo $( apt-cache search | grep apache2 ) > "$AVAILABLE_APACHE_PACKAGES_FILENAME";
	echo $( apt-cache search | grep mysql-server ) > "$AVAILABLE_MYSQL_PACKAGES_FILENAME";
}

function InstalledPackages(){
	cat "$INSTALLED_PACKAGES_FILENAME";
}

function AvailablePHPPackages(){
	cat "$AVAILABLE_PHP_PACKAGES_FILENAME";
}

function AvailableApachePackages(){
	cat "$AVAILABLE_APACHE_PACKAGES";
}

function AvaiableMySqlPackages(){
	cat "$AVAILABLE_MYSQL_PACKAGES";
}

# generate password
# depends on PHP
# PARAM:
#	@1: RANDOM_STRING:	String To Append To Hash
function PHPGeneratePassword(){
	echo `php -r "echo(md5(\"$1\" . date_format(new DateTime(), \"Y-m-d h:i:s\")));"`;
}

# install dependencies from apt
function FetchDependencyPackages(){
	# Get repository info for PHP 7.3
	add-apt-repository -y ppa:ondrej/apache2
	add-apt-repository -y ppa:ondrej/php
	# update the repository
	apt-get update
	apt-get -y upgrade
	# test if PHP7.3 is installed
	UpdatePackageRecords;
	test $( AvailablePHPPackages | grep php7.3 ) && echo "PHP 7.3 packages are available... downloading...";
	# install PHP 7.3 and apache2
	apt-get -q -y install apache2 "php$PHP_VERSION"
	# install PHP 7.3 extensions
	apt-get -q -y install "php$PHP_VERSION-{bcmath,bz2,intl,gd,mbstring,mcrypt,mysql,zip,json,xml,mbstring}" "libapache2-mod-php$PHP_VERSION"
}

# install and configure composer
function ConfigureComposer(){
	wget https://raw.githubusercontent.com/composer/getcomposer.org/76a7060ccb93902cd7576b67264ad91c8a2700e2/web/installer -O - -q | php -- --quiet
	sudo mv composer.phar /usr/bin/composer
	sudo chmod 755 /usr/bin/composer
	sudo chown vagrant /usr/bin/composer
}

# copy and configure ssh keys and configure ssh-agent for access to git
function ConfigureSSHKeys(){
	# copy public and private keys from shared folder
	find /host/_ssh -name "id*" -exec cp {} /home/vagrant/.ssh \;
	chown -R vagrant /home/vagrant/.ssh
	chmod -R 700 /home/vagrant/.ssh
	
	# add keys to ssh agent for use in git operations
	eval $(ssh-agent)
	ssh-add /home/vagrant/.ssh/id_rsa
}

# add git host signature to known_hosts file in order to talk to git unsupervised
function AddHostKey(){
	ssh-keyscan $PROJECT_REPO_HOST | tee -a /home/vagrant/.ssh/known_hosts
}


# git config 
# parameterized because it involves personal information
function ConfigureGit(){
	git config --global user.email $COMMITER_EMAIL
	git config --global user.name $COMMITER_NAME
}

# clone the git repo if necessary
function CloneGitRepo(){
	# git clone into the desired file
	cd /host/www
	test ! -d $PROJECT_DIR && git clone git@bitbucket.org:hebronwatson/hoopscore.git
}

# clone and configure the git repo
# PARAMS:
#	@1:	MYSQL_SECRETS_DIR: 		Directory Storing Secrets
#	@2:	MYSQL_SECRETS_FILENAME:	File Storing MySql Password
#	@3:	DB_CONFIG_FILEPATH:		File Storing Database Config Information for PHP
#	@4:	MYSQL_GENR8D_PASSWORD:	Password Generated By PHP for MySql				
function GitRepoSecrets(){
	# make directories that are not in git repo	
	cd /host/www	
	test ! -d "$PROJECT_DIR/$MYSQL_SECRETS_DIR" && mkdir "$PROJECT_DIR/$MYSQL_SECRETS_DIR"
	#
	# generate the password
	MYSQL_GENR8D_PASSWORD=`php -r "echo(md5('hello' . date_format(new DateTime(), 'Y-m-d h:i:s')));"`;
	
	# copy config file to hoopcore project
	cp "$DB_CONFIG_FILEPATH" "$HOOPSCORE_DB_CONFIG_FILEPATH";
	
	# populate with secrets
	echo $MYSQL_GENR8D_PASSWORD > "$PROJECT_DIR/$MYSQL_SECRETS_DIR/$MYSQL_SECRETS_FILENAME"
	
	printf "$MYSQL_GENR8D_PASSWORD" >> "$HOOPSCORE_DB_CONFIG_FILEPATH"	
}

function RunComposerInstall(){
	# install composer requirements
	composer install
}


# configure the database
# Install MySQL Server in a Non-Interactive mode. Default root password will be "root"
function AutomatedMySqlInstallation(){

	# set config for automated install through dpkg settings
	dpkg-reconfigure -f noninteractive tzdata
	echo "$MYSQL_SERVER_PACKAGE $MYSQL_SERVER_PACKAGE/root_password password $MYSQL_GENR8D_PASSWORD" | debconf-set-selections
	echo "$MYSQL_SERVER_PACKAGE $MYSQL_SERVER_PACKAGE/root_password_again password $MYSQL_GENR8D_PASSWORD" | debconf-set-selections
	apt-get -y install $MYSQL_SERVER_PACKAGE
	
	# Run the MySQL Secure Installation wizard
	# mysql_secure_installation
}


# run sql files 
function RunMySqlScripts(){ 
	mysql -u root -p$mysql_password < /host/www/hoopscore/db/sql/create_tables.sql
}


# modify the main apache config file to allow the site to run at /host/www/hoopscore/public
function ConfigureApacheSite(){
	sed -r -ibak "s/\/var\/www/\/host\/www\/hoopscore\/public/" /etc/apache2/apache2.conf
	sed -r -ibak "s/(\/var\/www\/html)/\/host\/www\/hoopscore\/public/" /etc/apache2/sites-available/000-default.conf
	# enable the site 
	a2dissite 000-default
	a2ensite 000-default
	# restart apache2
	service apache2 reload
}

#FetchDependencyPackages;
#ConfigureComposer;
ConfigureSSHKeys;
AddHostKey;
ConfigureGit;
CloneGitRepo;
GitRepoSecrets;
#RunComposerInstall;
#AutomatedMySqlInstallation;
RunMySqlScripts;
ConfigureApacheSite;
