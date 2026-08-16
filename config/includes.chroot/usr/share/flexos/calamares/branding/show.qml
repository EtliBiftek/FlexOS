import QtQuick 2.0
import calamares.slideshow 1.0
Presentation {
    Slide {
        Rectangle { anchors.fill: parent; color: "#101215" }
        Text { anchors.horizontalCenter: parent.horizontalCenter; anchors.verticalCenter: parent.verticalCenter; anchors.verticalCenterOffset: -45; text: "FlexOS"; color: "#f1f2f3"; font.pixelSize: 42; font.bold: true }
        Text { anchors.horizontalCenter: parent.horizontalCenter; anchors.verticalCenter: parent.verticalCenter; anchors.verticalCenterOffset: 15; text: qsTr("KDE Plasma Edition is being installed"); color: "#a7abb1"; font.pixelSize: 18 }
        Text { anchors.horizontalCenter: parent.horizontalCenter; anchors.verticalCenter: parent.verticalCenter; anchors.verticalCenterOffset: 55; text: qsTr("Clean. Flexible. Yours."); color: "#747980"; font.pixelSize: 14 }
    }
    Slide {
        Rectangle { anchors.fill: parent; color: "#101215" }
        Text { anchors.horizontalCenter: parent.horizontalCenter; anchors.verticalCenter: parent.verticalCenter; anchors.verticalCenterOffset: -45; text: qsTr("One desktop. One identity."); color: "#f1f2f3"; font.pixelSize: 32; font.bold: true }
        Text { anchors.horizontalCenter: parent.horizontalCenter; anchors.verticalCenter: parent.verticalCenter; anchors.verticalCenterOffset: 18; width: parent.width * 0.75; horizontalAlignment: Text.AlignHCenter; wrapMode: Text.WordWrap; text: qsTr("FlexOS is built around KDE Plasma 6 so the system, themes and FlexOS tools stay consistent."); color: "#a7abb1"; font.pixelSize: 17 }
    }
    Slide {
        Rectangle { anchors.fill: parent; color: "#101215" }
        Text { anchors.horizontalCenter: parent.horizontalCenter; anchors.verticalCenter: parent.verticalCenter; anchors.verticalCenterOffset: -45; text: qsTr("Flex Center"); color: "#f1f2f3"; font.pixelSize: 34; font.bold: true }
        Text { anchors.horizontalCenter: parent.horizontalCenter; anchors.verticalCenter: parent.verticalCenter; anchors.verticalCenterOffset: 20; width: parent.width * 0.76; horizontalAlignment: Text.AlignHCenter; wrapMode: Text.WordWrap; text: qsTr("Manage profiles, hardware, updates, packages, appearance and boot settings from one place."); color: "#a7abb1"; font.pixelSize: 17 }
    }
}
