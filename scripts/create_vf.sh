#!/bin/sh

[ ${DEBUG} ] && set -vx
set -eu

drv_bind() {
    drv=$1
    dev=$2
    echo "drv_bind func: $drv $dev"
    modprobe $drv # Ensure driver is loaded
    echo "$drv" >/sys/bus/pci/devices/$dev/driver_override
    echo $dev >/sys/bus/pci/drivers/$drv/bind
}

drv_unbind() {
    drv=$1
    dev=$2
    echo "drv_ubind func: $drv $dev"
    echo $dev >/sys/bus/pci/drivers/$drv/unbind
}

vf_create() {
    # Creating vf
    pf=${1%.*}.0
    numvfs=$(cat /sys/bus/pci/devices/$pf/sriov_numvfs)
    offset=$(cat /sys/bus/pci/devices/$pf/sriov_offset)
    totalvfs=$(cat /sys/bus/pci/devices/$pf/sriov_totalvfs)
    if [ $numvfs -lt $totalvfs ]; then
        offset=$(($offset + $numvfs))
        vf=${1%.*}.${offset}

        if [ $numvfs -eq 0 ]; then
            # make sure vfio-pci is loaded and sriov is enabled
            modprobe vfio-pci
            echo 1 >/sys/module/vfio_pci/parameters/enable_sriov
        fi

        # create vf
        echo $((1 + $numvfs)) >/sys/bus/pci/devices/$pf/sriov_numvfs
        echo Created VF: $vf out of PF: $pf
    else
        echo Cannot create additional VF, max VFs reached \($totalvfs\)
        exit 1
    fi

    eval "$2=$vf"
}

if ! command -v lspci >/dev/null; then
    echo "lspci: command not found, needed by $(basename $0)"
    exit 1
fi

for devId in "$@"; do
    for dev in $(lspci -Dd $devId | cut -d ' ' -f1); do
        vf_create $dev vf

        # Unbinding vf from driver in use
        drv=$(lspci -ks $vf | grep "driver" | cut -d ":" -f2 | tr -d ' ')
        if [ $drv != "vfio-pci" ]; then
            if [ -n "$drv" ]; then
                echo Unbinding VF: $vf from driver: $drv
                drv_unbind $drv $vf
            fi

            # Binding vf to vfio-pci driver
            echo Binding VF: $vf to driver: vfio-pci
            drv_bind vfio-pci $vf
        fi
    done
done
