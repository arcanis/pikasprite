#!/usr/bin/env bash

set -e

HERE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
source "${HERE_DIR}/common.sh"

rm -f "${SPRITESHEET_LESS_PATH}"

cat >> "${SPRITESHEET_LESS_PATH}" <<EOF
.pkspr() {
    display: inline-block;
}
EOF

cut -d' ' -f2-3 "${ICON_LIST_PATH}" | sort | uniq | while read FORMAT; do
    read -r -a SIZE <<< "${FORMAT}"

    for IS_TRIMMED in 1 0; do
        if [[ $IS_TRIMMED -eq 1 ]]; then
            cd "${TRIMMED_DIR}"
            IMAGE_FILE="spritesheet-${SIZE[0]}x${SIZE[1]}-trimmed.png"
        else
            cd "${ICON_DIR}"
            IMAGE_FILE="spritesheet-${SIZE[0]}x${SIZE[1]}-regular.png"
        fi

        cat >> "${SPRITESHEET_LESS_PATH}" <<EOF
.pkspr-${SIZE[0]}-${SIZE[1]}-${IS_TRIMMED}() {
    .pkspr;

    width: ${SIZE[0]}px;
    height: ${SIZE[1]}px;

    background-image: url(./${IMAGE_FILE});
}
EOF

        X=0
        Y=0

        COLUMNS=32

        echo "== ${IMAGE_FILE} =="
        echo "Crawling..."

        rm -f "${MONTAGE_PATH}"
        touch "${MONTAGE_PATH}"

        ENTRY_INDEX=1
        ENTRY_COUNT="$(wc -l < "${ICON_LIST_PATH}")"

        while read ICON_LINE; do
            ENTRY_INDEX=$(($ENTRY_INDEX + 1))
            printf '\r%s / %s' "${ENTRY_INDEX}" "${ENTRY_COUNT}"

            read -r -a ICON_ENTRY <<< "${ICON_LINE}"

            if [[ ${ICON_ENTRY[1]} -eq ${SIZE[0]} && ${ICON_ENTRY[2]} -eq ${SIZE[1]} ]]; then
                echo "${ICON_ENTRY[0]}" >> "${MONTAGE_PATH}"

                if [[ $IS_TRIMMED -eq 1 ]]; then
                    CLASS_NAME="$(gen_class_name "${ICON_ENTRY[0]}" trimmed)"
                else
                    CLASS_NAME="$(gen_class_name "${ICON_ENTRY[0]}")"
                fi

                cat >> "${SPRITESHEET_LESS_PATH}" <<EOF
.${CLASS_NAME} {
  .pkspr-${SIZE[0]}-${SIZE[1]}-${IS_TRIMMED};
  background-position: $(($X * -${SIZE[0]}))px $(($Y * -${SIZE[1]}))px;
}
EOF

                X=$(($X + 1))
                if [[ $X == $COLUMNS ]]; then
                    X=0
                    Y=$(($Y + 1))
                fi
            fi
        done < "${ICON_LIST_PATH}"
        printf '\n'

        echo "Montage..."
        montage -background transparent -tile "${COLUMNS}x" -geometry "${SIZE[0]}x${SIZE[1]}" @"${MONTAGE_PATH}" "${BUILD_DIR}/${IMAGE_FILE}"

        echo "Crushing..."
        pngcrush -q -brute -ow "${BUILD_DIR}/${IMAGE_FILE}"
    done
done

yarn run lessc "${SPRITESHEET_LESS_PATH}" "${SPRITESHEET_CSS_PATH}"
