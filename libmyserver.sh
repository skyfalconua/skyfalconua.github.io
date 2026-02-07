# libmyserver.sh v2026.2.7
# https://skyfalconua.github.io/libmyserver.sh

#- ./lib/utils.sh

_inline_echo() {
  printf "%s\n" "$1"
}

is_enabled() {
  local param=$(echo "$1" | tr '[:upper:]' '[:lower:]')
  [ "$param" = "true" ] || [ "$param" = "yes" ] || [ "$param" = "on" ] || [ "$param" = "1" ]
}

user_exists(){
  id "$1" &>/dev/null
}

color() {
  case "$1" in
    red) printf '\033[0;31m' ;;
    green) printf '\033[0;32m' ;;
    yellow) printf '\033[0;33m' ;;
    blue) printf '\033[0;34m' ;;
    magenta) printf '\033[0;35m' ;;
    cyan) printf '\033[0;36m' ;;
    *) printf '\033[0m' ;;
  esac
}

echo_step() {
  printf "$(color green)* $1 *$(color)\n\n"
}

echo_warn() {
  printf "$(color yellow)$1$(color)\n\n"
}

echo_action() {
  printf "$(color cyan)$1$(color)\n"
}

read_envfile() {
  # example:
  #   read_envfile \
  #     'ENV=' \
  #     '#USE_PARAM=yes'

  check_variables LIBMYSERVER_ENVFILE
  if [ -z "${LIBMYSERVER_ENVFILE}" ] ; then
    echo "Error: LIBMYSERVER_ENVFILE variable is not set"
    exit
  fi

  # Create envfile with commented placeholders if it doesn't exist
  if [ ! -f "$LIBMYSERVER_ENVFILE" ] ; then
    for keyval in "$@"; do
      echo "$keyval" >> "$LIBMYSERVER_ENVFILE"
    done
  fi

  # Reset all specified variables to empty strings
  local resetvars=""
  for key in "$@"; do
    key="${key#\#}"   # Strip leading '#' (comments)
    key="${key%%=*}"  # Strip everything from '=' to the end
    resetvars="$resetvars $key="
  done
  export $(echo "$resetvars __placeholder")

  # Load non-comment lines from envfile and export as environment variables
  local newvars="$(grep -v '^\s*#' "$LIBMYSERVER_ENVFILE" | tr '\n' ' ')"
  export $(echo "$newvars __placeholder")
}

check_variables() {
  local key=""
  local val=""
  local missing=""

  for key in "$@"; do
    key=$(echo "$key" | tr -cd '[:alnum:]_')
    val=$(eval "echo \$$key")

    if [ -z "$val" ]; then
      missing="$missing $key"
    fi
  done

  if [ -n "$missing" ]; then
    echo "parameters are missing:$missing"
    echo
    if [ -n "${LIBMYSERVER_ENVFILE}" ]; then
      echo " add them ${LIBMYSERVER_ENVFILE}"
    fi
    exit
  fi
}

render_variables() {
  local content=$(cat)
  local varname=""
  local varvalue=""

  for varname in "$@"; do
    local key=$(printf '%s' "$varname" | tr -cd '[:alnum:]_')
    eval "varvalue=\"\${$key}\""

    content=$(printf '%s' "$content" | sed "s#__${key}__#${varvalue}#g")
  done

  printf '%s' "$content"
}

save_to() {
  local filename="$1"
  cat | tee "$filename" > /dev/null
}

#- ./templates/nginx/container.nginx

template__nginx_container_nginx() {
  local E=_inline_echo
  $E "server {"
  $E "  listen 9000;"
  $E ""
  $E "  location / {"
  $E "    root /opt/bitnami/nginx/html;"
  $E "    try_files \$uri @mainsite;"
  $E ""
  $E "    expires max;"
  $E "    access_log off;"
  $E "  }"
  $E ""
  $E "  location @mainsite {"
  $E "    proxy_pass http://__PROJECTNAME__-__ENV__-web:8000;"
  $E "    proxy_set_header Host \$http_host;"
  $E "    proxy_set_header X-Real-IP \$remote_addr;"
  $E "    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;"
  $E "    proxy_set_header X-Forwarded-Proto \$scheme;"
  $E "    proxy_redirect off;"
  $E "  }"
  $E ""
  if is_enabled "${USE_DJANGO}"; then
  $E "  location /static/ {"
  $E "    alias /volumes/static/;"
  $E "  }"
  $E ""
  $E "  location /media/ {"
  $E "    alias /volumes/media/;"
  $E "  }"
  fi
  $E "}"
}

#- ./templates/nginx/system.nginx

template__nginx_system_nginx() {
  local E=_inline_echo
  $E "server {"
  $E "  server_name __HOST__;"
  $E "  listen 80;"
  $E ""
  if is_enabled "${USE_LEGO}"; then
  $E "  # optional"
  $E "  location /.well-known/acme-challenge {"
  $E "    proxy_pass http://127.0.0.1:81;"
  $E "    proxy_set_header Host \$host;"
  $E "  }"
  fi
  $E ""
  $E "  location / {"
  $E "    return 302 https://__HOST__\$request_uri;"
  $E "  }"
  $E "}"
  $E ""
  $E "server {"
  $E "  server_name __HOST__;"
  $E "  listen 443 ssl;"
  $E ""
  $E "  __SSL_OPTIONS__"
  $E "  ssl_certificate      __CERTFILE__;"
  $E "  ssl_certificate_key  __KEYFILE__;"
  $E ""
  $E "  location / {"
  $E "    proxy_pass http://127.0.0.1:__PORT__;"
  $E "    proxy_set_header Host \$http_host;"
  $E "    proxy_set_header X-Real-IP \$remote_addr;"
  $E "    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;"
  $E "    proxy_set_header X-Forwarded-Proto \$scheme;"
  $E "    proxy_redirect off;"
  $E "  }"
  $E "}"
}

#- ./templates/nginx/placeholder.crt

template__nginx_placeholder_crt() {
  local E=_inline_echo
  $E "-----BEGIN CERTIFICATE-----"
  $E "MIIDeTCCAmGgAwIBAgIUakn1fM62TFV6ilpBRhXlRDHhZV8wDQYJKoZIhvcNAQEL"
  $E "BQAwPzELMAkGA1UEBhMCQ0ExCzAJBgNVBAgMAlFDMQ0wCwYDVQQKDARTZWxmMRQw"
  $E "EgYDVQQDDAtkZWZhdWx0LmNvbTAgFw0yNDA0MjMxNzM2MDZaGA8yMDUxMDkwODE3"
  $E "MzYwNlowPzELMAkGA1UEBhMCQ0ExCzAJBgNVBAgMAlFDMQ0wCwYDVQQKDARTZWxm"
  $E "MRQwEgYDVQQDDAtkZWZhdWx0LmNvbTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCC"
  $E "AQoCggEBAKduYeuBwwEOnCw9svieCwqpHHgaF0TYUlQVQmS6/PC/tmstG/kXil1j"
  $E "avM6obtt/QHl3t4sAlC3EeRcWCTEbuyeS7H23TGxY0Id3Bh2G2E0/qKnXebnfWSb"
  $E "3y9bwAQBT4KXQZag2DF7YtzCkpob+ViZFObLejWjwhRUvbr2H7Ou+gcG3qflTJL/"
  $E "f1w3zkQutVQuOoiUGJRtiF3Qw2TKcWTlPNK4JJhOBCbnsfS25lQYBbHl9FJUlbPq"
  $E "hGRHb5qnhPtOi4yifUUs7+UHKBtFktDUP7VOW2bo9Ogg2ELSpjidJKyZ+k2GmDhi"
  $E "kCcEiN5zgAG5p3UONsNOekkzD9cUlrUCAwEAAaNrMGkwHQYDVR0OBBYEFH+HVfbM"
  $E "hQIX9re4DEJyM1GqCLDdMB8GA1UdIwQYMBaAFH+HVfbMhQIX9re4DEJyM1GqCLDd"
  $E "MA8GA1UdEwEB/wQFMAMBAf8wFgYDVR0RBA8wDYILZGVmYXVsdC5jb20wDQYJKoZI"
  $E "hvcNAQELBQADggEBABTGbby5b7lMFP5ZgsvLmK55P5lhgKcM7Ms3+DOcyoKUab+0"
  $E "J5wxqIUK+iPV/rbv6WUIGeRo9gfN+EYr0h1jZpRvIiSxL9HNZJJ/QYGJiUpUWE4f"
  $E "iquBHCVRjl3TvzLDS2HpP23ynet9wNWrI40XYxBYF0XcXQM38+BQwo/zfx5BIQEn"
  $E "Qs1XioqKr3281w0cvDZ4sfM0JzZTxXB+A1QBY4gr80EHMXTtIgcXOpIDDCgXeG1e"
  $E "XoR37P6eptLNjoWTWvtMy2M1eQ8m6CWNUZu7TjTHYEcMVf9lR0WV1PrI9YUJBP94"
  $E "VEyYrZP6wYT5fqrCwxjxw6tO7u3dxrE+/f0AqGc="
  $E "-----END CERTIFICATE-----"
}

#- ./templates/nginx/placeholder.key

template__nginx_placeholder_key() {
  local E=_inline_echo
  $E "-----BEGIN PRIVATE KEY-----"
  $E "MIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQCnbmHrgcMBDpws"
  $E "PbL4ngsKqRx4GhdE2FJUFUJkuvzwv7ZrLRv5F4pdY2rzOqG7bf0B5d7eLAJQtxHk"
  $E "XFgkxG7snkux9t0xsWNCHdwYdhthNP6ip13m531km98vW8AEAU+Cl0GWoNgxe2Lc"
  $E "wpKaG/lYmRTmy3o1o8IUVL269h+zrvoHBt6n5UyS/39cN85ELrVULjqIlBiUbYhd"
  $E "0MNkynFk5TzSuCSYTgQm57H0tuZUGAWx5fRSVJWz6oRkR2+ap4T7TouMon1FLO/l"
  $E "BygbRZLQ1D+1Tltm6PToINhC0qY4nSSsmfpNhpg4YpAnBIjec4ABuad1DjbDTnpJ"
  $E "Mw/XFJa1AgMBAAECggEAHQFk6lE5EKJQ0ONBcYujmw2v9miCtnUJUjK6pUu1jRmR"
  $E "RyDx8yWuXT5fZVK3eQp1ZdJGWVPjdMs6SMbsqDX1h31m3KZJLJYv/WDB4+T2GlF9"
  $E "eX0oKdvZn8fXEtPAwJDfjt6YSLmFqpDXECqPDi6hdEVU1yTR/5/me/IwSkbgOBbk"
  $E "pIDGyPDUDvLcW0OQQdcSaZC7UUahkcVV/ueaYVf2Qr7NlbKSKZ8BsTf04DEuJzuY"
  $E "Wxm9McbQfesvVFeMA64FGyO15EOcRAl3XyhAsP1aN0wsU+tAlC8od0y4rM9qIGB0"
  $E "qu3IO9oaVcAqgrlYSAoEbcy/19TOyTf4QLlnFb2mYwKBgQDeUb3X/YC7nvkxlpD5"
  $E "gwCT+j9G8w1RL8xJeD9yrrlyF/Zad7Q+PMICk94WpOl6mjBNeJihjpcwd5E0oZW8"
  $E "vrVU8hd7XdRp9dWiCrKApmURMfaH11KhhNFbbOndopj2K4ZHc3Vrc8/k71vjbbV5"
  $E "PTEIJ95BiQQTh/YbJhg7TEBZrwKBgQDAy+cgfVPv3+E0jJhx5QNUCU8zZSOu9AER"
  $E "tHSjkMC5QAjALxDBYrmDL+bBpsTsdJBpTRA2FUMn9LtprdE/KOEig8pv3cc+IB67"
  $E "owdUK2zubFDS0kGovJykK4lqXMJl+Vi553mEAHR7zDMfVqFZq1T4OLaBljTxTGWn"
  $E "Mk9cQZOC2wKBgBKNZbdJi12c1ZTCyNRZj0nJ/0/PZpQY1gZnh3vtgsI3p7JC/QKY"
  $E "lWQbrNPc7TLy/QbqAmqw+ILt52sp9NHsZDtzfGwqF1jEUBCWrfC4cgSuU7FgUZ/y"
  $E "8nmbrCR3tiYM2cbKpsjRwE6NfvCKrjMw3Q+eLBjx8yoiFXKMikcghNo3AoGAQYLH"
  $E "pY2QgPjE8HM5tbHIwLxtEhyy1FcLKfX0kEO2iPwOPSeA/QVL3hzfvzuovGQbUfyi"
  $E "no35BNGvAQjUCi8c2PqJRhvJAP4vEzkhW2NqH1Xk3M4fC3QTkeFNTzv3vmjM0laq"
  $E "PsVcz1gioupv5yVFuRakRUJB+SAphnec6c9KjXMCgYEAtKxqzTbcp38/2n05C18g"
  $E "IKAGyd2CAe8rshDqojuUbBh7Ky7lmJRoPc+BlodfNxibdhZrmUPOgVZizgTgGWhW"
  $E "VB+kzycme+n1E19RdXpIAxe2CEaMNhz+Eklxc8Rsmuon2bKnfOsko4VCLn2aiPnN"
  $E "qrCnFQde32d3XLh9x+8oOOg="
  $E "-----END PRIVATE KEY-----"
}

#- ./templates/nginx/robots-dev.txt

template__nginx_robots_dev_txt() {
  local E=_inline_echo
  $E "User-agent: *"
  $E "Disallow: /"
}

#- ./templates/nginx/robots-prod.txt

template__nginx_robots_prod_txt() {
  local E=_inline_echo
  $E "User-agent: *"
  $E "Allow: /"
  $E "Sitemap: https://__HOST__/sitemap.xml"
}

#- ./templates/podman/ConfigMap.yaml

template__podman_ConfigMap_yaml() {
  local E=_inline_echo
  $E "apiVersion: v1"
  $E "kind: ConfigMap"
  $E "metadata:"
  $E "  name: __PROJECTNAME__-__ENV__"
  $E "data:"
  $E "  ENV: __ENV__"
  $E "  HOST: __HOST__"
  for arg in "$@"; do
    $E "$arg: __$arg__"
  done
}

#- ./templates/podman/Podman.yaml

template__podman_Podman_yaml() {
  local E=_inline_echo
  $E "apiVersion: v1"
  $E "kind: Pod"
  $E "metadata:"
  $E "  labels:"
  $E "    app: __PROJECTNAME__-__ENV__"
  $E "  name: __PROJECTNAME__-__ENV__"
  $E ""
  $E "spec:"
  $E "  containers:"
  $E "    - image: '__PROJECTNAME__-__ENV__/web'"
  $E "      name: web"
  $E "      envFrom: # -> ./ .. /ConfigMap.yaml"
  $E "        - configMapRef:"
  $E "            name: __PROJECTNAME__-__ENV__"
  if is_enabled "${USE_DJANGO}"; then
  $E "      volumeMounts:"
  $E "        - mountPath: /volumes/static"
  $E "          name: __PROJECTNAME__-__ENV__-static_volume_pvc"
  $E "        - mountPath: /volumes/media"
  $E "          name: __PROJECTNAME__-__ENV__-media_volume_pvc"
  fi
  $E ""
  if is_enabled "${USE_DJANGO}"; then
  $E "    - image: docker.io/bitnami/mariadb"
  $E "      name: db"
  $E "      env:"
  $E "        - name: MARIADB_ROOT_PASSWORD"
  $E "          value: rootpassword"
  $E "        - name: MARIADB_PASSWORD"
  $E "          value: __PROJECTNAME__password"
  $E "        - name: MARIADB_USER"
  $E "          value: __PROJECTNAME__user"
  $E "        - name: MARIADB_DATABASE"
  $E "          value: __PROJECTNAME__db"
  $E "      volumeMounts:"
  $E "        - mountPath: /bitnami/mariadb"
  $E "          name: __PROJECTNAME__-__ENV__-db_volume_pvc"
  fi
  $E ""
  $E "    - image: '__PROJECTNAME__-__ENV__/nginx'"
  $E "      name: nginx"
  $E "      args:"
  $E "        - nginx"
  $E "        - '-g'"
  $E "        - daemon off;"
  $E "      ports:"
  $E "        - containerPort: 9000"
  $E "          hostPort: __OUTPORT__"
  if is_enabled "${USE_DJANGO}"; then
  $E "      volumeMounts:"
  $E "        - mountPath: /volumes/media"
  $E "          name: __PROJECTNAME__-__ENV__-media_volume_pvc"
  $E "        - mountPath: /volumes/static"
  $E "          name: __PROJECTNAME__-__ENV__-static_volume_pvc"
  fi
  $E ""
  if is_enabled "${USE_DJANGO}"; then
  $E "  volumes:"
  $E "    - name: __PROJECTNAME__-__ENV__-db_volume_pvc"
  $E "      persistentVolumeClaim:"
  $E "        claimName: __PROJECTNAME__-__ENV__-db_volume"
  $E "    - name: __PROJECTNAME__-__ENV__-media_volume_pvc"
  $E "      persistentVolumeClaim:"
  $E "        claimName: __PROJECTNAME__-__ENV__-media_volume"
  $E "    - name: __PROJECTNAME__-__ENV__-static_volume_pvc"
  $E "      persistentVolumeClaim:"
  $E "        claimName: __PROJECTNAME__-__ENV__-static_volume"
  fi
}

#- ./templates/podman/systemd.conf

template__podman_systemd_conf() {
  local E=_inline_echo
  $E "[Unit]"
  $E "Description=__PROJECTNAME__-__ENV__ container"
  $E ""
  $E "[Install]"
  $E "WantedBy=default.target"
  $E ""
  $E "[Service]"
  $E "Restart=always"
  $E ""
  $E "[Kube]"
  $E "Yaml=__PROJECTROOT__/var/configs/Podman.yaml"
  $E "ConfigMap=__PROJECTROOT__/var/configs/ConfigMap.yaml"
}

#- ./lib/nginx.sh

_copy_cloudflare_certificate() {
  check_variables PROJECTROOT HOST

  local certdir="$1"
  sudo mkdir -p "$certdir"

  # Cloudflare origin CA certificate
  local crtfile="$PROJECTROOT/var/certificates/cloudflare.crt"
  local keyfile="$PROJECTROOT/var/certificates/cloudflare.key"

  if [ ! -f "$crtfile" ] || [ ! -f "$keyfile" ]; then
    echo_warn "Cloudflare origin CA certificate was not found. Obtain it here:"
    echo_warn "  https://dash.cloudflare.com/?to=/:account/:zone/ssl-tls/origin"
    echo_warn "Then put them to:"
    echo_warn "  - ./var/certificates/cloudflare.crt"
    echo_warn "  - ./var/certificates/cloudflare.key"
    exit
  fi

  curl -sL https://developers.cloudflare.com/ssl/static/authenticated_origin_pull_ca.pem \
    > "$certdir/cloudflare_aop_ca.crt"
  chmod 644 "$certdir/cloudflare_aop_ca.crt"

  cat "$crtfile" | save_to "$certdir/$HOST.crt"
  chmod 644 "$certdir/$HOST.crt"

  cat "$keyfile" | save_to "$certdir/$HOST.key"
  chmod 640 "$certdir/$HOST.key"
}

_copy_lego_placeholders() {
  check_variables PROJECTROOT HOST

  local certdir="$1"
  sudo mkdir -p "$certdir"

  local crtfile="${certdir}/$HOST.crt"
  local keyfile="${certdir}/$HOST.key"

  if [ ! -f "$crtfile" ]; then
    template__nginx_placeholder_crt | save_to "$crtfile";
  fi

  if [ ! -f "$keyfile" ]; then
    template__nginx_placeholder_key | save_to "$keyfile";
  fi
}

init_nginx_config() {
  check_variables PROJECTROOT HOST PORT

  echo | save_to /usr/share/nginx/html/index.html;

  local conffile="/etc/nginx/conf.d/$HOST.conf"
  local certdir="" # for cloudflare or lego only
  local ssl_configured=""

  local SSL_OPTIONS=""  # Placeholder for unused legacy variable
  local CERTFILE=""
  local KEYFILE=""

  # -- use cloudflare proxy -- -- --

  if is_enabled "$USE_CLOUDFLARE"; then
    certdir="/opt/certificates/cloudflare"

    SSL_OPTIONS="ssl_client_certificate /opt/certificates/cloudflare_aop_ca.crt;"
    SSL_OPTIONS="$SSL_OPTIONS\n  ssl_verify_client on;"
    CERTFILE="$certdir/$HOST.crt"
    KEYFILE="$certdir/$HOST.key"

    ssl_configured="yes"
    _copy_cloudflare_certificate "$certdir"
  fi

  # -- use go-acme/lego cli -- -- --

  if is_enabled "$USE_LEGO"; then
    certdir="/opt/certificates/lego"

    SSL_OPTIONS=""
    CERTFILE="$certdir/$HOST.crt"
    KEYFILE="$certdir/$HOST.key"

    ssl_configured="yes"
    _copy_lego_placeholders "$certdir"
  fi

  # -- use nginx/nginx-acme module -- -- --

  if is_enabled "$USE_NGXACME"; then
    SSL_OPTIONS="acme_certificate letsencrypt;"
    SSL_OPTIONS="$SSL_OPTIONS\n  ssl_certificate_cache max=2;"

    CERTFILE="\$acme_certificate"
    KEYFILE="\$acme_certificate_key"

    ssl_configured="yes"
    _copy_lego_placeholders "$certdir"
  fi

  # -- ensure ssl configured -- -- --

  if ! is_enabled "$ssl_configured"; then
    echo_warn "One of these parameters is required - USE_CLOUDFLARE, USE_LEGO, USE_NGXACME"
    exit
  fi

  # -- create config -- -- --

  echo_step "Create $conffile"
  template__nginx_system_nginx | \
    render_variables HOST PORT SSL_OPTIONS CERTFILE KEYFILE | \
    save_to "$conffile"
  echo

  # -- reload nginx -- -- --

  echo_step "Reload nginx config"
  sudo nginx -s reload
}

#- ./lib/lego.sh

add_cron_script() {
  local cronscript="$1"
  local cronjob="$2"
  (crontab -l | grep -v -F "$cronscript" || true ; set -f ; echo "$cronjob" ) | crontab -
}

_lego_echo_renew_certificate() {
  check_variables EMAIL
  local host="$1"

  local token_prefix=""
  local logfile="/opt/cron/logs/update_${host}_host.log"
  local params1="-m ${EMAIL} -d ${host} --path=/opt/lego --accept-tos"

  local params2=""
  if [ -n "$USE_CF_DNS_API_TOKEN" ]; then
    token_prefix="CF_DNS_API_TOKEN=\"${USE_CF_DNS_API_TOKEN}\" "
    params2="--dns cloudflare"
  else
    params2="--http --http.port=:81"
  fi

  local E="_inline_echo"
  $E ""
  $E "runlego() {"
  $E "  echo && \\"
  $E "  ${token_prefix}$(which lego) \\"
  $E "    ${params1} \\"
  $E "    ${params2} renew 2>&1"
  $E "}"
  $E "runlego >> ${logfile}"
  $E "nginx -s reload"
  $E "systemctl restart dumbproxy.service 2>/dev/null"
}

lego_cron_certificate() {
  check_variables CRONMIN HOST

  local cronscript="/opt/cron/scripts/update_${HOST}_host.sh"

  # -- ensure dir exists -- -- --
  mkdir -p /opt/lego/scripts /opt/lego/logs

  # -- create script -- -- --
  _lego_echo_renew_certificate "${HOST}" > "$cronscript" && \
  chmod 755 "$cronscript"

  # -- create cron job -- -- --
  echo_action "> cat $cronscript" && cat "$cronscript"
  cronjob=$CRONMIN' 04 * * * '$cronscript # at 04:XX each day
  add_cron_script "$cronscript" "$cronjob"

  # -- log cronjob -- -- --
  echo && echo_action "> crontab -l" && crontab -l
}

lego_update_certificate_manually() {
  check_variables HOST EMAIL USE_CLOUDFLARE

  if is_enabled "$USE_CLOUDFLARE"; then
    echo_warn "Cloudflare certificate is used, skipping"
    exit
  fi

  lego -d "$HOST" -m "$EMAIL" --path=/opt/lego -a --http --http.port=:81 run && \
  nginx -s reload
}

#- ./lib/podman.sh

podman_build_web_app() {
  local appdir="$1"
  check_variables ENV PROJECTNAME
  echo_step "Build $PROJECTNAME-$ENV/web image"
  podman build --format docker --tag "$PROJECTNAME-$ENV/web" "./$appdir"
}

make_config_map_variables() {
  check_variables PROJECTROOT
  if [ -f "$PROJECTROOT/var/configs/ConfigMap.yaml" ]; then return; fi

  local SECRET_KEY=$(</dev/urandom base64 | tr -d '/+' | head -c 50) || true

  echo_step "Create ./var/configs/ConfigMap.yaml"
  template__podman_ConfigMap_yaml | \
    render_variables "${@}" |
    save_to "$PROJECTROOT/var/configs/ConfigMap.yaml"
}

make_config_nginx_container() {
  check_variables PROJECTROOT
  if [ -f "$PROJECTROOT/nginx/nginx-container.conf" ]; then return; fi

  echo_step "Create ./nginx/nginx-container.conf"
  template__nginx_container_nginx | \
    render_variables "${@}" | \
    save_to "$PROJECTROOT/nginx/nginx-container.conf"
}

make_config_podman() {
  check_variables PROJECTROOT OUTPORT
  if [ ! -f "$PROJECTROOT/var/configs/Podman.yaml" ]; then return; fi

  echo_step "Create ./var/configs/Podman.yaml"
  template__podman_Podman_yaml | \
    render_variables PROJECTNAME ENV OUTPORT | \
    save_to "$PROJECTROOT/var/configs/Podman.yaml"
}

make_config_robots_txt() {
  check_variables PROJECTROOT ENV
  if [ -f "$PROJECTROOT/nginx/html/robots.txt" ]; then return; fi

  local outfile="$PROJECTROOT/nginx/html/robots.txt"

  echo_step "Create ./nginx/html/robots.txt"
  if [ "$ENV" = "prod" ]; then
    template__nginx_robots_prod_txt | \
      render_variables HOST | \
      save_to "$outfile"
  else
    template__nginx_robots_dev_txt | \
      render_variables HOST | \
      save_to "$outfile"
  fi
}

podman_build_nginx() {
  check_variables PROJECTNAME ENV
  echo_step "Build $PROJECTNAME-$ENV/nginx image"
  podman build --format docker --tag "$PROJECTNAME-$ENV/nginx" nginx
}

make_config_systemd() {
  check_variables PROJECTROOT PROJECTNAME ENV
  if [ -f "$sddir/$PROJECTNAME-$ENV.kube" ]; then return; fi

  local sddir="$HOME/.config/containers/systemd"
  mkdir -p "$sddir"

  echo_step "Create $sddir/$PROJECTNAME-$ENV.kube"

  template__podman_systemd_conf | \
    render_variables PROJECTROOT PROJECTNAME ENV | \
    save_to "$sddir/$PROJECTNAME-$ENV.kube"
}

start_containers_systemd() {
  check_variables PROJECTNAME ENV
  echo_step "Start containers via systemd"
  systemctl --user daemon-reload && \
  systemctl --user restart "$PROJECTNAME-$ENV.service" && \
  systemctl --user status "$PROJECTNAME-$ENV.service" --lines=0 --no-pager
}

start_containers_podman_kube_play() {
  check_variables PROJECTROOT
  echo_step "Start containers"
  podman kube play --replace --configmap "$PROJECTROOT/var/configs/ConfigMap.yaml" \
    "$PROJECTROOT/var/configs/Podman.yaml"
}

#- ./lib/django.sh

podman_django_collectstatic() {
  check_variables ENV PROJECTNAME

  echo_step "Collect static files"
  podman exec "$PROJECTNAME-$ENV-web" python manage.py collectstatic --no-input
  echo
}

podman_django_migrate_db() {
  check_variables ENV PROJECTNAME
  echo_step "Migrate database"
  podman exec "$PROJECTNAME-$ENV-web" python manage.py migrate --noinput
  echo
}

podman_django_dump_data() {
  check_variables ENV HOST PROJECTNAME PROJECTROOT

  local pod_name="$PROJECTNAME-$ENV-web"
  local pod_prefix="podman exec -it $pod_name "
  local auto_push=""
  local params=""

  # Parse command line options
  for i in "$@"; do
    case $i in
      --local)
        pod_prefix=""
        shift
        ;;
      --auto-push)
        auto_push=YES
        shift
        ;;
      --drop-revisions)
        params="$params --drop-revisions"
        shift
        ;;
      *)
        ;;
    esac
  done

  cd "$PROJECTROOT/var"
  git reset       initial_data/data.json
  git checkout -f initial_data/data.json
  echo

  if [ -z "$pod_prefix" ]; then
    source "$PROJECTROOT/venv/bin/activate"
    echo
  fi

  cd "$PROJECTROOT/src"
  $pod_prefix python manage.py dump_initial_data $params
  echo

  if [ -n "$pod_prefix" ]; then
    cd "$PROJECTROOT"
    echo   Copy "$pod_name:/volumes/initial_data/data.json" to ./var/initial_data/data.json
    podman cp   "$pod_name:/volumes/initial_data/data.json"    ./var/initial_data/data.json
    echo
  fi

  cd "$PROJECTROOT/var"

  local timestamp=$(date +"%m-%d-%Y-%H-%M-%S")
  git add --all
  git commit -m "dump $timestamp" || true

  if [ -n "$auto_push" ]; then
    git push
  else
    echo
    echo "please run the following commands:"
    echo "  cd $PROJECTROOT/var"
    echo "  git push"
  fi
}

podman_django_load_data() {
  check_variables ENV HOST PROJECTNAME PROJECTROOT

  local pod_name="$PROJECTNAME-$ENV-web"
  local pod_prefix="podman exec -it $pod_name "

  # Parse command line options
  for i in "$@"; do
    case $i in
      --local)
        pod_prefix=""
        shift
        ;;
      *)
        ;;
    esac
  done

  if [ -z "$pod_prefix" ]; then
    source "$PROJECTROOT/venv/bin/activate"
    echo
  else
    cd "$PROJECTROOT"
    echo   Copy ./var/initial_data/data.json to "$pod_name:/volumes/initial_data/data.json"
    podman cp   ./var/initial_data/data.json    "$pod_name:/volumes/initial_data/data.json"
    echo
  fi

  cd "$PROJECTROOT/src"
  $pod_prefix python manage.py migrate
  $pod_prefix python manage.py load_initial_data
  echo
  $pod_prefix python manage.py changepassword admin

  echo
  echo_warn "Don't forget to update site domain and port"
  echo "https://$HOST/admin/sites/"
  echo
  echo "Hostname:"
  echo "  $HOST"
  echo "Port:"
  echo "  443"
  echo
}
