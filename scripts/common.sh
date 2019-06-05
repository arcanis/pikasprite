#!/usr/bin/env bash

ROOT_DIR="${HERE_DIR}/.."
BUILD_DIR="${ROOT_DIR}/build"
INTERMEDIARY_DIR="${BUILD_DIR}/intermediary"
TRIMMED_DIR="${INTERMEDIARY_DIR}/trimmed"
ICON_DIR="${ROOT_DIR}/icons"

ICON_LIST_PATH="${INTERMEDIARY_DIR}/icon-list.txt"
MONTAGE_PATH="${INTERMEDIARY_DIR}/montage-list.txt"
SPRITESHEET_LESS_PATH="${BUILD_DIR}/spritesheet.less"
SPRITESHEET_CSS_PATH="${BUILD_DIR}/spritesheet.css"
CLASSNAMES_PATH="${BUILD_DIR}/classnames.js"
COLORS_PATH="${BUILD_DIR}/colors.js"

mkdir -p "${INTERMEDIARY_DIR}"
mkdir -p "${TRIMMED_DIR}"

gen_class_name() {
    IFS=/ read -ra TAGS <<<"$(dirname "${1}")"
    TAGS=("${TAGS[@]/regular}")

    PRIMARY="${TAGS[0]}"
    SECONDARIES=("${TAGS[@]:1}")
    NAME=$(basename "${1}" .png)
    shift

    printf 'pkspr-%s-%s' "${PRIMARY}" "${NAME}"
    for TAG in "${SECONDARIES[@]}" "${@}"; do
        if [[ $TAG != "" ]]; then
            printf -- '-%s' "${TAG}"
        fi
    done
}
