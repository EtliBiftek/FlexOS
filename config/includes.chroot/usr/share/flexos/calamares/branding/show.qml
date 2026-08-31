import QtQuick 2.0
import calamares.slideshow 1.0

Presentation {
    Slide {
        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                GradientStop { position: 0.0; color: "#090c12" }
                GradientStop { position: 1.0; color: "#11182a" }
            }

            Rectangle {
                width: Math.min(parent.width * 0.72, 720)
                height: 300
                radius: 24
                anchors.centerIn: parent
                color: "#dd10151e"
                border.color: "#273142"
                border.width: 1

                Rectangle {
                    width: 70
                    height: 70
                    radius: 19
                    color: "#7c83ff"
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.top
                    anchors.topMargin: 38

                    Text {
                        anchors.centerIn: parent
                        text: "F"
                        color: "white"
                        font.pixelSize: 38
                        font.bold: true
                    }
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.top
                    anchors.topMargin: 128
                    text: qsTr("Installing FlexOS")
                    color: "#ffffff"
                    font.pixelSize: 30
                    font.bold: true
                }

                Text {
                    width: parent.width - 80
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.top
                    anchors.topMargin: 180
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                    text: qsTr("Your desktop, recovery tools and performance stack are being prepared.")
                    color: "#aab4c5"
                    font.pixelSize: 15
                }

                Rectangle {
                    width: parent.width - 96
                    height: 5
                    radius: 3
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 34
                    color: "#202a3a"

                    Rectangle {
                        width: parent.width * 0.38
                        height: parent.height
                        radius: 3
                        color: "#7c83ff"
                    }
                }
            }
        }
    }

    Slide {
        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                GradientStop { position: 0.0; color: "#090c12" }
                GradientStop { position: 1.0; color: "#11182a" }
            }

            Rectangle {
                width: Math.min(parent.width * 0.76, 760)
                height: 300
                radius: 24
                anchors.centerIn: parent
                color: "#dd10151e"
                border.color: "#273142"

                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: 42
                    anchors.top: parent.top
                    anchors.topMargin: 42
                    text: qsTr("FLEXOS DESKTOP")
                    color: "#7c83ff"
                    font.pixelSize: 12
                    font.bold: true
                }

                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: 42
                    anchors.top: parent.top
                    anchors.topMargin: 78
                    text: qsTr("Clean by default. Powerful when needed.")
                    color: "#ffffff"
                    font.pixelSize: 28
                    font.bold: true
                }

                Text {
                    width: parent.width - 84
                    anchors.left: parent.left
                    anchors.leftMargin: 42
                    anchors.top: parent.top
                    anchors.topMargin: 132
                    wrapMode: Text.WordWrap
                    text: qsTr("Flex Center brings updates, drivers, snapshots, recovery, security and the CachyOS-derived performance stack into one consistent interface.")
                    color: "#aab4c5"
                    font.pixelSize: 16
                    lineHeight: 1.25
                }

                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: 42
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 38
                    text: qsTr("Fast startup • focused controls • no FlexOS telemetry")
                    color: "#d8deea"
                    font.pixelSize: 14
                }
            }
        }
    }

    Slide {
        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                GradientStop { position: 0.0; color: "#090c12" }
                GradientStop { position: 1.0; color: "#11182a" }
            }

            Rectangle {
                width: Math.min(parent.width * 0.70, 700)
                height: 280
                radius: 24
                anchors.centerIn: parent
                color: "#dd10151e"
                border.color: "#273142"

                Rectangle {
                    width: 54
                    height: 54
                    radius: 17
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.top
                    anchors.topMargin: 36
                    color: "#172539"
                    border.color: "#31527a"

                    Text {
                        anchors.centerIn: parent
                        text: "✓"
                        color: "#54d6a0"
                        font.pixelSize: 30
                        font.bold: true
                    }
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.top
                    anchors.topMargin: 112
                    text: qsTr("Almost ready")
                    color: "#ffffff"
                    font.pixelSize: 29
                    font.bold: true
                }

                Text {
                    width: parent.width - 90
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.top
                    anchors.topMargin: 165
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                    text: qsTr("When installation finishes, restart the computer and remove the live USB to enter your installed FlexOS system.")
                    color: "#aab4c5"
                    font.pixelSize: 15
                    lineHeight: 1.2
                }
            }
        }
    }
}
