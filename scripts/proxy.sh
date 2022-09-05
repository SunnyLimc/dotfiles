#!/bin/bash
case "$(uname -s)" in
  Linux*) OST=linux;;
  CYGWIN*|MINGW*|MSYS*) OST=win;;
  *) OST=other;;
esac
islinux() {
  [[ $OST = "linux" ]]
}
iswin() {
  [[ $OST = "win" ]]
}

PORT=7890

set_proxy(){
  if islinux; then
    HOSTIP=$(cat /etc/resolv.conf | grep nameserver | awk '{print $2}')
  else
    HOSTIP="localhost"
  fi 
  PROXY_HTTP="http://${HOSTIP}:${PORT}"
  export http_proxy="${PROXY_HTTP}"
  export HTTP_PROXY="${PROXY_HTTP}"
  export https_proxy="${PROXY_HTTP}"
  export HTTPS_PROXY="${PROXY_HTTP}"
  export http_proxy_default="${HOSTIP}:${PORT}"
}

unset_proxy(){
  unset http_proxy
  unset HTTP_PROXY
  unset https_proxy
  unset HTTPS_PROXY
  unset http_proxy_default
}

test_setting(){
  if islinux; then
    WSLIP=$(hostname -I | awk '{print $1}')
    HOSTIP=$(cat /etc/resolv.conf | grep nameserver | awk '{print $2}')
    echo "Host ip:" ${HOSTIP}
    echo "WSL ip:" ${WSLIP}
  fi
  echo 'Extra infos:'
  echo '$http_proxy:' $http_proxy
  echo '$HTTP_PROXY:' $HTTP_PROXY
  echo '$https_proxy' $https_proxy
  echo '$HTTPS_PROXY' $HTTPS_PROXY
  echo '$http_proxy_default' $http_proxy_default
}

set_apt(){
  iswin && echo "Not support form this OS." && return 1
  if [ "$(id -u)" != "0" ]; then
    sudo "$0" "$1"
    exit $?
  fi
  echo 'Acquire::http::Proxy ''"'${PROXY_HTTP}'"'';' > /etc/apt/apt.conf.d/proxy.conf
  echo 'Acquire::https::Proxy ''"'${PROXY_HTTP}'"'';' >> /etc/apt/apt.conf.d/proxy.conf
}

if [ "$1" = "set" ]
then
    set_proxy
elif [ "$1" = "unset" ]
then
    unset_proxy
elif [ "$1" = "test" ]
then
    test_setting
elif [ "$1" = "set-apt" ]
then
    set_apt
else
    echo "Unsupported arguments."
fi
