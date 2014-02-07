#!/bin/sh

EXPECTED_ARGS=1

# include global settings
. ../configuration
set_global_config

# boot command
KERNEL_BOOT_CMD="console=ttymxc3,115200 init=/init video=mxcfb0:dev=ldb,1024x600M@60,if=RGB24,bpp=32 video=mxcfb1:off video=mxcfb2:off fbmem=8M vmalloc=400M androidboot.console=ttymxc3 androidboot.hardware=freescale"

# toolchain setup
ROOT_PATH=`pwd`
TOOLCHAIN_PATH=../prebuilts/gcc/linux-x86/arm/arm-eabi-4.6/bin
CROSS_COMPILE=$ROOT_PATH/$TOOLCHAIN_PATH/arm-eabi-
UBOOT_PATH=$ROOT_PATH/../bootable/bootloader/uboot-imx/tools

export ARCH=arm
export CROSS_COMPILE
export PATH=$UBOOT_PATH:$ROOT_PATH/$TOOLCHAIN_PATH:$PATH

# function
print_usage() {
    echo "Usage: build.sh [normal|debug|modules|clean|distclean]"
}
gen_boot_img() {
    if [ -f ../out/target/product/$TARGET_PRODUCT/ramdisk.img ] ; then
    echo "Generate boot.img"
    # cmdline reference with /device/fsl/sabresd_6dq/BoardConfig.mk
    # kernel base address reference with /device/fsl/imx6/soc/imx6dq.mk
    ../out/host/linux-x86/bin/mkbootimg --kernel ./arch/arm/boot/zImage --ramdisk ../out/target/product/$TARGET_PRODUCT/ramdisk.img --base 0x10800000 --cmdline "$KERNEL_BOOT_CMD" --board sabresd_6dq -o boot.img
    fi
}

# verify input parameters
ARGS_VALUE=$#
if [ $ARGS_VALUE -lt $EXPECTED_ARGS ] ; then
    INPUT=normal
    print_usage
else
    INPUT=$1
fi

# main function
case "$INPUT" in
    normal)
    echo "normal build"
    create_log_folder
    get_start_time
    make imx6_android_defconfig
    make -j$CPU_JOB_NUM uImage 2>&1 | tee log/$TIME.log
    gen_boot_img
    get_end_time
    ;;
    debug)
    echo "debug build"
    create_log_folder
    get_start_time
    make imx6_android_defconfig
    make -j$CPU_JOB_NUM CONFIG_DEBUG_SECTION_MISMATCH=y uImage 2>&1 | tee log/$TIME.log
    gen_boot_img
    get_end_time
    ;;
    clean)
    echo "clean build"
    create_log_folder
    get_start_time
    make distclean
    make imx6_android_defconfig
    make -j$CPU_JOB_NUM uImage 2>&1 | tee log/$TIME.log
    gen_boot_img
    get_end_time
    ;;
    distclean)
    echo "make distclean"
    make distclean
    delete_log_folder
    ;;
    menuconfig)
    echo "make menuconfig"
    make menuconfig ARCH=arm
    ;;
    modules)
    echo "make module"
    make imx6_android_defconfig
    make -j$CPU_JOB_NUM modules 2>&1 | tee log/$TIME.log
    ;;
    *)
    print_usage
    ;;
esac

