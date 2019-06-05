#!/usr/bin/env bash

set -e

HERE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
source "${HERE_DIR}/common.sh"

rm -f "${CLASSNAMES_PATH}"

cat >> "${CLASSNAMES_PATH}" <<EOF
(function (root, factory) {
    if (typeof define === 'function' && define.amd) {
        // AMD. Register as an anonymous module.
        define([], factory);
    } else if (typeof module === 'object' && module.exports) {
        // Node. Does not work with strict CommonJS, but
        // only CommonJS-like environments that support module.exports,
        // like Node.
        module.exports = factory();
    } else {
        // Browser globals (root is window)
        root.PikaSprite = root.PikaSprite || {};
        root.PikaSprite.classNames = factory();
  }
}(typeof self !== 'undefined' ? self : this, function () {
  return [
EOF

ENTRY_INDEX=1
ENTRY_COUNT="$(wc -l < "${ICON_LIST_PATH}")"

cat "${ICON_LIST_PATH}" | while read ICON_LINE; do
    ENTRY_INDEX=$(($ENTRY_INDEX + 1))
    printf '\r%s / %s' "${ENTRY_INDEX}" "${ENTRY_COUNT}"

    read -r -a ICON_ENTRY <<< "${ICON_LINE}"

    for IS_TRIMMED in 1 0; do
        if [[ $IS_TRIMMED -eq 1 ]]; then
            CLASS_NAME="$(gen_class_name "${ICON_ENTRY[0]}" trimmed)"
        else
            CLASS_NAME="$(gen_class_name "${ICON_ENTRY[0]}")"
        fi

        printf '    ["%s"],\n' "${CLASS_NAME}" >> "${CLASSNAMES_PATH}"
    done
done
echo

cat >> "${CLASSNAMES_PATH}" <<EOF
  ];
}));
EOF
