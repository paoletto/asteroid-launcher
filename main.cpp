/*
 * Copyright (C) 2015 Florent Revest <revestflo@gmail.com>
 *               2014 Aleksi Suomalainen <suomalainen.aleksi@gmail.com>
 *               2012 Timur Kristóf <venemo@fedoraproject.org>
 * All rights reserved.
 *
 * You may use this file under the terms of BSD license as follows:
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *     * Redistributions of source code must retain the above copyright
 *       notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above copyright
 *       notice, this list of conditions and the following disclaimer in the
 *       documentation and/or other materials provided with the distribution.
 *     * Neither the name of the author nor the
 *       names of its contributors may be used to endorse or promote products
 *       derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDERS OR CONTRIBUTORS BE LIABLE FOR
 * ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#include <QFont>
#include <QScopedPointer>
#include <QCoreApplication>
#include <QScreen>
#include <QQmlEngine>
#include <QQmlContext>
#include <QTranslator>
#include <QDirIterator>
#include <QtLocation/private/qgeojson_p.h>

#include <lipstickqmlpath.h>
#include <lipstickcompositor.h>
#include <homeapplication.h>
#include <homewindow.h>
#include <localemanager.h>

#include "applauncherbackground.h"
#include "firstrun.h"
#include "launcherlocalemanager.h"
#include "gesturefilterarea.h"
#include "notificationsnoozer.h"

class GeoJsoner: public QObject
{
    Q_OBJECT
    Q_PROPERTY(QVariant model MEMBER m_importedGeoJson NOTIFY modelChanged)

public:
    GeoJsoner(QObject *parent = nullptr) : QObject(parent)
    {

    }

public slots:

    Q_INVOKABLE bool load(QUrl url)
    {
        // Reading GeoJSON file
        QString path = url.toString();
        if (url.scheme() == QLatin1String("qrc")) {
            path = QStringLiteral(":") + url.path();
        }
        QFile loadFile(path);
        if (!loadFile.open(QIODevice::ReadOnly)) {
            qWarning() << "Error while opening the file: " << path << "(" << url << ")";
            qWarning() << loadFile.error() <<  loadFile.errorString();
            return false;
        }

        // Load the GeoJSON file using Qt's API
        QJsonParseError err;
        QJsonDocument loadDoc(QJsonDocument::fromJson(loadFile.readAll(), &err));
        if (err.error) {
             qWarning() << "Parsing while importing the JSON document:\n" << err.errorString();
             return false;
        }

        // Import geographic data to a QVariantList
        QVariantList modelList = QGeoJson::importGeoJson(loadDoc);
        m_importedGeoJson =  modelList;
        emit modelChanged();
        return true;
    }

signals:
    void modelChanged();

public:
    QVariant m_importedGeoJson;
};

class NativeGestureManager: public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool nativeGestureEnabled READ nativeGestureEnabled WRITE setNativeGestureEnabled NOTIFY nativeGestureEnabledChanged)
    bool m_nativeGestureEnabled = true;
    HomeWindow *m_homeWindow = nullptr;
public:
    NativeGestureManager(HomeWindow *parent = nullptr) : QObject(parent), m_homeWindow(parent)
    {

    }

    bool nativeGestureEnabled() const {
        return m_nativeGestureEnabled;
    }

    void setNativeGestureEnabled(bool enabled) {
        if (m_nativeGestureEnabled == enabled)
            return;

        m_nativeGestureEnabled = enabled;
        if (!m_homeWindow)
            return;
        if(enabled)
            m_homeWindow->enableNativeGestures();
        else
            m_homeWindow->disableNativeGestures();

    }

signals:
    void nativeGestureEnabledChanged();
};

#include "main.moc"

int main(int argc, char **argv)
{
    QmlPath::append(":/qml/");
    QScopedPointer<GeoJsoner> geoJsoner(new GeoJsoner);
    HomeApplication app(argc, argv, QString());
    QCoreApplication::setOrganizationName("AsteroidOS");
    QCoreApplication::setApplicationName("asteroid-launcher");


    app.engine()->rootContext()->setContextProperty("geoJsoner", geoJsoner.get());

    FirstRun *firstRun = new FirstRun();
    LauncherLocaleManager *launcherLocaleManager = new LauncherLocaleManager();
    QObject::connect(app.localeManager(), SIGNAL(localeChanged()), launcherLocaleManager, SLOT(onLocaleChanged()));

    QGuiApplication::setFont(QFont("Noto Sans"));
    app.setCompositorPath("qrc:/qml/compositor.qml");
    Qt::ScreenOrientation nativeOrientation = app.primaryScreen()->nativeOrientation();
    QByteArray v = qgetenv("LAUNCHER_NATIVEORIENTATION");
    if (!v.isEmpty()) {
        switch (v.toInt()) {
        case 1:
            nativeOrientation = Qt::PortraitOrientation;
            break;
        case 2:
            nativeOrientation = Qt::LandscapeOrientation;
            break;
        case 4:
            nativeOrientation = Qt::InvertedPortraitOrientation;
            break;
        case 8:
            nativeOrientation = Qt::InvertedLandscapeOrientation;
            break;
        default:
            nativeOrientation = app.primaryScreen()->nativeOrientation();
        }
    }
    if (nativeOrientation == Qt::PrimaryOrientation)
        nativeOrientation = app.primaryScreen()->primaryOrientation();
    app.engine()->rootContext()->setContextProperty("nativeOrientation", nativeOrientation);
    app.engine()->rootContext()->setContextProperty("firstRun", firstRun);

    qmlRegisterType<AppLauncherBackground>("org.asteroid.launcher", 1, 0, "AppLauncherBackground");
    qmlRegisterType<GestureFilterArea>("org.asteroid.launcher", 1, 0, "GestureFilterArea");
    qmlRegisterType<NotificationSnoozer>("org.asteroid.launcher", 1, 0, "NotificationSnoozer");
    qmlRegisterType<GeoJsoner>("org.asteroid.launcher", 1, 0, "GeoJsoner");


    app.setQmlPath("qrc:/qml/MainScreen.qml");

    // Give these to the environment inside the lipstick homescreen
    // Fixes a bug where some applications wouldn't launch, eg. terminal or browser
    setenv("EGL_PLATFORM", "wayland", 1);
    setenv("QT_QPA_PLATFORM", "wayland", 1);
    setenv("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1", 1);
    app.mainWindowInstance()->showFullScreen();

    NativeGestureManager *nativeGestureManager = new NativeGestureManager(app.mainWindowInstance());
    app.engine()->rootContext()->setContextProperty("nativeGestureManager", nativeGestureManager);

    return app.exec();
}

