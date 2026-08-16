import QtQuick 2.0
import calamares.slideshow 1.0
Presentation {
    Slide {
        Rectangle { anchors.fill: parent; color: "#101215" }
        Text { anchors.centerIn: parent; anchors.verticalCenterOffset: -35; text: "FlexOS"; color:"#f2f3f4"; font.pixelSize:44; font.bold:true }
        Text { anchors.centerIn: parent; anchors.verticalCenterOffset: 28; text: qsTr("KDE Plasma Edition is being installed"); color:"#a4a9b0"; font.pixelSize:18 }
    }
    Slide {
        Rectangle { anchors.fill: parent; color: "#101215" }
        Text { anchors.centerIn: parent; anchors.verticalCenterOffset: -35; text: qsTr("Flex Center"); color:"#f2f3f4"; font.pixelSize:36; font.bold:true }
        Text { anchors.centerIn: parent; anchors.verticalCenterOffset: 30; width: parent.width*.75; horizontalAlignment:Text.AlignHCenter; wrapMode:Text.WordWrap;
               text: qsTr("Updates, drivers, snapshots, recovery, performance, privacy and security in one place."); color:"#a4a9b0"; font.pixelSize:17 }
    }
}
