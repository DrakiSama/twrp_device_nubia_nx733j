#
# Copyright (C) 2025 The Android Open Source Project
#
# SPDX-License-Identifier: Apache-2.0
#

DEVICE_PATH := device/nubia/NX733J

# Building with minimal manifest
ALLOW_MISSING_DEPENDENCIES := true

# Rules
BUILD_BROKEN_DUP_RULES := true
BUILD_BROKEN_ELF_PREBUILT_PRODUCT_COPY_FILES := true
BUILD_BROKEN_NINJA_USES_ENV_VARS += RTIC_MPGEN
BUILD_BROKEN_PLUGIN_VALIDATION := soong-libaosprecovery_defaults soong-libguitwrp_defaults soong-libminuitwrp_defaults soong-vold_defaults

# Architecture
TARGET_ARCH := arm64
TARGET_ARCH_VARIANT := armv8-a
TARGET_CPU_ABI := arm64-v8a
TARGET_CPU_ABI2 :=
TARGET_CPU_VARIANT := generic
TARGET_CPU_VARIANT_RUNTIME := oryon

# Power
ENABLE_CPUSETS := true
ENABLE_SCHEDBOOST := true

# Bootloader
PRODUCT_PLATFORM := sun
TARGET_BOOTLOADER_BOARD_NAME := sun
TARGET_NO_BOOTLOADER := true
TARGET_USES_UEFI := true

# Platform
TARGET_BOARD_PLATFORM := sun
TARGET_BOARD_PLATFORM_GPU := qcom-adreno830
QCOM_BOARD_PLATFORMS += sun

# Kernel — compilado desde source oficial NX733J (android15-6.6.30)
# Source layout esperado en el árbol TWRP:
#   kernel/nubia/nx733j/msm-kernel/  ← kernel_platform/msm-kernel
#   kernel/nubia/nx733j/common/      ← kernel_platform/common
# Clang: r510928 (build.config.constants)
# Variante: perf → gki_defconfig + vendor/sun_perf.config
TARGET_KERNEL_ARCH := arm64
TARGET_KERNEL_HEADER_ARCH := arm64
BOARD_KERNEL_IMAGE_NAME := Image
BOARD_BOOT_HEADER_VERSION := 4
BOARD_KERNEL_PAGESIZE := 4096

# Clang/LLVM completo (LLVM=1 definido en build.config.common del source oficial)
TARGET_KERNEL_CLANG_COMPILE := true
TARGET_KERNEL_CLANG_VERSION := r510928
TARGET_KERNEL_ADDITIONAL_FLAGS := LLVM=1 LLVM_IAS=1

# Kernel source — compila desde source si está disponible, sino usa prebuilt
# Source esperado en: kernel/nubia/nx733j/msm-kernel/ (copiar desde NX733J_V(15)_Kernel(6.6.30))
ifneq ($(wildcard kernel/nubia/nx733j/msm-kernel/Makefile),)
TARGET_KERNEL_SOURCE := kernel/nubia/nx733j/msm-kernel
TARGET_KERNEL_CONFIG := gki_defconfig
TARGET_KERNEL_CONFIG += vendor/sun_perf.config
$(info Building kernel from source: $(TARGET_KERNEL_SOURCE))
else
TARGET_PREBUILT_KERNEL := $(DEVICE_PATH)/prebuilt/kernel
$(info Kernel source not found, using prebuilt: $(TARGET_PREBUILT_KERNEL))
endif

BOARD_PREBUILT_DTBOIMAGE := $(DEVICE_PATH)/prebuilt/dtbo.img
BOARD_MKBOOTIMG_ARGS += --header_version $(BOARD_BOOT_HEADER_VERSION)
BOARD_MKBOOTIMG_ARGS += --pagesize $(BOARD_KERNEL_PAGESIZE)

# Ramdisk
BOARD_RAMDISK_USE_LZ4 := true

# A/B
BOARD_EXCLUDE_KERNEL_FROM_RECOVERY_IMAGE := true
AB_OTA_UPDATER := true
AB_OTA_PARTITIONS += \
    boot \
    init_boot \
    vendor_boot \
    dtbo \
    vbmeta \
    vbmeta_system \
    odm \
    odm_dlkm \
    product \
    system \
    system_ext \
    system_dlkm \
    vendor \
    vendor_dlkm

# Verified Boot
BOARD_AVB_ENABLE := true
BOARD_AVB_ALGORITHM := SHA256_RSA4096
BOARD_AVB_KEY_PATH := external/avb/test/data/testkey_rsa4096.pem
BOARD_AVB_ROLLBACK_INDEX := $(PLATFORM_SECURITY_PATCH_TIMESTAMP)
BOARD_AVB_ROLLBACK_INDEX_LOCATION := 1
BOARD_AVB_MAKE_VBMETA_IMAGE_ARGS += --flags 3

# Partitions — tamaños verificados con "fastboot getvar" en NX733J real (PQ84A01)
BOARD_BOOTIMAGE_PARTITION_SIZE        := 100663296   # 0x06000000
BOARD_INIT_BOOT_IMAGE_PARTITION_SIZE  := 8388608     # 0x00800000
BOARD_VENDOR_BOOTIMAGE_PARTITION_SIZE := 100663296   # 0x06000000
BOARD_DTBOIMG_PARTITION_SIZE          := 25165824    # 0x01800000
BOARD_RECOVERYIMAGE_PARTITION_SIZE    := 104857600   # 0x06400000

BOARD_PROPERTY_OVERRIDES_SPLIT_ENABLED := true

TARGET_COPY_OUT_VENDOR := vendor
TARGET_COPY_OUT_ODM := odm
BOARD_ODMIMAGE_FILE_SYSTEM_TYPE := ext4
BOARD_USES_VENDOR_DLKMIMAGE := true
TARGET_COPY_OUT_VENDOR_DLKM := vendor_dlkm
BOARD_VENDOR_DLKMIMAGE_FILE_SYSTEM_TYPE := ext4

# Dynamic Partitions — super verificado: 0x400000000 = 17179869184 bytes (16 GB)
BOARD_SUPER_PARTITION_SIZE := 17179869184
BOARD_SUPER_PARTITION_GROUPS := nubia_dynamic_partitions
# Reservar ~4 MB para metadata del super
BOARD_NUBIA_DYNAMIC_PARTITIONS_SIZE := 17175674880
BOARD_NUBIA_DYNAMIC_PARTITIONS_PARTITION_LIST := \
    system \
    system_ext \
    product \
    vendor \
    vendor_dlkm \
    odm \
    odm_dlkm

# File systems
TARGET_USERIMAGES_USE_EXT4 := true
TARGET_USERIMAGES_USE_F2FS := true

# Extras
TARGET_SYSTEM_PROP += $(DEVICE_PATH)/system.prop

# Recovery
BOARD_HAS_LARGE_FILESYSTEM := true
TARGET_RECOVERY_PIXEL_FORMAT := RGBX_8888
TARGET_RECOVERY_FSTAB := $(DEVICE_PATH)/recovery.fstab

# Crypto — FBE completo para Android 15/16 con fscrypt policy v2
TW_INCLUDE_CRYPTO := true
TW_INCLUDE_CRYPTO_FBE := true
TW_INCLUDE_FBE_METADATA_DECRYPT := true
BOARD_USES_QCOM_FBE_DECRYPTION := true
BOARD_USES_METADATA_PARTITION := true
TW_USE_FSCRYPT_POLICY := 2
# Bypass de verificación de versión — permite que TWRP descifre ROMs futuras
PLATFORM_VERSION := 99.87.36
PLATFORM_VERSION_LAST_STABLE := $(PLATFORM_VERSION)
PLATFORM_SECURITY_PATCH := 2099-12-31
VENDOR_SECURITY_PATCH := $(PLATFORM_SECURITY_PATCH)
BOOT_SECURITY_PATCH := $(PLATFORM_SECURITY_PATCH)

# Tools
TW_INCLUDE_7ZA := true
TW_INCLUDE_REPACKTOOLS := true
TW_INCLUDE_RESETPROP := true
TW_INCLUDE_LIBRESETPROP := true
TW_ENABLE_ALL_PARTITION_TOOLS := true

# F2FS
TW_ENABLE_FS_COMPRESSION := false

# Debug
TARGET_USES_LOGD := true
TWRP_INCLUDE_LOGCAT := true
TARGET_RECOVERY_DEVICE_MODULES += debuggerd
RECOVERY_BINARY_SOURCE_FILES += $(TARGET_OUT_EXECUTABLES)/debuggerd
TARGET_RECOVERY_DEVICE_MODULES += strace
RECOVERY_BINARY_SOURCE_FILES += $(TARGET_OUT_EXECUTABLES)/strace

# Fastbootd
TW_INCLUDE_FASTBOOTD := true

# TWRP Configuration
TW_THEME := portrait_hdpi
TW_FRAMERATE := 120
RECOVERY_SDCARD_ON_DATA := true
TARGET_RECOVERY_QCOM_RTC_FIX := true
TW_EXCLUDE_DEFAULT_USB_INIT := true
TW_INCLUDE_NTFS_3G := true
TW_NO_EXFAT_FUSE := true
TW_NO_SCREEN_BLANK := true
TW_USE_DMCTL := true
TW_USE_TOOLBOX := true
TARGET_USES_MKE2FS := true
TW_INCLUDE_FUSE_EXFAT := true
TW_INCLUDE_FUSE_NTFS := true
TW_INPUT_BLACKLIST := "hbtp_vm:goodix_fp:nubia_tgk_aw_sar0_ch0:nubia_tgk_aw_sar1_ch0:sun-mtp-snd-card Headset Jack:sun-mtp-snd-card Button Jack"
TW_BRIGHTNESS_PATH := "/sys/class/backlight/panel0-backlight/brightness"
TW_MAX_BRIGHTNESS := 2047
TW_DEFAULT_BRIGHTNESS := 250
TW_EXTRA_LANGUAGES := true
TW_EXCLUDE_APEX := true
TW_HAS_EDL_MODE := false
TW_NO_HAPTICS := true
TW_USE_SERIALNO_PROPERTY_FOR_DEVICE_ID := true
TW_SCREEN_BLANK_ON_BOOT := true
# Módulos de vendor requeridos para display, touch y battery (Nubia/ZTE sun platform)
# Verificados contra kernel source NX733J V(15) y vendor_boot stock
TW_LOAD_VENDOR_MODULES := "msm.ko drm_display_helper.ko panel_event_notifier.ko dispcc-sun.ko gpucc-sun.ko zte_tpd.ko aw9620x.ko qti_battery_charger.ko zte_power_supply.ko bcl_pmic5.ko bcl_soc.ko"
TW_LOAD_VENDOR_MODULES_EXCLUDE_GKI := true
TW_LOAD_PREBUILT_MODULES_AT_FIRST := true
TW_CUSTOM_CPU_TEMP_PATH := "/sys/class/thermal/thermal_zone1/temp"
TW_BACKUP_EXCLUSIONS := /data/fonts
TW_HAS_USB_OTG := true
TW_CUSTOM_BATTERY_PATH := "/sys/class/power_supply/battery"
TW_DEVICE_VERSION := "by Draki"

# Nota: ro.product.device = PQ84A01 (codename interno Nubia del NX733J)
# fingerprint real: nubia/PQ84A01-UN/PQ84A01:16/BQ2A.250705.001/20260210.135030:user/release-keys
