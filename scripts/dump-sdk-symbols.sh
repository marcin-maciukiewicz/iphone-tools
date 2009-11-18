#!/bin/bash
#
#
#

SDK_ROOT="/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS"
SDK_VERSION="3.1"
find ${SDK_ROOT}${SDK_VERSION}.sdk/System/Library/Frameworks -type f -perm 0755 | xargs nm 

