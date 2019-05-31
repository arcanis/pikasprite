#!/usr/bin/env bash

set -e

HERE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
BUILD_DIR="${HERE_DIR}/../build"
TMP_DIR="$(mktemp -d)"

cd "${HERE_DIR}/../icons"

CSS_PATH="${BUILD_DIR}/spritesheet.css"
IMAGE_PATH="${BUILD_DIR}/spritesheet-%%.png"
JS_PATH="${BUILD_DIR}/spritesheet.js"
LESS_PATH="${BUILD_DIR}/spritesheet.less"

MONTAGE_FILE="${TMP_DIR}/montage.txt"

COLUMNS=32

rm -rf "${BUILD_DIR}"
mkdir -p "${BUILD_DIR}"

cat >> "${JS_PATH}" <<EOF
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
        root.PikaSprite = factory();
  }
}(typeof self !== 'undefined' ? self : this, function () {
  return [
EOF

cat >> "${LESS_PATH}" <<EOF
.pkspr:before {
  display: inline-block;
  content: '';

  width: 32px;
  height: 32px;

  background-image: url(./spritesheet-items.png);
}
.pkspr[class^="pokemon-"]:before, .pkspr[class*=" pokemon-"]:before,
.pkspr[class^="dex-"]:before, .pkspr[class*=" dex-"]:before {
  width: 40px;
  height: 30px;

  background-image: url(./spritesheet-pkmns.png);
}
EOF

for PASS in pkmns items; do
    rm -f "${MONTAGE_FILE}"

    echo "=== ${PASS} ==="
    echo "Crawling..."

    X=0
    Y=0

    case "${PASS}" in
        pkmns) W=40 H=30 OPTS=(-name '*.png' -a -wholename './pokemon/*');;
        items) W=32 H=32 OPTS=(-name '*.png' -a -not -wholename './pokemon/*');;
    esac

    find "${OPTS[@]}" | sed 's|^\./||' | sort | while read ICON_FILE; do
        RW=$(identify -format "%w" "$ICON_FILE")> /dev/null
        RH=$(identify -format "%h" "$ICON_FILE")> /dev/null

        if [[ $RW -ne $W || $RH -ne $H ]]; then
            echo "Warning: ${ICON_FILE}: ${RW}x${RH} != ${W}x${H}"
        fi

        IFS=/ read -ra TAGS <<<"$(dirname "${ICON_FILE}")"
        TAGS=("${TAGS[@]/regular}")

        PRIMARY="${TAGS[0]}"
        SECONDARIES=("${TAGS[@]:1}")
        NAME=$(basename "${ICON_FILE}" .png)

        CLASS_NAME="$(
            printf '.pkspr.%s-%s' "${PRIMARY}" "${NAME}"
            for TAG in "${SECONDARIES[@]}"; do
                if [[ $TAG != "" ]]; then
                    printf ".%s" "${TAG}"
                fi
            done
        )"

        printf '  "%s",\n' "${CLASS_NAME}" >> "${JS_PATH}"
        printf '%s:before {background-position:%spx %spx}\n' "${CLASS_NAME}" "$(($X * -$W))" "$(($Y * -$H))" >> "${LESS_PATH}"

        echo "${ICON_FILE}" >> "$MONTAGE_FILE"

        X=$(($X + 1))
        if [[ $X == $COLUMNS ]]; then
            X=0
            Y=$(($Y + 1))
        fi
    done

    FINAL_IMAGE_PATH="${IMAGE_PATH//%%/$PASS}"

    echo "Montage..."
    montage -background transparent -tile "${COLUMNS}x" -geometry "${W}x${H}" @"${MONTAGE_FILE}" "${FINAL_IMAGE_PATH}"

    echo "Crushing..."
    pngcrush -q -brute -ow "${FINAL_IMAGE_PATH}"
done

cat >> "${JS_PATH}" <<EOF
  ];
}));
EOF

yarn run -q lessc "${HERE_DIR}/../index.less" "${CSS_PATH}"
