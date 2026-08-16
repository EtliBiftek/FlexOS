import QtQuick 2.0
import calamares.slideshow 1.0

Presentation {
    Slide {
        Rectangle { anchors.fill: parent; color: "#101215" }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: -48
            text: "FlexOS 0.5"
            color: "#f2f3f4"
            font.pixelSize: 42
            font.bold: true
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: 10
            text: qsTr("KDE Plasma Edition is being installed")
            color: "#a4a9b0"
            font.pixelSize: 18
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: 48
            text: qsTr("Clean. Flexible. Yours.")
            color: "#747980"
            font.pixelSize: 14
        }
    }

    Slide {
        Rectangle { anchors.fill: parent; color: "#101215" }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: -50
            text: qsTr("Flex Recovery")
            color: "#f2f3f4"
            font.pixelSize: 34
            font.bold: true
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: 20
            width: parent.width * 0.76
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            text: qsTr("GRUB recovery entries, package repair and safe-graphics recovery are included for beta testing.")
            color: "#a4a9b0"
            font.pixelSize: 17
        }
    }

    Slide {
        Rectangle { anchors.fill: parent; color: "#101215" }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: -50
            text: qsTr("Flex Center")
            color: "#f2f3f4"
            font.pixelSize: 34
            font.bold: true
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: 20
            width: parent.width * 0.78
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            text: qsTr("Updates, FlexOS component packages, drivers, snapshots, performance, privacy and diagnostics in one place.")
            color: "#a4a9b0"
            font.pixelSize: 17
        }
    }
}
