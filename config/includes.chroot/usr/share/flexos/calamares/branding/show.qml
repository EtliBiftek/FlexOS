import QtQuick 2.0
import calamares.slideshow 1.0

Presentation {
    id: presentation

    Slide {
        Rectangle {
            anchors.fill: parent
            color: "#151619"
        }

        Image {
            id: flexosWelcome
            source: "welcome.svg"
            width: Math.min(parent.width * 0.72, 520)
            height: Math.min(parent.height * 0.58, 280)
            fillMode: Image.PreserveAspectFit
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: -28
        }

        Text {
            anchors.top: flexosWelcome.bottom
            anchors.topMargin: 18
            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width * 0.82
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            color: "#d2d4d7"
            font.pixelSize: 18
            text: qsTr("Installing FlexOS. This may take a few minutes.")
        }
    }
}
