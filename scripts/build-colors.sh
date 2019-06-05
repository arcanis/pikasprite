#!/usr/bin/env bash

set -e

HERE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
source "${HERE_DIR}/common.sh"

rm -f "${COLORS_PATH}"

cd "${ICON_DIR}"

cat >> "${COLORS_PATH}" <<EOF
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
        root.PikaSprite.colors = factory();
  }
}(typeof self !== 'undefined' ? self : this, function () {
  return {
EOF

ENTRY_INDEX=1
ENTRY_COUNT="$(wc -l < "${ICON_LIST_PATH}")"

cat "${ICON_LIST_PATH}" | while read ICON_LINE; do
    ENTRY_INDEX=$(($ENTRY_INDEX + 1))
    printf '\r%s / %s' "${ENTRY_INDEX}" "${ENTRY_COUNT}"

    read -r -a ICON_ENTRY <<< "${ICON_LINE}"

    COLOR="$(node -e "$(cat <<EOF
        const colibrijs = require('colibrijs');
        const canvas = require('canvas');
        const fs = require('fs');

        const img = new canvas.Image();
        img.src = fs.readFileSync(process.argv[1]);

        console.log(JSON.stringify(
          colibrijs.extractImageColors(img, {
              ignoredColors: ['#202020', '#525252'],
              outputType: 'hex',
          }),
        ));
EOF
    )" "${ICON_ENTRY[0]}")"

    printf '    "%s": %s,\n' "$(gen_class_name "${ICON_ENTRY[0]}")" "${COLOR}" >> "${COLORS_PATH}"
done
echo

cat >> "${COLORS_PATH}" <<EOF
  };
}));
EOF
