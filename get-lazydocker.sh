os_arch=""
version=""
REPOS_HOST="https://github.com"
REPOS_PATH="jesseduffield/lazydocker"

getArch() {
  if [[ $(uname -m | grep 'x86_64') != "" ]]; then
    os_arch="x86_64"
  elif [[ $(uname -m | grep 'aarch64\|armv8b\|armv8l') != "" ]]; then
    os_arch="arm64"
  elif [[ $(uname -m | grep 'arm\|armv7l') != "" ]]; then
    os_arch="arm"
  fi
  echo -e "当前架构: $os_arch"
}

getVersion() {
  version=$(curl -m 10 -sL "https://api.github.com/repos/${REPOS_PATH}/releases/latest" | grep "tag_name" | head -n 1 | awk -F ":" '{print $2}' | sed 's/[ \"v,]//g;')
  echo -e "当前版本: v$version"
}

download() {
  local filename="lazydocker_${version}_Linux_${os_arch}.tar.gz"
  local downloadUrl="${REPOS_HOST}/${REPOS_PATH}/releases/download/v${version}/${filename}"
  echo -e "下载地址: $downloadUrl"
  wget -t 2 -T 10 -O $filename $downloadUrl -q --show-progress --progress=bar:force 2>&1
  tar xzf $filename -C /usr/local/bin lazydocker 
}

getArch
getVersion
download

exit 0
