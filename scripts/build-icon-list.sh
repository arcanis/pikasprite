#!/usr/bin/env bash

set -e

HERE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
source "${HERE_DIR}/common.sh"

rm -f "${ICON_LIST_PATH}"

cd "${ICON_DIR}"

find -name '*.png' | sed 's#^\./##' | sort | while read ICON_FILE; do
    read -r -a SIZE <<< "$(identify -format '%w %h' "${ICON_FILE}")"
    printf '%s %d %d\n' "${ICON_FILE}" "${SIZE[0]}" "${SIZE[1]}"
done > "${ICON_LIST_PATH}"
