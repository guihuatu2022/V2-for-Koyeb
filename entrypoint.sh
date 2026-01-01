#!/usr/bin/env bash

# 定义 UUID 及 伪装路径,请自行修改.(注意:伪装路径以 / 符号开始,为避免不必要的麻烦,请不要使用特殊符号.)

base64 -d config > config.json

UUID=${UUID:-'de04add9-5c68-8bab-950c-08cd5320df18'}

VMESS_WSPATH=${VMESS_WSPATH:-'/vmess'}

VLESS_WSPATH=${VLESS_WSPATH:-'/vless'}

sed -i "s#UUID#$UUID#g;s#VMESS_WSPATH#${VMESS_WSPATH}#g;s#VLESS_WSPATH#${VLESS_WSPATH}#g" config.json

sed -i "s#VMESS_WSPATH#${VMESS_WSPATH}#g;s#VLESS_WSPATH#${VLESS_WSPATH}#g" /etc/nginx/nginx.conf

# 伪装 v2ray 执行文件

RELEASE_RANDOMNESS=$(tr -dc 'A-Za-z0-9' </dev/urandom | head -c 6)

mv v ${RELEASE_RANDOMNESS}

cat config.json | base64 > config

rm -f config.json

# Nezha Agent setup (optional)
if [ -n "${NEZHA_SERVER}" ] && [ -n "${NEZHA_PORT}" ] && [ -n "${NEZHA_KEY}" ]; then
    if [ -f "./nezha-agent" ]; then
        NEZHA_SERVER_ADDR="${NEZHA_SERVER}:${NEZHA_PORT}"
        
        # Determine TLS setting
        if [ "${NEZHA_TLS}" = "true" ]; then
            TLS_SETTING="true"
        else
            TLS_SETTING="false"
        fi
        
        # Determine UUID
        if [ -n "${NEZHA_UUID}" ]; then
            UUID_LINE="uuid: ${NEZHA_UUID}"
        else
            UUID_LINE="uuid: \"\""
        fi
        
        # Create Nezha config
        cat > /app/nezha-config.yml <<EOF
server: ${NEZHA_SERVER_ADDR}
client_secret: ${NEZHA_KEY}
tls: ${TLS_SETTING}
${UUID_LINE}
debug: false
disable_auto_update: true
disable_command_execute: false
disable_force_update: true
disable_nat: false
disable_send_query: false
gpu: false
insecure_tls: false
ip_report_period: 1800
report_delay: 3
skip_connection_count: false
skip_procs_count: false
temperature: false
use_gitee_to_upgrade: false
use_ipv6_country_code: false
EOF
        
        # Start Nezha Agent
        nohup ./nezha-agent -c /app/nezha-config.yml >/dev/null 2>&1 &
    fi
fi

# 运行 nginx 和 v2ray

nginx

base64 -d config > config.json

./${RELEASE_RANDOMNESS} run &

# Keep container running
tail -f /dev/null
