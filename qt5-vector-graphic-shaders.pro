####################################################################################################

TEMPLATE = app
TARGET = qt5-vector-graphic-shaders

####################################################################################################

CONFIG += c++11
CONFIG += debug console qml_debug
# CONFIG += qtquickcompiler

QT += core
QT += qml quick quickcontrols2

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
# End
#
####################################################################################################
