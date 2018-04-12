#!/usr/bin/env bash

# Exit the script as soon as something fails.
set -e

REDIRECTS=()

DEFAULT_SERVER_FILE=$NGINX_INSTALL_PATH/conf.d/default_server.conf
REDIRECTS_FILE=$NGINX_INSTALL_PATH/conf.d/redirects.conf

redirect_exists () {
  for i in "${REDIRECTS[@]}"; do
    if [[ "$1" == "$i" ]]; then
      return 0
    fi
  done

  return 1
}

function create_redirect() {
cat <<EOF
server {
  listen 80;

  server_name ${2};

  location = /health_check {
    return 200;
    access_log off;
  }

  location / {
    return ${3} ${1}\$request_uri;
  }
}
EOF
}

if [[ "$SERVER_REDIRECTS" == "" ]]; then
  echo "No redirect(s) defined!"
else
  echo "" > $REDIRECTS_FILE

  IFS=',' read -ra PROVIDED_REDIRECTS <<< "$SERVER_REDIRECTS"
  IFS=$'\n' SORTED_REDIRECTS=($(sort -r <<<"${PROVIDED_REDIRECTS[*]}"))

  for redirect in "${SORTED_REDIRECTS[@]}"; do
    IFS='%' read -ra SETTINGS <<< "$redirect"

    if (( ${#SETTINGS[@]} >= 1 )); then
      dest="${SETTINGS[0]}"
      source="${SETTINGS[1]:-_}"
      code="${SETTINGS[2]:-302}"

      if redirect_exists $source; then
        echo "WARNING! Duplicate redirect source defined: '$source' :: Using existing redirect..."
      elif [[ "$code" == "301" || "$code" == "302" ]]; then
        echo "Configuring NGINX redirect: ($code) '$source' -> '$dest'"

        if [[ "$source" == "_" && -f $DEFAULT_SERVER_FILE ]]; then
          echo "No source provided, removing default server config..."
          rm $DEFAULT_SERVER_FILE
        fi

        REDIRECTS+=("$source")
        echo "$(create_redirect $dest $source $code)" >> $REDIRECTS_FILE
      else
        echo "ERROR! Invalid redirect HTTP code provided: '$code' (must be 301 or 302)"
        exit 1
      fi
    fi
  done
fi

nginx -t

# Execute the CMD from the Dockerfile and pass in all of its arguments.
exec "$@"
