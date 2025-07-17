#!/bin/bash

FILENAME="$(basename $0)"
VERSION="2024.05.31.1115"

COMMAND=""
if [ -x "$(command -v apt)" ]; then COMMAND="apt";            # Ubuntu/Debian
elif [ -x "$(command -v dnf)" ]; then COMMAND="dnf";          # Fedora or 최신 CentOS/RHEL
elif [ -x "$(command -v yum)" ]; then COMMAND="yum";          # CentOS/RHEL
else echo "지원되는 패키지 관리자를 찾을 수 없습니다."; exit 0;
fi

###########################################################################################################

function os_locale() {
  echo "Korean Encoding"
  sudo localedef -c -i ko_KR -f UTF-8 ko_KR.UTF-8
  sudo localectl set-locale LANG=ko_KR.UTF-8

  echo "Korean Time"
  sudo timedatectl set-timezone Asia/Seoul
}

function os_upgrade() {
  echo "Docker 설치"
  case "$COMMAND" in
    apt) sudo apt update -y && sudo apt upgrade -y;;
    yum) sudo yum update -y && sudo yum upgrade -y;;
    dnf) sudo dnf update -y && sudo dnf upgrade -y;;
    *) "지원되는 패키지 관리자를 찾을 수 없습니다."; exit 1;;
  esac
}

function install_docker() {
  echo "Docker 설치"
  CURRENT_VERSION=$(docker --version | sed 's/Docker version //')
  #NEW_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep 'tag_name' | grep -o 'v[0-9]*\.[0-9]*\.[0-9]*')
  echo -e "  Current Version:\tv$CURRENT_VERSION"
  #echo -e "  New Version:\t\t$NEW_VERSION)"
  
  case "$COMMAND" in
    apt)
      # 시스템 업데이트 및 필수 패키지 설치
      sudo apt update && sudo apt upgrade -y
      sudo apt install apt-transport-https ca-certificates curl software-properties-common -y

      sudo apt install curl docker-ce-rootless-extras

      # Docker GPG 키 및 저장소 추가
      curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
      echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
      sudo apt update

      # Docker 설치
      sudo apt install docker-ce docker-ce-cli containerd.io
      sudo systemctl start docker
      sudo systemctl enable docker
      sudo systemctl status docker
      ;;
    dnf)
      # docker & docker-compose 자동 설치
      curl -fsSL https://get.docker.com | sudo sh

      # # Docker 서비스 시작 및 부팅 자동 등록
      # sudo systemctl enable --now docker

      # # 비root 계정에서 도커 사용(보안약함)
      # #sudo usermod -aG docker $USER
      # #newgrp docker

      # # 정상 설치 확인
      # docker --version
      # docker compose version
      # docker run hello-world
      ;;
    *) "지원되는 패키지 관리자를 찾을 수 없습니다."; exit 1;;
  esac
}

function install_docker_compose() {
  echo "최신 버전의 Docker Compose를 다운로드"
  sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose

  echo "다운로드한 파일에 실행 권한을 부여"
  sudo chmod +x /usr/local/bin/docker-compose

  echo "심볼릭 링크를 생성하여 시스템 경로에 docker-compose를 추가"
  sudo ln -sf /usr/local/bin/docker-compose /usr/bin/docker-compose
  
  echo "업데이트된 버전 확인"
  docker-compose --version
}

function install_git() {

  case "$COMMAND" in
    apt)
      sudo apt-get update
      if ! git --version > /dev/null 2>&1; then sudo apt-get install -y git; echo "Git이 설치되었습니다."
      else sudo apt-get upgrade -y git; echo "Git이 업데이트되었습니다."
      fi;;
    yum)
      sudo yum update
      if ! git --version > /dev/null 2>&1; then  sudo yum install -y git; echo "Git이 설치되었습니다."
      else sudo yum update -y git; echo "Git이 업데이트되었습니다."
      fi;;
    dnf)
      sudo dnf update
      if ! git --version > /dev/null 2>&1; then sudo dnf install -y git; echo "Git이 설치되었습니다."
      else sudo dnf update -y git; echo "Git이 업데이트되었습니다."
      fi;;
    *) "지원되는 패키지 관리자를 찾을 수 없습니다."; exit 1;;
  esac  
    
  # 깃 버전 확인
  git --version
}

function install_rclone() {

  # rclone 설치
  curl -fsSL "https://raw.githubusercontent.com/wiserain/rclone/mod/install.sh" | sudo bash  # 최신
  #curl -fsSL "https://raw.githubusercontent.com/wiserain/rclone/mod/install.sh" | sudo bash -s v1.69.3-241  # 선택

  #
  case "$COMMAND" in
    apt) sudo apt install -y fuse3;;
    yum) sudo yum install -y fuse3;;
    dnf) sudo dnf install -y fuse3;;
    *) "지원되는 패키지 관리자를 찾을 수 없습니다."; exit 1;;
  esac  

  # rclone 경로 생성
  CONFIG_PATH="/etc/rclone"
  mkdir -p "$CONFIG_PATH"

  fi  
}

###########################################################################################################

while :; do
    clear

    echo "###############################################################"
    echo "##"
    echo "## $FILENAME v$VERSION"
    echo "##"
    echo "###############################################################"
    echo ""
    echo ""

    echo " 0) Initialize: locale, time"
    echo " 1) OS Upgrade"
    echo ""
    echo " 2) docker 설치"
    echo " 3) docker-compose 설치"
    echo " 4) git 설치"
    echo " 5) rclone 설치"
    echo ""
    echo " q) 종료"
    echo ""
    read -p "# 원하시는 기능을 입력하세요. > " SELECT_VALUE
    echo ""

    case $SELECT_VALUE in
      0) os_locale;;
      1) os_upgrade;;
      2) install_docker;;
      3) install_docker_compose;;
      4) install_git;;
      5) install_rclone;;
      q) break;;
    esac

    read -p "# 계속하려면 엔터키를 누르세요..." SELECT_VALUE
done
