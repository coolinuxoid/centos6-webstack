#!/bin/bash
#Main Function
function ssh-connect() {
echo "Please enter FQDN or IP addr of Remote Host"
read host
echo "Please enter root password for remote host"
echo -n Password:
read -s passwd
echo
username=root
sshpass -p $passwd scp -r ./filesforscript $username@$host:/root/.
sshpass -p $passwd ssh $username@$host "host=$host; $(typeset -f); select-dbsrv; select-websrv; test-page;"
}

#Database functions
#POSTGRESQL INSTALLATION
function pgsql_install() {
echo "You selected PostgreSQL database server for your stack"
sleep 1
        yum install postgresql postgresql-server php-pgsql php php-common -y
        service postgresql initdb
        service postgresql start
        chkconfig postgresql on
        chown postgres /var/lib/pgsql/
	pghbaconf=`find / -name pg_hba.conf`
	pghbaconfremove='/root/filesforscript/pghbaconf-remove'
	pghbaconfset='/root/filesforscript/pghbaconf-set'
	cp -v $pghbaconf $pghbaconf.orig
        check_pgsqlpass
	create_pgsql_db
}
function check_pgsqlpass() {
if echo '\q' | su -c "psql" - postgres 2> /dev/null
then
        configure_pgsql
else
        menu_pgsqlpass
fi
}

function configure_pgsql() {
while [ $pgsqlpass1 != $pgsqlpass2 ]
do
        echo "Configuring PostgreSQL..."
        echo "Please enter NEW root password for PostgreSql database:"
        echo -n Password:
        read -s pgsqlpass1
        echo
        echo -n "Please re-enter password:"
        read -s pgsqlpass2
        echo
        sleep 2
done
printf "\password\n$pgsqlpass1\n$pgsqlpass1\n\q" | su -c "psql" - postgres
echo y | cp $pghbaconfset $pghbaconf
service postgresql reload
}

function menu_pgsqlpass() {
while [[ "$pgsql_menu" != 1 && "$pgsql_menu" != 2 ]]
do
        echo -e "\nPostgreSQL root password exists"
        echo -e "\n[1] Reset root password of PostgreSQL\n[2] Continue with current password"
        echo -n "Please select [1] or [2]:"
        read pgsql_menu
        sleep 1
done

case $pgsql_menu in
        1) reconfigure_pgsqlpass ;;
        2) check_current_pgsqlpass ;;
esac
}
function reconfigure_pgsqlpass() {
        echo -e "\nResetting pgsql root password"
        remove_pgsqlpass > /dev/null 2>&1
        configure_pgsql
}

function remove_pgsqlpass() {
        cp -v $pghbaconf $pghbaconf.bkp
	echo y | cp $pghbaconfremove $pghbaconf
        service postgresql reload
}

function check_current_pgsqlpass() {
echo -n Please enter current pgsql root password:

read -s pgsqlpass1
if echo $pgsqlpass1 |su -c "psql" - postgres -p 2> /dev/null
then
        echo -e "\nPostgreSQL ROOT Password is correct\n"
else
        echo -e "\nEntered PosgreSQL ROOT password is incorrect\n"
        sleep 1
        check_current_pgsqlpass_menu
fi
}

function check_current_pgsqlpass_menu() {
echo -e "\n[1] Reset root password of Mysql\n[2] Retry"
echo -n "Please select [1] or [2]:"
read current_pass_menu
case $current_pass_menu in
        1) reconfigure_pgsqlpass ;;
        2) check_current_pgsqlpass ;;
        *) check_current_pgsqlpass_menu ;;
esac
}

function create_pgsql_db() {
echo -e "\n\nCreating database\n\n"
sleep 2
echo -n "Please enter database name:  "
read DBNAME
echo
echo -n "Please enter username:  "
read DBUSER
echo
echo -n "Please enter password for user "$DBUSER":  "
read -s DBPASS
echo

printf "$pgsqlpass1\nCREATE USER $DBUSER WITH PASSWORD '$DBPASS';\nCREATE DATABASE $DBNAME;\nGRANT ALL PRIVILEGES ON DATABASE $DBNAME to $DBUSER;\n" | su -c "psql" - postgres -p

echo "PostgreSQL database and user created."
echo "DB name:    $DBNAME"
echo "Username:   $DBUSER"
echo "Password:   $DBPASS"
sleep 3
sed "s/DBNAME/$DBNAME/g; s/DBUSER/$DBUSER/g; s/DBPASS/$DBPASS/g" /root/filesforscript/infopgsql.php > /root/filesforscript/info.php
}
#MYSQL INSTALLATION

function mysql_install() {
echo "You selected MySQL database server for your stack"
sleep 1
        yum install mysql mysql-server php-mysql php php-common -y
        service mysqld start
        chkconfig mysqld on
        check_mysqlpass
        create_mysql_db
}

function check_mysqlpass() {
if echo quit | mysql -uroot 2> /dev/null
then
        configure_mysqlpass
else
        menu_mysqlpass
fi
}

function configure_mysqlpass() {
while [ $mysqlpass1 != $mysqlpass2 ]
do
        echo "Configuring MySQL..."
        echo "Please enter NEW root password for Mysql database:"
        echo -n Password:
        read -s mysqlpass1
        echo
        echo -n "Please re-enter password:"
        read -s mysqlpass2
        echo
        sleep 2

done
echo -e "\n\n$mysqlpass1\n$mysqlpass1\n\n\n\n\n" | mysql_secure_installation
}
function menu_mysqlpass() {
while [[ "$mysql_menu" != 1 && "$mysql_menu" != 2 ]]
do
        echo -e "\nMySQL root password exists"
        echo -e "\n[1] Reset root password of Mysql\n[2] Continue with current password"
        echo -n "Please select [1] or [2]:"
        read mysql_menu
        sleep 1
done

case $mysql_menu in
        1) reconfigure_mysqlpass ;;
        2) check_current_mysqlpass ;;
esac
}

function reconfigure_mysqlpass() {
        echo -e "\nResetting mysql root password"
        remove_mysqlpass > /dev/null 2>&1
        configure_mysqlpass
}

function remove_mysqlpass() {
        service mysqld stop
        mysqld_safe --skip-grant-tables &
        printf "use mysql;\nupdate user set password=PASSWORD("") where User='root';\nflush privileges;\nquit" | mysql -uroot
        service mysqld stop
        service mysqld start
}
function check_current_mysqlpass() {
echo -n Please enter current mysql root password:

read -s mysqlpass1
if echo quit | mysql -uroot -p$mysqlpass1 2> /dev/null
then
        echo -e "\nMySQL ROOT Password is correct\n"
else
        echo -e "\nPassword is incorrect\n"
        sleep 1
        check_current_mysqlpass_menu
fi
}

function check_current_mysqlpass_menu() {
echo -e "\n[1] Reset root password of Mysql\n[2] Retry"
echo -n "Please select [1] or [2]:"
read current_pass_menu
case $current_pass_menu in
        1)
        reconfigure_mysqlpass
        ;;
        2)
        check_current_mysqlpass
        ;;
        *)
        check_current_mysqlpass_menu
        ;;
esac
}
function create_mysql_db() {
echo -e "\n\nCreating database\n\n"
sleep 2
echo -n "Please enter database name:  "
read DBNAME
echo
echo -n "Please enter username:  "
read DBUSER
echo
echo -n "Please enter password for user "$DBUSER":  "
read -s DBPASS
echo
mysql -uroot -p$mysqlpass1 -e "CREATE DATABASE $DBNAME;"
mysql -uroot -p$mysqlpass1 -e "GRANT ALL ON $DBNAME.* TO '$DBUSER'@'localhost' IDENTIFIED BY '$DBPASS';"
mysql -uroot -p$mysqlpass1 -e "FLUSH PRIVILEGES;"
echo "MySQL database and user created."
echo "DB name:    $DBNAME"
echo "Username:   $DBUSER"
echo "Password:   $DBPASS"
sleep 3
sed "s/DBNAME/$DBNAME/g; s/DBUSER/$DBUSER/g; s/DBPASS/$DBPASS/g" /root/filesforscript/infomysql.php > /root/filesforscript/info.php
}
#Web Server Installation and Configuration function
#APACHE INSTALLATION
function apache_install() {
echo You selected Apache Web Server
sleep 1
yum install httpd php -y
mv -v /etc/httpd/conf/httpd.conf /etc/httpd/conf/httpd.conf.orig
sed "s/HOST/$host/g" /root/filesforscript/httpd.conf > /etc/httpd/conf/httpd.conf
service httpd start 2> /dev/null
chkconfig httpd on
httpd_vhost_add
}
function httpd_vhost_add() {
echo -e "\n\nWelcome to Virtual Host configuration\n\n"
echo -n "Please enter Server Name of your Virtual Host [example.com]:  "
read VHOSTNAME
if test "$VHOSTNAME" = "";then
	echo "ServerName can not be BLANK"
	sleep 1
	httpd_vhost_add
fi
VHOSTLIST='/etc/httpd/conf.d/VHOSTLIST.txt'
echo $VHOSTNAME >> $VHOSTLIST
sed "s/VHOSTNAME/$VHOSTNAME/g" /root/filesforscript/apachevhost.conf > /etc/httpd/conf.d/$VHOSTNAME.conf
mkdir -p /var/www/html/$VHOSTNAME/public
chmod -R 755 /var/www/html/$VHOSTNAME
cp /root/filesforscript/info.php /var/www/html/$VHOSTNAME/public/info.php
sed -i "s/VIRTUALHOST/$VHOSTNAME/g" /var/www/html/$VHOSTNAME/public/info.php
chown -R apache:apache /var/www/html/$VHOSTNAME
service httpd reload
httpd_vhost_menu
}
function httpd_vhost_menu() {
echo -e "\n[1] FINISH \n[2] Add another Virtual Host"
echo -n "Please select [1] or [2]:"
read menu_select
case $menu_select in
        1) echo ;;
        2) httpd_vhost_add ;;
        *) httpd_vhost_menu ;;
esac
}
#NGINX INSTALLATION
function nginx-install() {
php_config='/etc/php.ini'
fpm_config='/etc/php-fpm.d/www.conf'
nginx_default='/etc/nginx/nginx.conf'

echo You selected Nginx Web Server
sleep 1
yum install epel-release -y
yum install nginx -y
service nginx start
chkconfig nginx on
yum install php-fpm -y
printf "/cgi.fix_pathinfo\nc\ncgi.fix_pathinfo=0\n.\nw\nq" | ed $php_config > /dev/null 2>&1
printf "/listen =\nc\nlisten = /var/run/php-fpm/php-fpm.sock\n.\n/listen.owner =\nc\nlisten.owner = nginx\n.\n/listen.group =\nc\nlisten.group = nginx\n.\n/user =\nc\nuser = nginx\n.\n/group =\nc\ngroup = nginx\n.\nw\nq" |ed $fpm_config > /dev/null 2>&1
service php-fpm start
chmod 666 /var/run/php-fpm/php-fpm.sock
chown nginx:nginx /var/run/php-fpm/php-fpm.sock
cp -v /etc/nginx/nginx.conf /etc/nginx/nginx.conf.bkp
printf "$\ni\n    include /etc/nginx/sites-enabled/*.conf;\n    server_names_hash_bucket_size 64;\n.\nw\nq" | ed $nginx_default > /dev/null 2>&1
mkdir /etc/nginx/sites-available
mkdir /etc/nginx/sites-enabled
service php-fpm restart
service nginx restart
nginx_vhost_add
}
function nginx_vhost_add() {
echo -e "\n\nWelcome to Virtual Host configuration\n\n"
echo -n "Please enter Server Name of your Virtual Host [example.com]:  "
read VHOSTNAME
if test "$VHOSTNAME" = "";then
        echo "ServerName can not be BLANK"
        sleep 1
        nginx_vhost_add
fi
VHOSTLIST='/etc/nginx/conf.d/VHOSTLIST.txt'
echo $VHOSTNAME >> $VHOSTLIST
sed "s/VHOSTNAME/$VHOSTNAME/g" /root/filesforscript/nginxvhost.conf > /etc/nginx/sites-available/$VHOSTNAME.conf
mkdir -p /var/www/$VHOSTNAME/public
chmod -R 755 /var/www/$VHOSTNAME
cp /root/filesforscript/info.php /var/www/$VHOSTNAME/public/info.php
sed -i "s/VIRTUALHOST/$VHOSTNAME/g" /var/www/$VHOSTNAME/public/info.php
chown -R nginx:nginx /var/www/$VHOSTNAME
ln -s /etc/nginx/sites-available/$VHOSTNAME.conf /etc/nginx/sites-enabled/$VHOSTNAME.conf
service nginx restart
nginx_vhost_menu
}
function nginx_vhost_menu() {
echo -e "\n[1] FINISH \n[2] Add another Virtual Host"
echo -n "Please select [1] or [2]:"
read menu_select
case $menu_select in
        1) echo ;;
        2) nginx_vhost_add ;;
        *) nginx_vhost_menu ;;
esac
}
function select-dbsrv() {
echo "##############################################################################################################"
while [[ "$dboption" != 1 && "$dboption" != 2 ]]
do
        echo -e "Please select Database Server"
        echo -n "Mysql[1] or PostgreSQL[2]:"
        read dboption
        sleep 2
done
case $dboption in
        1) mysql_install ;;
        2) pgsql_install ;;
esac
}
function select-websrv() {
while [[ "$WEB" != 1 && "$WEB" != 2 ]]
do
        echo -e "Please select webserver"
        echo -n "Apache24[1] or Nginx[2]:"
        read WEB
        sleep 2
done
case $WEB in
        1) apache_install ;;
        2) nginx-install ;;
esac
}
function test-page() {
for VHOSTNAME in `cat $VHOSTLIST`
do
	echo "Please see http://$VHOSTNAME/info.php to check test page"
done
}
#COMMANDS
apt-get install sshpass -y > /dev/null 2>&1
yum install sshpass -y > /dev/null 2>&1
ssh-connect
