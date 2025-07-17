#!/bin/bash

FILENAME="$(basename $0)"
VERSION="2024.05.31.1115"

COMMAND=""
if [ -x "$(command -v apt)" ]; then COMMAND="apt";            # Ubuntu/Debian
elif [ -x "$(command -v dnf)" ]; then COMMAND="dnf";          # Fedora or 최신 CentOS/RHEL
elif [ -x "$(command -v yum)" ]; then COMMAND="yum";          # CentOS/RHEL
else echo "지원되는 패키지 관리자를 찾을 수 없습니다."; exit 0;
fi
