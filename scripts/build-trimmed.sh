#!/usr/bin/env bash

set -e

HERE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
source "${HERE_DIR}/common.sh"

rm -rf "${TRIMMED_DIR}"
mkdir -p "${TRIMMED_DIR}"

cd "${ICON_DIR}"

cat "${ICON_LIST_PATH}" | while read ICON_LINE; do
    read -r -a ICON_ENTRY <<< "${ICON_LINE}"
    mkdir -p "$(dirname "${TRIMMED_DIR}/${ICON_ENTRY[0]}")"

    if [[ -L "${ICON_ENTRY[0]}" ]]; then
        cp -P "${ICON_ENTRY[0]}" "${TRIMMED_DIR}/${ICON_ENTRY[0]}"
    else
        convert "${ICON_ENTRY[0]}" -trim +repage -gravity center -background none -extent "${ICON_ENTRY[1]}"x"${ICON_ENTRY[2]}" "${TRIMMED_DIR}/${ICON_ENTRY[0]}"
    fi
done
