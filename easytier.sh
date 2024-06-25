#!/bin/bash

while getopts m:h:n:s:i:d:p: flag; do
  case "${flag}" in
  m) mirror=${OPTARG} ;;
  h) hostname=${OPTARG} ;;
  n) nname=${OPTARG} ;;
  s) nsecret=${OPTARG} ;;
  i) ipv4=${OPTARG} ;;
  d) dhcp=${OPTARG} ;;
  p) peer=${OPTARG} ;;
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
  ARCH="x86_64-unknown-linux-musl"
  ;;
aarch64)
  ARCH="aarch64-unknown-linux-musl"
  ;;
armv7l)
  ARCH="armv7-unknown-linux-musleabihf"
  ;;
armv6l)
  ARCH="arm-unknown-linux-musleabihf"
  ;;
esac

if [[ -z $ARCH ]]; then
  echo -e "${red}错误${plain} 不支持的架构: $(uname -m)"
  exit 1
fi

echo -e "> 安装 unzip"
sudo apt install -y unzip

echo -e "> 当前架构: $ARCH"

FILE_NAME="easytier-$ARCH-v1.1.0.zip"
echo -e "> 下载 $FILE_NAME"

REPORT="https://github.com/EasyTier/EasyTier/releases/latest/download"
DOWNLOAD_FILE=EasyTier.zip

wget -t 2 -T 60 -O $DOWNLOAD_FILE "${MIRROR}${REPORT}/$FILE_NAME" -q --show-progress --progress=bar:force 2>&1
if [[ $? != 0 ]]; then
  echo -e "$DOWNLOAD_FILE 下载失败"
  echo -e "下载地址: ${MIRROR}${REPORT}/$FILE_NAME"
  exit 1
fi

sudo mkdir -p /opt/easytier

unzip -qo $DOWNLOAD_FILE -d /opt/easytier

# 写入配置文件
sudo tee /opt/easytier/config.toml <<EOF
hostname = "$hostname"
instance_name = "default"
ipv4 = "$ipv4"
dhcp = $dhcp
listeners = [
  "tcp://0.0.0.0:11010",
  "udp://0.0.0.0:11010",
  "wg://0.0.0.0:11011",
  "ws://0.0.0.0:11011/",
  "wss://0.0.0.0:11012/",
]
rpc_portal = "127.0.0.1:15888"

[network_identity]
network_name = "$nname"
network_secret = "$nsecret"

[[peer]]
uri = "$peer"
EOF

# 配置 systemd
sudo tee /etc/systemd/system/easytier.service <<EOF
[Unit]
Description=easytier
After=network.target

[Service]
Type=simple
Restart=always
RestartSec=120
StartLimitInterval=5
StartLimitBurst=10

WorkingDirectory=/opt/easytier
ExecStart=/opt/easytier/easytier-core -c /opt/easytier/config.toml

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload

# sudo systemctl start easytier

# sudo systemctl restart easytier

# sudo systemctl enable easytier
