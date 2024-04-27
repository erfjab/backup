#!/bin/bash

# برای نمایش متن های خبری ساده به رنگ آّبی
function print() {
    message="$1"
    echo -e "\e[94m$message\e[0m"
}

# برای نمایش پیام موفقیت آمیز به رنگ پررنگ آبی
function success() {
    message="$1"
    echo -e "\e[1;94m$message\e[0m"
}

# برای نمایش ارورها به رنگ قرمز
function error() {
    message="$1"
    echo -e "\e[91m$message\e[0m"
}

# برای دریافت ورودی ها به رنگ نارنجی
function input() {
    message="$1"
    name="$2"
    read -p "$(echo -e '\e[33m'"$message"'\e[0m')" "$name"
}

# Welcome
# اینتروی اسکریپت
clear
print '\n\n\tWelcome to Backup script'
print '\t\tBy @Ac-Lover\n'
print '----------------------------------'


# Bot token
# گرفتن توکن ربات از کاربر و ذخیره آن در متغیر tk
while [[ -z "$tk" ]]; do
    input "\nTelegram Bot Token (of @BotFather): " "tk"
    if [[ $tk == $'\0' ]]; then
        error "Invalid input. Token cannot be empty."
        unset tk
    fi
done

# Chat id
# گرفتن Chat ID از کاربر و ذخیره آن در متغیر chatid
while [[ -z "$chatid" ]]; do
    input "\nTelegram Chat id (of @userinfobot): " "chatid"
    if [[ $chatid == $'\0' ]]; then
        error "Invalid input. Chat id cannot be empty. try again..."
        unset chatid
    elif [[ ! $chatid =~ ^\-?[0-9]+$ ]]; then
        error "${chatid} is not a number. try again..."
        unset chatid
    fi
done

# Caption
# گرفتن عنوان برای فایل پشتیبان و ذخیره آن در متغیر caption
input "\nCaption (for example, your domain, to identify the database file more easily): " "caption"

# Cronjob
# تعیین زمانی برای اجرای این اسکریپت به صورت  دوره‌ای برحسب دقیقه
while true; do
    input "\ncronjob time in minutes (not more than 1440) (e.g: 80 or 40 or 1440): " "interval"
    if [[ $interval =~ ^[0-9]+$ ]]; then
        if [[ $interval -eq 1 ]]; then
            cron_time="* * * * *"
            break
        elif [[ $interval -eq 0 ]]; then
            error "Invalid input. Please enter a number greater than zero."
        elif [[ $interval -le 1440 ]]; then
            cron_hour=$(( interval / 60 ))
            cron_minute=$(( interval % 60 ))
            if [[ $cron_hour -eq 0 ]]; then
                cron_hour="*"
            fi
            cron_time="*/${cron_minute} */${cron_hour} * * *"
            break
        else
            error "Invalid input. Please enter a number less than or equal to 1440."
        fi
    else
        error "Invalid input. Please enter a valid number."
    fi
done



# x-ui or marzban or hiddify
# گرفتن نوع نرم افزاری که می‌خواهیم پشتیبانی از آن بگیریم و ذخیره آن در متغیر xmh
while [[ -z "$xmh" ]]; do
    input "\nx-ui or marzban or hiddify? [x/m/h] : " "xmh"
    if [[ $xmh == $'\0' ]]; then
        error "Invalid input. Please choose x, m or h."
        unset xmh
    elif [[ ! $xmh =~ ^[xmh]$ ]]; then
        error "${xmh} is not a valid option. Please choose x, m or h."
        unset xmh
    fi
done

while [[ -z "$crontabs" ]]; do
    input "\nWould you like the previous crontabs to be cleared? [y/n] : " "crontabs"
    if [[ $crontabs == $'\0' ]]; then
        error "Invalid input. Please choose y or n."
        unset crontabs
    elif [[ ! $crontabs =~ ^[yn]$ ]]; then
        error "${crontabs} is not a valid option. Please choose y or n."
        unset crontabs
    fi
done

if [[ "$crontabs" == "y" ]]; then
# remove cronjobs
sudo crontab -l | grep -vE '/root/ac-backup.+\.sh' | crontab -
fi


# m backup
# ساخت فایل پشتیبانی برای نرم‌افزار Marzban و ذخیره آن در فایل ac-backup.zip
if [[ "$xmh" == "m" ]]; then

if dir=$(find /opt /root -type d -iname "marzban" -print -quit); then
  success "The folder exists at $dir"
else
  error "The folder does not exist."
  exit 1
fi

if [ -d "/var/lib/marzban/mysql" ]; then

  sed -i -e 's/\s*=\s*/=/' -e 's/\s*:\s*/:/' -e 's/^\s*//' /opt/marzban/.env

  docker exec marzban-mysql-1 bash -c "mkdir -p /var/lib/mysql/db-backup"
  source /opt/marzban/.env

    cat > "/var/lib/marzban/mysql/ac-backup.sh" <<EOL
#!/bin/bash

USER="root"
PASSWORD="$MYSQL_ROOT_PASSWORD"


databases=\$(mysql -h 127.0.0.1 --user=\$USER --password=\$PASSWORD -e "SHOW DATABASES;" | tr -d "| " | grep -v Database)

for db in \$databases; do
    if [[ "\$db" != "information_schema" ]] && [[ "\$db" != "mysql" ]] && [[ "\$db" != "performance_schema" ]] && [[ "\$db" != "sys" ]] ; then
        echo "Dumping database: \$db"
		mysqldump -h 127.0.0.1 --force --opt --user=\$USER --password=\$PASSWORD --databases \$db > /var/lib/mysql/db-backup/\$db.sql

    fi
done

EOL
chmod +x /var/lib/marzban/mysql/ac-backup.sh

ZIP=$(cat <<EOF
docker exec marzban-mysql-1 bash -c "/var/lib/mysql/ac-backup.sh"
zip -r /root/ac-backup-m.zip /opt/marzban/* /var/lib/marzban/* /opt/marzban/.env -x /var/lib/marzban/mysql/\*
zip -r /root/ac-backup-m.zip /var/lib/marzban/mysql/db-backup/*
rm -rf /var/lib/marzban/mysql/db-backup/*
EOF
)

    else
      ZIP="zip -r /root/ac-backup-m.zip ${dir}/* /var/lib/marzban/* /opt/marzban/.env"
fi

ACLover="marzban backup"

# x-ui backup
# ساخت فایل پشتیبانی برای نرم‌افزار X-UI و ذخیره آن در فایل ac-backup.zip
elif [[ "$xmh" == "x" ]]; then

if dbDir=$(find /etc /opt/freedom -type d -iname "x-ui*" -print -quit); then
  success "The folder exists at $dbDir"
  if [[ $dbDir == *"/opt/freedom/x-ui"* ]]; then
     dbDir="${dbDir}/db/"
  fi
else
  error "The folder does not exist."
  exit 1
fi

if configDir=$(find /usr/local -type d -iname "x-ui*" -print -quit); then
  success "The folder exists at $configDir"
else
  error "The folder does not exist."
  exit 1
fi

ZIP="zip /root/ac-backup-x.zip ${dbDir}/x-ui.db ${configDir}/config.json"
ACLover="x-ui backup"

# hiddify backup
# ساخت فایل پشتیبانی برای نرم‌افزار Hiddify و ذخیره آن در فایل ac-backup.zip
elif [[ "$xmh" == "h" ]]; then

if ! find /opt/hiddify-manager/hiddify-panel/ -type d -iname "backup" -print -quit; then
  error "The folder does not exist."
  exit 1
fi

ZIP=$(cat <<EOF
cd /opt/hiddify-manager/hiddify-panel/
if [ $(find /opt/hiddify-manager/hiddify-panel/backup -type f | wc -l) -gt 100 ]; then
  find /opt/hiddify-manager/hiddify-panel/backup -type f -delete
fi
python3 -m hiddifypanel backup
cd /opt/hiddify-manager/hiddify-panel/backup
latest_file=\$(ls -t *.json | head -n1)
rm -f /root/ac-backup-h.zip
zip /root/ac-backup-h.zip /opt/hiddify-manager/hiddify-panel/backup/\$latest_file

EOF
)
ACLover="hiddify backup"
else
error "Please choose m or x or h only !"
exit 1
fi


trim() {
    # remove leading and trailing whitespace/lines
    local var="$*"
    # remove leading whitespace characters
    var="${var#"${var%%[![:space:]]*}"}"
    # remove trailing whitespace characters
    var="${var%"${var##*[![:space:]]}"}"
    echo -n "$var"
}

IP=$(ip route get 1 | sed -n 's/^.*src \([0-9.]*\) .*$/\1/p')
caption="${caption}\n\n${ACLover}\n<code>${IP}</code>\nCreated by @AC_Lover - https://github.com/AC-Lover/backup"
comment=$(echo -e "$caption" | sed 's/<code>//g;s/<\/code>//g')
comment=$(trim "$comment")

# install zip
# نصب پکیج zip
sudo apt install zip -y

# send backup to telegram
# ارسال فایل پشتیبانی به تلگرام
cat > "/root/ac-backup-${xmh}.sh" <<EOL
rm -rf /root/ac-backup-${xmh}.zip
$ZIP
echo -e "$comment" | zip -z /root/ac-backup-${xmh}.zip
curl -F chat_id="${chatid}" -F caption=\$'${caption}' -F parse_mode="HTML" -F document=@"/root/ac-backup-${xmh}.zip" https://api.telegram.org/bot${tk}/sendDocument
EOL


# Add cronjob
# افزودن کرانجاب جدید برای اجرای دوره‌ای این اسکریپت
{ crontab -l -u root; echo "${cron_time} /bin/bash /root/ac-backup-${xmh}.sh >/dev/null 2>&1"; } | crontab -u root -

# run the script
# اجرای این اسکریپت
bash "/root/ac-backup-${xmh}.sh"

# Done
# پایان اجرای اسکریپت
success "\n\n\tDone with @Ac_Lover !"
success "\t\t⭐ Don't Forget...\n\n"
