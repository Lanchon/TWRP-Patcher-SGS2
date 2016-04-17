#!/bin/bash

set -e

makeZip() {

    local device="$1"
    local crossflash="$2"

    local variant="$device"
    if [ -n "$crossflash" ]; then
        variant="crossflash-$device"
    fi

    echo "variant: $variant"

    script="build/lanchon-twrp-patcher-$variant.sh"
    ./make-script "$device" "$crossflash" "$script"

    unsignedZip="build/lanchon-twrp-patcher-unsigned-$variant.zip"
    signedZip="build/lanchon-twrp-patcher-$versionShort-$variant.zip"

    flashize "$script" "$unsignedZip" /tmp/lanchon-twrp-patcher.log
    signapk -w key/testkey.x509.pem key/testkey.pk8 "$unsignedZip" "$signedZip"

    rm "$script"
    rm "$unsignedZip"

}

makeDevice() {

    local device="$1"

    makeZip "$device" ""
    makeZip "$device" "true"

}

makeAll() {

    rm -f build/lanchon-twrp-patcher*

    makeDevice d710
    makeDevice i777
    makeDevice n7000

}

make() {

    versionLong="$(sed -n "s/^version=\"\(.*\)\"$/\1/p" twrp-patcher.sh)"
    if [ -z "$versionLong" ]; then
        >&2 echo "error: value not found: 'version'"
        exit 1
    fi
    versionShort="$(echo "$versionLong" | sed "s/-//g")"

    echo "version: $versionLong"

    mkdir -p build
    makeAll

}

make "$@"
