#!/usr/bin/bash

mkdir /code/avds/$1
mkdir /code/avds/$1/android
mkdir /code/avds/$1/emulator

docker run --privileged -d --name $1 -p 6080:6080 -p 4723:4723 -p 5554:5554 -p 5555:5555 \
  -v "/code/apks:/root/tmp" \
  -v "/code/avds/$1/android:/root/.android" \
  -v "/code/avds/$1/emulator:/root/android_emulator" \
  -e DEVICE="Samsung Galaxy S6" \
  -e EMULATOR_ARGS="-gpu swiftshader_indirect" \
  -e AVD_NAME="$1" \
  -e APPIUM=true \
  budtmo/docker-android-x86-8.1