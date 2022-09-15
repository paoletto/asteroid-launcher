TEMPLATE = app
TARGET = asteroid-launcher
VERSION = 0.1

QT += quick waylandcompositor dbus positioning location-private
CONFIG += qt link_pkgconfig qtquickcompiler
PKGCONFIG += lipstick-qt5 timed-qt5 mlite5

SOURCES += \
    main.cpp \
    applauncherbackground.cpp \
    firstrun.cpp \
    gesturefilterarea.cpp \
    launcherlocalemanager.cpp \
    notificationsnoozer.cpp

HEADERS += \
    applauncherbackground.h \
    firstrun.h \
    gesturefilterarea.h \
    launcherlocalemanager.h \
    notificationsnoozer.h

RESOURCES += \
    resources-qml.qrc

OTHER_FILES += qml/*.qml \
    qml/MainScreen.qml \
    qml/today/Today.qml \
    qml/compositor/compositor.qml \
    qml/compositor/WindowWrapperBase.qml \
    qml/compositor/CircleMaskShader.qml \
    qml/misc/USBModeSelector.qml \
    qml/misc/VolumeControl.qml \
    qml/misc/ShutdownScreen.qml \
    qml/notifications/NotificationPreview.qml \
    qml/notifications/NotificationsPanel.qml \
    qml/quicksettings/QuickSettings.qml \
    qml/quicksettings/QuickSettingsToggle.qml

TRANSLATIONS = $$files(i18n/$$TARGET.*.ts)

map_tiles.files = $$files($$PWD/assets/map_tiles/*.*)
map_tiles.prefix = /
map_tiles.base = $$PWD

map_providers.files = $$files($$PWD/assets/map_providers/*)
map_providers.prefix = /
map_providers.base = $$PWD

geojson.files = $$files($$PWD/assets/geojson/*.*)
geojson.prefix = /
geojson.base = $$PWD

RESOURCES += map_tiles map_providers geojson

target.path = /usr/bin

applauncher.path = /usr/share/asteroid-launcher/applauncher
applauncher.files =  applauncher/*

watchfaces.path = /usr/share/asteroid-launcher/watchfaces
watchfaces.files =  watchfaces/*

watchfaces-img.path = /usr/share/asteroid-launcher/watchfaces-img
watchfaces-img.files =  watchfaces-img/*

watchfaces-preview.path = /usr/share/asteroid-launcher/watchfaces-preview
watchfaces-preview.files =  watchfaces-preview/*

INSTALLS = target applauncher watchfaces watchfaces-img watchfaces-preview
