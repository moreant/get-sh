#!/bin/bash

[[ $EUID -ne 0 ]] && echo -e "错误: 必须使用root用户运行此脚本！\n" && exit 1

while getopts m:p: flag; do
  case "${flag}" in
  m) mirror=${OPTARG} ;;
  p) params=${OPTARG} ;;
  esac
done

if [[ $mirror != "" ]]; then
  MIRROR=$mirror
else
  country="$(curl -s -m 10 https://ipinfo.io/country)"
  if [ -z "$country" ]; then
    echo -e "请检查网络连接"
    exit 1
  fi

  if [ "$country" = "CN" ]; then
    MIRROR="https://mirror.ghproxy.com"
    echo -e "> 监测到您的IP在中国，使用镜像下载"
  else
    MIRROR=""
  fi
fi

echo -e "> 使用镜像地址: $MIRROR"
if [ -n "$MIRROR" ]; then
  MIRROR="$MIRROR/"
fi

case "$(uname -m)" in
x86_64)
  ARCH="amd64"
  ;;
aarch64)
  ARCH="arm64"
  ;;
armv7l)
  ARCH="armv7l"
  ;;
armv6l)
  ARCH="armv6l"
  ;;
esac

if [[ -z $ARCH ]]; then
  echo -e "${red}错误${plain} 不支持的架构: $(uname -m)"
  exit 1
fi

echo -e "> 当前架构: $ARCH"

FRPP_FILE_NAME="frp-panel-client-linux-${ARCH}"
echo -e "> 下载 $FRPP_FILE_NAME"

REPORT="https://github.com/VaalaCat/frp-panel/releases/latest/download"

wget -t 2 -T 60 -O frp-panel-client "${MIRROR}${REPORT}/$FRPP_FILE_NAME" -q --show-progress --progress=bar:force 2>&1
if [[ $? != 0 ]]; then
  echo -e "Frp-Panel-Client 下载失败"
  echo -e "下载地址: ${MIRROR}${REPORT}/$FRPP_FILE_NAME"
  exit 1
fi

chmod +x frp-panel-client

sudo mv frp-panel-client /usr/local/bin/frp-panel-client

get_start_params() {
  read -p "请输入启动参数：" params
  echo "$params"
}

if [ -n "$1" ]; then
  start_params="$params"
else
  start_params=$(get_start_params)
fi

sudo tee /lib/systemd/system/frpp.service <<EOF
[Unit]
Description=frp-panel-client
After=network.target

[Service]
Type=simple
Restart=always
RestartSec=5
StartLimitInterval=0
ExecStart=/usr/local/bin/frp-panel-client $start_params

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload

sudo systemctl start frpp

sudo systemctl restart frpp

sudo systemctl enable frpp
