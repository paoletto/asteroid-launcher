/*
 * Copyright (C) 2018 - Timo Könnecke <el-t-mo@arcor.de>
 *               2016 - Sylvia van Os <iamsylvie@openmailbox.org>
 *               2015 - Florent Revest <revestflo@gmail.com>
 *               2012 - Vasiliy Sorokin <sorokin.vasiliy@gmail.com>
 *                      Aleksey Mikhailichenko <a.v.mich@gmail.com>
 *                      Arto Jalkanen <ajalkane@gmail.com>
 * All rights reserved.
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as
 * published by the Free Software Foundation, either version 2.1 of the
 * License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick 2.1

Item {

    Canvas {
        id: minuteArc
        property var centerX: parent.width/2
        property var centerY: parent.height/2
        anchors.fill: parent
        smooth: true
        renderStrategy: Canvas.Cooperative
        visible: !displayAmbient
        onPaint: {
            var ctx = getContext("2d")
            var rot = (wallClock.time.getMinutes() -15 )*6
            ctx.reset()
            ctx.lineWidth = parent.width*0.0031
            var gradient = ctx.createConicalGradient (centerX, centerY, 90*0.01745)
                gradient.addColorStop(1-(wallClock.time.getMinutes()/60), Qt.rgba(1, 1, 1, 0.4))
                gradient.addColorStop(1-(wallClock.time.getMinutes()/60/6), Qt.rgba(1, 1, 1, 0.0))
            var gradient2 = ctx.createConicalGradient (centerX, centerY, 90*0.01745)
                gradient2.addColorStop(1-(wallClock.time.getMinutes()/60), Qt.rgba(1, 1, 1, 0.5))
                gradient2.addColorStop(1-(wallClock.time.getMinutes()/60/6), Qt.rgba(1, 1, 1, 0.01))
            ctx.fillStyle = gradient
            ctx.strokeStyle = gradient2
            ctx.beginPath()
            ctx.arc(centerX, centerY, width / 2.75, -90*0.01745329252, rot*0.01745329252, false);
            ctx.lineTo(centerX, centerY);
            ctx.fill()
            ctx.stroke()
        }
    }

    Text {
        id: hourDisplay
        renderType: Text.NativeRendering
        font.pixelSize: parent.height*0.87
        font.family: "BebasKai"
        font.styleName:"Bold"
        color: Qt.rgba(1, 1, 1, 0.9)
        opacity: 0.9
        style: Text.Outline; styleColor: Qt.rgba(0, 0, 0, 0.2)
        horizontalAlignment: Text.AlignHCenter
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        text: if (use12H.value) {
                  wallClock.time.toLocaleString(Qt.locale(), "hh ap").slice(0, 2) }
              else
                  wallClock.time.toLocaleString(Qt.locale(), "HH")
    }

    Canvas {
        id: minuteCircle
        property var minute: 0
        property var rotM: (wallClock.time.getMinutes() - 15)/60
        property var centerX: parent.width/2
        property var centerY: parent.height/2
        property var minuteX: centerX+Math.cos(rotM * 2 * Math.PI)*width/2.75
        property var minuteY: centerY+Math.sin(rotM * 2 * Math.PI)*height/2.75
        anchors.fill: parent
        smooth: true
        renderStrategy: Canvas.Cooperative
        onPaint: {
            var ctx = getContext("2d")
            var rot1 = (0 -15 )*6 *0.01745329252
            var rot2 = (60 -15 )*6 *0.01745329252
            ctx.reset()
            ctx.lineWidth = 3
            ctx.fillStyle = Qt.rgba(0.184, 0.184, 0.184, 0.95)
            ctx.beginPath()
            ctx.moveTo(minuteX, minuteY)
            ctx.arc(minuteX, minuteY, width / 8.6, rot1, rot2, false);
            ctx.lineTo(minuteX, minuteY);
            ctx.fill();
        }
    }

    Text {
        id: minuteDisplay
        property var rotM: (wallClock.time.getMinutes() - 15)/60
        property var centerX: parent.width/2-width/2
        property var centerY: parent.height/2-height/2
        font.pixelSize: parent.height/5.24
        font.family: "BebasKai"
        font.styleName:'Condensed'
        color: "white"
        opacity: 1.00
        x: centerX+Math.cos(rotM * 2 * Math.PI)*parent.width*0.364
        y: centerY+Math.sin(rotM * 2 * Math.PI)*parent.width*0.364
        text: wallClock.time.toLocaleString(Qt.locale(), "mm")
    }

    Connections {
        target: wallClock
        function onTimeChanged() {
            var hour = wallClock.time.getHours()
            var minute = wallClock.time.getMinutes()
            if(minuteCircle.minute !== minute) {
                minuteCircle.minute = minute
                minuteCircle.requestPaint()
                minuteArc.requestPaint()
            }
        }
    }

    Component.onCompleted: {
        var hour = wallClock.time.getHours()
        var minute = wallClock.time.getMinutes()
        minuteCircle.minute = minute
        minuteCircle.requestPaint()
        minuteArc.requestPaint()

        burnInProtectionManager.widthOffset = Qt.binding(function() { return width*0.3})
        burnInProtectionManager.heightOffset = Qt.binding(function() { return height*0.3})
    }
}
