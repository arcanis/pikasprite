#!/usr/bin/env bash

set -e

HERE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
BUILD_DIR="${HERE_DIR}/../build"
TMP_DIR="$(mktemp -d)"

CSS_PATH="${BUILD_DIR}/spritesheet.css"
IMAGE_PATH="${BUILD_DIR}/spritesheet-%pass-%trimmed.png"
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
.pkspr {
  display: inline-block;
}
.pkspr:before {
  display: block;
  content: '';

  width: 100%;
  height: 100%;

}

.pkspr {
  width: 32px;
  height: 32px;
}
.pkspr[class^="pokemon-"], .pkspr[class*=" pokemon-"], .pkspr[class^="dex-"], .pkspr[class*=" dex-"] {
  width: 40px;
  height: 30px;
}

.pkspr:before {
  background-image: url(./spritesheet-items-regular.png);
}
.pkspr[class^="pokemon-"]:before, .pkspr[class*=" pokemon-"]:before, .pkspr[class^="dex-"]:before, .pkspr[class*=" dex-"]:before {
  background-image: url(./spritesheet-pkmns-regular.png);
}
.pkspr.trimmed:before {
  background-image: url(./spritesheet-items-trimmed.png);
}
.pkspr[class^="pokemon-"].trimmed:before, .pkspr[class*=" pokemon-"].trimmed:before, .pkspr[class^="dex-"].trimmed:before, .pkspr[class*=" dex-"].trimmed:before {
  background-image: url(./spritesheet-pkmns-trimmed.png);
}
EOF

for TRIMMED in 1 0; do
    cd "${HERE_DIR}/../icons"

    echo "=== Trimmed: ${TRIMMED}"
    if [[ $TRIMMED -eq 1 ]]; then
        TRIMMED_DIR="${TMP_DIR}/trimmed-icons"
        mkdir -p "${TRIMMED_DIR}"

        find -name '*.png' | while read ICON_FILE; do
            RW=$(identify -format "%w" "$ICON_FILE")> /dev/null
            RH=$(identify -format "%h" "$ICON_FILE")> /dev/null

            mkdir -p "$(dirname "${TRIMMED_DIR}/${ICON_FILE}")"
            convert "${ICON_FILE}" -trim +repage -gravity center -background none -extent "$RW"x"$RH" "${TRIMMED_DIR}/${ICON_FILE}"
        done

        cd "${TRIMMED_DIR}"
    fi

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

        FINAL_IMAGE_PATH="${IMAGE_PATH}"
        FINAL_IMAGE_PATH="${FINAL_IMAGE_PATH//%pass/$PASS}"

        if [[ $TRIMMED -eq 1 ]]; then
            FINAL_IMAGE_PATH="${FINAL_IMAGE_PATH//%trimmed/trimmed}"
        else
            FINAL_IMAGE_PATH="${FINAL_IMAGE_PATH//%trimmed/regular}"
        fi

        echo "Montage..."
        montage -background transparent -tile "${COLUMNS}x" -geometry "${W}x${H}" @"${MONTAGE_FILE}" "${FINAL_IMAGE_PATH}"

        echo "Crushing..."
        pngcrush -q -brute -ow "${FINAL_IMAGE_PATH}"
    done
done

cat >> "${JS_PATH}" <<EOF
  ];
}));
EOF

yarn run -q lessc "${HERE_DIR}/../index.less" "${CSS_PATH}"
