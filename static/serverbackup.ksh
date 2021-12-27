#!/bin/ksh
# this code does not check any errors!
# use at your own risk!
# if you use it, make a copy of your gpg keyring to a 
# safe place

#modify these to your needs
dirs="/etc /var/spool/maildir /srv/www/htdocs /home/manni /var/teamspeak"
logfile="/var/log/ftpbackup.log"
enc_to=XXXchange_thisXXX
ftp_pass=XXXchange_thisXXX
mysql_pass=XXXchange_thisXXX
ftp_server=XXXchange_thisXXX
ftp_user=XXXchange_thisXXX
#end of configurable vars

dt=$(date -I)
workdir=/root

touch $logfile

cd $workdir || exit 1

echo "$dt: starting $0" >> $logfile

for d in $dirs ; do
    echo "$dt: backing up $d" >> $logfile
    b=$(basename $d)
    echo "$dt: Creating compressed tarfile $b.tgz" >> $logfile
    tar czf $b.$dt.tgz $d
done

du -sh *.$dt.tgz >> $logfile

#dump all mysql databases
for d in $(echo /var/lib/mysql/*) ; do
    if [[ -d $d ]] ; then
        dbname=$(basename $d)
        echo "Dumping db $dbname" >> $logfile
        /usr/bin/mysqldump -u root -p$mysql_pass  $dbname  >> $dbname.sql.$dt
        echo "Compressing dumpfile of $dbname" >> $logfile
        gzip $dbname.sql.$dt
    fi
done

#encrypt and delete them
for tarfile in *.$dt.tgz ; do
    echo "$dt: Encrypting $tarfile" >> $logfile
    gpg -a --encrypt -r $enc_to $tarfile
    rm -f $tarfile
done

#same for db dumps
for dumpfile in *.sql.$dt.gz ; do
	echo "Encrypting dumpfile $dumpfile" >> $logfile
	gpg -a --encrypt -r $enc_to $dumpfile
	rm -f $dumpfile
done

for crypted_archive in *.asc ; do
echo "$dt: Uploading $crypted_archive" >> $logfile
ncftpput -u $ftp_user -p $ftp_pass -DD $ftp_server -m  /backup/$dt $crypted_archive
rm -f $crypted_archive 
done
