#!/bin/bash
error='\033[37m\033[41m'
success='\033[30m\033[42m'
warning='\033[30m\033[43m'
info='\033[37m\033[44m'
blue='\033[34m'
yellow='\033[33m'
green='\033[32m'
clr='\033[0m'
verbose=0

parse_options() {
    while [[ "$#" -gt 0 ]]; do
        case $1 in
            -v|--verbose) verbose=1 ;;
        esac
        shift
    done
}

spinner() {
  chars="◐◓◑◒"

  while :; do
    for ((i = 0; i < ${#chars}; i++)); do
      sleep 0.5
      echo -en "$1 ${chars:$i:1}" "\r"
    done
  done
}

execute() {
    if [ $verbose -eq 1 ] ; then
        "$@"
    else
        "$@" > /dev/null 2>&1
    fi
}

set_app_name() {
  APP_NAME="sword"

  echo "$1" | grep -Pq '^(?!-+)[\w_-]+$'
  RESULT=$?

  if [ $# -gt 0 ] || [ $RESULT -eq 0 ]; then
    APP_NAME=$1
  fi
}

set_free_port() {
  FREE_PORT_SITE=$(comm -23 <({ echo 443; seq 8080 8100; }) <(nmap --min-hostgroup 100 -p 443,8080-8100 -sS -n -T4 host.docker.internal | grep 'open' | awk '{print $1}' | cut -d'/' -f1) | head -n 1)
  sudo -u appuser sed -i "s/443:443/$FREE_PORT_SITE:443/g" docker-compose.yml

  URL_SITE=https://$APP_NAME.localhost
  URL_MAIL=https://$APP_NAME-mail.localhost

  if [ "$FREE_PORT_SITE" -ne 443 ]; then
    URL_SITE=$URL_SITE:$FREE_PORT_SITE
    URL_MAIL=$URL_MAIL:$FREE_PORT_SITE
  fi
}

install() {
  mkdir -p /app/"$APP_NAME"

  if [ -z "$(ls -A /app/"$APP_NAME"/)" ]; then
    cd /srv/files/ || return 1
    cp -R . /app/"$APP_NAME"/

    cd /app/"$APP_NAME"/ || return 1

    sed -i "s@APP_NAME=sword@APP_NAME=$APP_NAME@g" .env
    sed -i "/PROJECT_DIR=/d" .env
    echo "PROJECT_DIR=$APP_NAME" >> .env
    sed -i "s@- ./@- $HOST_PWD/$APP_NAME/@g" docker-compose.yml
  fi

  chown -R appuser:appgroup /app/"$APP_NAME"
  cd /app/"$APP_NAME"/ || return 1

  set_free_port

  docker compose up -d
  chown -R appuser:appgroup .
  setfacl -R -m u:appuser:rwX -m u:www-data:rwX -m u:82:rwX .
  setfacl -dR -m u:appuser:rwX -m u:www-data:rwX -m u:82:rwX .
}

main() {
  parse_options "$@"
  set_app_name "$@"

  tput civis

  echo ''
  echo -e "$success                                                                                                                        $clr"
  echo -e "$success Sword installation in progress                                                                                    $clr"
  echo -e "$success                                                                                                                        $clr"
  echo ''
  echo "Creating new project in ./$APP_NAME directory."
  spinner 'Please wait while preparing your project...' &
  PID=$!

  execute install
  RESULT=$?

  kill $PID
  tput cnorm

  if [ $RESULT -eq 0 ]; then
    echo ''
    echo ''
    echo -e "$info                                                                                                                        $clr"
    echo -e "$info What's next?                                                                                                           $clr"
    echo -e "$info                                                                                                                        $clr"
    echo ''
    echo -e "  * ${blue}Read$clr the documentation at ${yellow}https://getsword.com$clr"
    echo ''
    echo -e "  * ${blue}Go$clr to ${yellow}$URL_SITE$clr to access your website"
    echo ''
    echo -e "  * ${blue}Go$clr to ${yellow}$URL_MAIL$clr to check mails sent by Symfony or WordPress"
  else
    if [ $verbose -eq 0 ]; then
      echo ''
      echo ''
      echo -e "$error                                                                                                                        $clr"
      echo -e "$error An error occurred during installation. What to do next?                                                                $clr"
      echo -e "$error                                                                                                                        $clr"
      echo ''
      echo -e "  * ${blue}Remove$clr the Docker environment with ${yellow}cd $APP_NAME && docker compose down$clr"
      echo ''
      echo -e "  * ${blue}Remove$clr the project with ${yellow}rm -rf $HOST_PWD/$APP_NAME$clr"
      echo ''
      echo -e "  * ${blue}Relaunch$clr installation with ${yellow}-v${clr} or ${yellow}--verbose${clr} at the end of the command line"
      echo ''
      echo -e "  * Alternatively, try a manual installation. Check the documentation at ${yellow}https://getsword.com$clr"
    fi
  fi
}

main "$@"
