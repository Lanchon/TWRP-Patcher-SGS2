#!/sbin/sh

#####################################################
# IsoRec TWRP Patcher                               #
# Copyright 2016, Lanchon                           #
#####################################################

#####################################################
# TWRP Patcher is free software licensed under      #
# the GNU General Public License (GPL) version 3    #
# and any later version.                            #
#####################################################

set -e

version="2016-04-17"

### logging

fatal() {
    echo
    >&2 echo "FATAL:" "$@"
    exit 1
}

warning() {
    >&2 echo "WARNING:" "$@"
}

info() {
    echo "info:" "$@"
}

### helpers

checkTool() {

    #info "checking tool: $1"
    if [ -z "$(which "$1")" ]; then
        fatal "required tool '$1' missing (please use a recent version of TWRP)"
    fi

}

checkDevice() {

    checkTool getprop

    case ":$(getprop ro.product.device):$(getprop ro.build.product):" in

        # i9100:
        *:galaxys2:*) ;;
        *:i9100:*) ;;
        *:GT-I9100:*) ;;
        *:GT-I9100M:*) ;;
        *:GT-I9100P:*) ;;
        *:GT-I9100T:*) ;;
        *:SC-02C:*) ;;

        # d710:
        *:epic4gtouch:*) ;;
        *:SPH-D710:*) ;;
        *:d710:*) ;;
        *:smdk4210:*) ;;
        *:SPH-D710VMUB:*) ;;
        *:SPH-D710BST:*) ;;

        # i777:
        *:i777:*) ;;
        *:SGH-I777:*) ;;
        *:SGH-S959G:*) ;;

        # n7000:
        *:galaxynote:*) ;;
        *:n7000:*) ;;
        *:N7000:*) ;;
        *:GT-N7000:*) ;;

        *)
            fatal "this package is for '$deviceName' devices; this device is '$(getprop ro.product.device)'"
            ;;

    esac

}

checkTwrp() {

    #info "checking TWRP"
    if [ ! -e /sbin/twrp ]; then
        fatal "this package requires TWRP"
    fi

}

checkTools() {

    checkTool lzop
    checkTool cpio
    checkTool find
    checkTool sed

}

printVersion() {

    echo "Version: $version"
    echo "Source: i9100"
    echo "Target: $device"
    echo "Crossflash: $cfstate"

}

checkRepatch() {

    local tagFile=lanchon-twrp-patcher

    if [ -e $tagFile ]; then
        info "detected previously applied patch, as follows:"
        echo
        cat $tagFile
        fatal "recovery already patched (please flash a clean TWRP before patching again)"
    fi
    printVersion >$tagFile

}

### patching

patch_d710() {

    sed -i 's/GT-I9100/SPH-D710/g' default.prop
    sed -i 's/i9100/d710/g' default.prop

    sed -i 's|/devices/platform/s3c-sdhci.2/mmc_host/mmc1|/devices/virtual/block/cyasblkdevblk0|g' fstab.smdk4210 etc/recovery.fstab

}

patch_i777() {

    sed -i 's/GT-I9100/SGH-I777/g' default.prop
    sed -i 's/i9100/i777/g' default.prop

}

patch_n7000() {

    sed -i 's/GT-I9100/GT-N7000/g' default.prop
    sed -i 's/i9100/n7000/g' default.prop

}

patch() {

    if [ -n "$crossflash" ]; then
        sed -i 's/ro\.build\.product=GT-I9100/ro\.build\.product=lanchon-magic/g' default.prop
    fi
    "patch_$device"
    if [ -n "$crossflash" ]; then
        sed -i 's/ro\.build\.product=lanchon-magic/ro\.build\.product=i9100/g' default.prop
    fi

}

### main

main() {

    if [ -n "$crossflash" ]; then
        cfstate="Enabled"
    else
        cfstate="Disabled"
    fi

    echo " ####################################"
    echo "  Lanchon IsoRec TWRP Patcher"
    echo "  Version: $version"
    echo "  Source: i9100"
    echo "  Target: $device"
    echo "  Crossflash: $cfstate"
    echo "  Copyright 2016, Lanchon (GPLv3)"
    echo " ####################################"
    echo

    # /dev/block/platform/dw_mmc/by-name/RECOVERY
    dev=/dev/block/mmcblk0p6

    tlzo=/tmp/isorec-ramdisk.cpio.lzo
    tcpio=/tmp/isorec-ramdisk.cpio
    tdir=/tmp/isorec-ramdisk

    checkDevice
    #checkTwrp
    checkTools

    rm -f $tlzo
    rm -f $tcpio
    rm -rf $tdir

    echo "processing currently installed recovery..."
    echo

    info "decompressing"
    if ! lzop -d <$dev >$tcpio; then
        fatal "IsoRec recovery not found"
    fi

    info "unpacking"
    mkdir -p $tdir
    cd $tdir
    if ! cpio -i <$tcpio 2>/dev/null; then
        fatal "recovery image is corrupt"
    fi
    rm $tcpio

    info "verifying"
    checkRepatch

    info "patching"
    patch

    info "repacking"
    cd $tdir
    if ! find | cpio -o -H newc >$tcpio; then
        fatal "repacking failed"
    fi
    cd /
    rm -r $tdir

    info "compressing"
    if ! lzop <$tcpio >$tlzo; then
        fatal "compressing failed"
    fi
    rm $tcpio

    info "flashing"
    if ! cat $tlzo >$dev; then
        fatal "flashing failed"
    fi
    #rm $tlzo

    info "success"

}
