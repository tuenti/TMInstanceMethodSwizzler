#!/bin/sh
set -e
xctool -project Sample\ app/TMInstanceMethodSwizzler\ sample.xcodeproj -scheme TMInstanceMethodSwizzler\ sample -sdk iphonesimulator test 
