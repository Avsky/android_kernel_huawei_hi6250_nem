# Android makefile to build kernel as a part of Android Build
# http://jhshi.me/2014/06/30/build-kernel-in-tree-with-aosp-for-nexus-5-hammerhead/

OBB_PRODUCT_NAME := hi6250
BALONG_TOPDIR := $(KERNEL_PATH_FULL)/drivers/vendor/hisi
CFG_PLATFORM := hi6250
TARGET_ARM_TYPE := arm64
#SRCHI1101 := drivers/misc/hw-drv
PERL := perl
export BALONG_TOPDIR OBB_PRODUCT_NAME CFG_PLATFORM TARGET_ARM_TYPE PERL

ifeq ($(TARGET_PREBUILT_KERNEL),)

KERNEL_HEADER_DEFCONFIG := $(strip $(KERNEL_HEADER_DEFCONFIG))
ifeq ($(KERNEL_HEADER_DEFCONFIG),)
KERNEL_HEADER_DEFCONFIG := $(KERNEL_DEFCONFIG)
endif

KERNEL_OUT := $(TARGET_OUT_INTERMEDIATES)/KERNEL_OBJ
KERNEL_OUT_FULL := $(shell pwd)/$(KERNEL_OUT)
KERNEL_CONFIG := $(KERNEL_OUT_FULL)/.config

KERNEL_ARCH_PREFIX := arm64
CROSS_COMPILE_PREFIX := aarch64-linux-android-

ifeq ($(KERNEL_DEFCONFIG)$(wildcard $(KERNEL_CONFIG)),)
$(error Kernel configuration not defined, cannot build kernel)
else

ifeq ($(TARGET_USES_UNCOMPRESSED_KERNEL),true)
$(info Using uncompressed kernel)
TARGET_PREBUILT_INT_KERNEL := $(KERNEL_OUT)/arch/$(KERNEL_ARCH_PREFIX)/boot/Image
else
TARGET_PREBUILT_INT_KERNEL := $(KERNEL_OUT)/arch/$(KERNEL_ARCH_PREFIX)/boot/Image.gz
endif

TARGET_PREBUILT_KERNEL := $(TARGET_PREBUILT_INT_KERNEL)

COMMON_HEAD := $(KERNEL_PATH_FULL)/kernel/drivers/
COMMON_HEAD += $(KERNEL_PATH_FULL)/kernel/mm/
COMMON_HEAD += $(KERNEL_PATH_FULL)/kernel/include/hisi/
COMMON_HEAD += $(KERNEL_PATH_FULL)/drivers/vendor/hisi/ap/platform/hi6250/
COMMON_HEAD += $(KERNEL_PATH_FULL)/external/efipartition

ifneq ($(COMMON_HEAD),)
BALONG_INC := $(patsubst %,-I%,$(COMMON_HEAD))
else
BALONG_INC :=
endif

ifeq ($(CFG_CONFIG_HISI_FAMA),true)
BALONG_INC  += -DCONFIG_HISI_FAMA
endif

export BALONG_INC

$(KERNEL_OUT):
	mkdir -p $(KERNEL_OUT)

$(KERNEL_CONFIG): $(KERNEL_OUT)
	$(MAKE) -C $(KERNEL_DIR) O=$(KERNEL_OUT_FULL) ARCH=$(KERNEL_ARCH_PREFIX) CROSS_COMPILE=$(CROSS_COMPILE_PREFIX) $(KERNEL_DEFCONFIG)

$(TARGET_PREBUILT_INT_KERNEL): $(KERNEL_OUT) $(KERNEL_CONFIG) $(KERNEL_HEADERS_INSTALL)
	$(hide) echo "Building kernel..."
	$(MAKE) -C $(KERNEL_DIR) O=$(KERNEL_OUT_FULL) ARCH=$(KERNEL_ARCH_PREFIX) CROSS_COMPILE=$(CROSS_COMPILE_PREFIX)

$(KERNEL_HEADERS_INSTALL): $(KERNEL_OUT)
	rm -f $(KERNEL_CONFIG)
	$(MAKE) -C $(KERNEL_DIR) O=$(KERNEL_OUT_FULL) ARCH=$(KERNEL_ARCH_PREFIX) CROSS_COMPILE=$(CROSS_COMPILE_PREFIX) $(KERNEL_HEADER_DEFCONFIG)
	$(MAKE) -C $(KERNEL_DIR) O=$(KERNEL_OUT_FULL) ARCH=$(KERNEL_ARCH_PREFIX) CROSS_COMPILE=$(CROSS_COMPILE_PREFIX) headers_install

kerneltags: $(KERNEL_OUT) $(KERNEL_CONFIG)
	$(MAKE) -C $(KERNEL_DIR) O=$(KERNEL_OUT_FULL) ARCH=$(KERNEL_ARCH_PREFIX) CROSS_COMPILE=$(CROSS_COMPILE_PREFIX) tags

kernelconfig: $(KERNEL_OUT) $(KERNEL_CONFIG)
	env KCONFIG_NOTIMESTAMP=true \
		$(MAKE) -C $(KERNEL_DIR) O=$(KERNEL_OUT_FULL) ARCH=$(KERNEL_ARCH_PREFIX) CROSS_COMPILE=$(CROSS_COMPILE_PREFIX) menuconfig
	env KCONFIG_NOTIMESTAMP=true \
		$(MAKE) -C $(KERNEL_DIR) O=$(KERNEL_OUT_FULL) ARCH=$(KERNEL_ARCH_PREFIX) CROSS_COMPILE=$(CROSS_COMPILE_PREFIX) savedefconfig
	cp $(KERNEL_OUT_FULL)/defconfig $(KERNEL_PATH_FULL)/arch/$(KERNEL_ARCH_PREFIX)/configs/$(KERNEL_DEFCONFIG)

endif
endif
