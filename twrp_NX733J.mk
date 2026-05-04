#
# Copyright (C) 2025 The Android Open Source Project
#
# SPDX-License-Identifier: Apache-2.0
#

DEVICE_PATH := device/nubia/NX733J

# Inherit from device.mk configuration
$(call inherit-product, $(DEVICE_PATH)/device.mk)

# Device identifier
PRODUCT_DEVICE := NX733J
PRODUCT_NAME := twrp_NX733J
PRODUCT_BRAND := nubia
PRODUCT_MANUFACTURER := nubia
PRODUCT_MODEL := Nubia Z70 Ultra

# Assert
TARGET_OTA_ASSERT_DEVICE := NX733J

# Fingerprint
BUILD_FINGERPRINT := nubia/CN_PQ84A01/PQ84A01:15/AQ3A.240812.002/20251209.173802:user/release-keys

# Theme
TW_STATUS_ICONS_ALIGN := center
