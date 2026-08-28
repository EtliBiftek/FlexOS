import QtQuick 2.0
import calamares.slideshow 1.0

Presentation {
    Slide {
        Rectangle {
            anchors.fill: parent
            color: "#1b1d20"

            Rectangle {
                width: 112
                height: 112
                radius: 24
                color: "#24272b"
                border.color: "#3c4046"
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter
                anchors.verticalCenterOffset: -86

                Text {
                    anchors.centerIn: parent
                    text: "F"
                    color: "#e4e5e7"
                    font.pixelSize: 58
                    font.bold: true
                }
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter
                anchors.verticalCenterOffset: 18
                text: qsTr("Installing FlexOS")
                color: "#f0f1f2"
                font.pixelSize: 30
                font.bold: true
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter
                anchors.verticalCenterOffset: 60
                text: qsTr("Your system is being prepared. You can keep this window open.")
                color: "#999da3"
                font.pixelSize: 15
            }
        }
    }

    Slide {
        Rectangle {
            anchors.fill: parent
            color: "#1b1d20"

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter
                anchors.verticalCenterOffset: -35
                text: qsTr("Built for a clean desktop")
                color: "#f0f1f2"
                font.pixelSize: 28
                font.bold: true
            }

            Text {
                width: parent.width * 0.72
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter
                anchors.verticalCenterOffset: 20
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                text: qsTr("KDE Plasma, Flex Center, recovery tools and FlexOS component updates are configured as part of the installation.")
                color: "#9da1a7"
                font.pixelSize: 16
            }
        }
    }

    Slide {
        Rectangle {
            anchors.fill: parent
            color: "#1b1d20"

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter
                anchors.verticalCenterOffset: -35
                text: qsTr("Almost ready")
                color: "#f0f1f2"
                font.pixelSize: 28
                font.bold: true
            }

            Text {
                width: parent.width * 0.72
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter
                anchors.verticalCenterOffset: 20
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                text: qsTr("When installation finishes, restart the computer and remove the live USB to enter your installed FlexOS system.")
                color: "#9da1a7"
                font.pixelSize: 16
            }
        }
    }
}
