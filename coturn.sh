#!/bin/bash

# Discover public and private IP for this instance

# Yes, this does work. See: https://github.com/ianblenke/aws-6to4-docker-ipv6
#IPV6="$(ip -6 addr show eth0 scope global | grep inet6 | awk '{print $2}')"

PORT=${PORT:-3478}
ALT_PORT=${PORT:-3479}

TLS_PORT=${TLS:-5349}
TLS_ALT_PORT=${TLS_ALT_PORT:-5350}

MIN_PORT=${MIN_PORT:-49152}
MAX_PORT=${MAX_PORT:-65535}

TURNSERVER_CONFIG=/app/etc/turnserver.conf

cat <<EOF > ${TURNSERVER_CONFIG}-template
# https://github.com/coturn/coturn/blob/master/examples/etc/turnserver.conf
listening-port=${PORT}
min-port=${MIN_PORT}
max-port=${MAX_PORT}
EOF

echo "listening-ip=${BIND_IPV4}" >> ${TURNSERVER_CONFIG}-template
echo "external-ip=${PUBLIC_IPV4}" >> ${TURNSERVER_CONFIG}-template
echo "relay-ip=${PUBLIC_IPV4}" >> ${TURNSERVER_CONFIG}-template

if [ -n "${JSON_CONFIG}" ]; then
  echo "${JSON_CONFIG}" | jq -r '.config[]' >> ${TURNSERVER_CONFIG}-template
fi

if [ -n "$SSL_CERTIFICATE" ]; then
  echo "$SSL_CA_CHAIN" > /app/etc/turn_server_cert.pem
  echo "$SSL_CERTIFICATE" >> /app/etc/turn_server_cert.pem
  echo "$SSL_PRIVATE_KEY" > /app/etc/turn_server_pkey.pem

  cat <<EOT >> ${TURNSERVER_CONFIG}-template
tls-listening-port=${TLS_PORT}
alt-tls-listening-port=${TLS_ALT_PORT}
cert=/app/etc/turn_server_cert.pem
pkey=/app/etc/turn_server_pkey.pem
EOT

fi

# Allow for ${VARIABLE} substitution using envsubst from gettext
envsubst < ${TURNSERVER_CONFIG}-template > ${TURNSERVER_CONFIG}

exec /app/bin/turnserver
