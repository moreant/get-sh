#!/usr/bin/env /bin/bash

[[ $EUID -ne 0 ]] && echo -e "${red}错误: ${plain} 必须使用root用户运行此脚本！\n" && exit 1

NZ_BASE_PATH="/opt/nezha"
NZ_AGENT_PATH="${NZ_BASE_PATH}/agent"

OS=$(uname -s)

# read -p "自定义镜像？：" mirror

mirror="$@"

if [[ $mirror != "" ]]; then
  prefix=$mirror
else
  if [ "$(curl -s https://ipinfo.io/country)" = "CN" ]; then
    prefix="https://mirror.ghproxy.com"
    echo "监测到您的IP在中国，使用镜像下载"
  else
    prefix=""
  fi
fi
if [ "$prefix" != "" ]; then
  echo "使用镜像地址: $prefix"
  prefix="$prefix/"
fi

REPORT="https://github.com/nezhahq/agent/releases/latest/download"

if [[ $(uname -m | grep 'x86_64') != "" ]]; then
  os_arch="amd64"
elif [[ $(uname -m | grep 'i386\|i686') != "" ]]; then
  os_arch="386"
elif [[ $(uname -m | grep 'aarch64\|armv8b\|armv8l') != "" ]]; then
  os_arch="arm64"
elif [[ $(uname -m | grep 'arm\|armv7l') != "" ]]; then
  os_arch="arm"
elif [[ $(uname -m | grep 's390x') != "" ]]; then
  os_arch="s390x"
elif [[ $(uname -m | grep 'riscv64') != "" ]]; then
  os_arch="riscv64"
fi

echo -e "> 安装监控Agent"
mkdir -p $NZ_AGENT_PATH
chmod 777 -R $NZ_AGENT_PATH

NZ_AGENT_FILE="nezha-agent_linux_${os_arch}.zip"

wget -t 2 -T 60 -O $NZ_AGENT_FILE "${prefix}${REPORT}/nezha-agent_linux_${os_arch}.zip" -q --show-progress --progress=bar:force 2>&1
if [[ $? != 0 ]]; then
  echo -e "Release 下载失败"
  return 0
fi

unzip -qo $NZ_AGENT_FILE -d ./nz-tmp &&
  mv ./nz-tmp/nezha-agent $NZ_AGENT_PATH &&
  rm -rf $NZ_AGENT_FILE ./nz-tmp

sudo systemctl restart nezha-agent.service
