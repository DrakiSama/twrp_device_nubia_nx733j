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
TARGET_OTA_ASSERT_DEVICE := NX733J,PQ84A01

# Fingerprint (Android 16 / PQ84A01-UN global)
BUILD_FINGERPRINT := nubia/PQ84A01-UN/PQ84A01:16/BQ2A.250705.001-BP2A.250605.031.A3/20260210.135030:user/release-keys

# Theme
TW_STATUS_ICONS_ALIGN := center
