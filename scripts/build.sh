#!/usr/bin/env bash

set -e

HERE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
source "${HERE_DIR}/common.sh"

if [[ ! -f "${ICON_LIST_PATH}" ]]; then
    bash "${HERE_DIR}/build-icon-list.sh"
fi

if [[ ! -d "${TRIMMED_DIR}" ]]; then
    bash "${HERE_DIR}/build-trimmed.sh"
fi
