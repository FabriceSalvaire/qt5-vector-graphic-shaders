####################################################################################################

TEMPLATE = app
TARGET = qt5-vector-graphic-shaders

####################################################################################################

CONFIG += c++11
CONFIG += debug console qml_debug
# CONFIG += qtquickcompiler

QT += core
QT += qml quick

INCLUDEPATH += src

# HEADERS += \
#   src/xxx.h

SOURCES += \
  src/main.cpp

# OTHER_FILES += \
#   pages/*.qml

RESOURCES += qt5-vector-graphic-shaders.qrc

####################################################################################################
#
# Android
#

#android {

# QT += androidextras

# HEADERS += \
#   src/android_activity/android_activity.h

# SOURCES += \
#   src/android_activity/android_activity.cpp

# OTHER_FILES += \
#   android/AndroidManifest.xml

# DISTFILES += \
#     android/AndroidManifest.xml \
#     android/gradle/wrapper/gradle-wrapper.jar \
#     android/gradlew \
#     android/res/values/libs.xml \
#     android/build.gradle \
#     android/gradle/wrapper/gradle-wrapper.properties \
#     android/gradlew.bat

#ANDROID_PACKAGE_SOURCE_DIR = $$PWD/android
#}

####################################################################################################
#
# End
#
####################################################################################################
