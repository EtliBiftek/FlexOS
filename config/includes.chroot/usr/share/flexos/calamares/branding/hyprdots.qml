import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import io.calamares.core 1.0
import io.calamares.ui 1.0

Item {
    id: root
    width: parent ? parent.width : 1000
    height: parent ? parent.height : 700
    property bool activatedInCalamares: false

    function onActivate() {
        var desktop = String(Global.value("packagechooser_desktop"))
        if (desktop !== "hyprland") {
            config.packageChoice = "none"
            Qt.callLater(function() { ViewManager.next() })
        }
    }

    Rectangle {
        anchors.fill: parent
        color: "#1b1d20"

        ScrollView {
            anchors.fill: parent
            anchors.margins: 18
            clip: true

            ColumnLayout {
                width: Math.max(760, root.width - 56)
                spacing: 14

                Label {
                    text: qsTr("Hyprland Dots")
                    color: "#f2f3f4"
                    font.pixelSize: 28
                    font.bold: true
                }
                Label {
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                    color: "#a7abb1"
                    text: qsTr("Optional. end4-pC is recommended by FlexOS, but its Debian / Nix installation path is experimental and requires an internet connection.")
                }

                ButtonGroup { id: presetGroup }

                RadioButton {
                    id: noDots
                    text: qsTr("No dots — keep the standard Hyprland setup")
                    checked: true
                    ButtonGroup.group: presetGroup
                    onCheckedChanged: if (checked) config.packageChoice = "none"
                }

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: presetColumn.implicitHeight + 28
                    radius: 10
                    color: "#202327"
                    border.color: end4pc.checked ? "#8f959d" : "#363a40"
                    ColumnLayout {
                        id: presetColumn
                        anchors.fill: parent
                        anchors.margins: 14
                        spacing: 8
                        RadioButton {
                            id: end4pc
                            text: qsTr("end4-pC — Recommended")
                            font.bold: true
                            ButtonGroup.group: presetGroup
                            onCheckedChanged: if (checked) config.packageChoice = "end4pc"
                        }
                        Label {
                            Layout.fillWidth: true
                            wrapMode: Text.WordWrap
                            color: "#d2d4d7"
                            text: qsTr("Material-style Quickshell setup for illogical-impulse. FlexOS installs the required base dots first, then applies end4-pC as the default shell.")
                        }
                        Label {
                            Layout.fillWidth: true
                            wrapMode: Text.WordWrap
                            color: "#9fa4aa"
                            text: qsTr("Credit: customized and maintained by pctrade. Based on illogical-impulse / dots-hyprland by end-4. Additional upstream credits: gh0stzk, StarS2112 and simeulinuxkaliaiwr.")
                        }
                    }
                }

                Label {
                    text: qsTr("Preview")
                    color: "#f2f3f4"
                    font.pixelSize: 18
                    font.bold: true
                }

                GridLayout {
                    Layout.fillWidth: true
                    columns: root.width > 1050 ? 3 : 2
                    columnSpacing: 10
                    rowSpacing: 10
                    Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 190; color: "#121417"; radius: 8; border.color: "#32363c"; Image { anchors.fill: parent; anchors.margins: 5; source: "https://raw.githubusercontent.com/pctrade/end4-pC/ed05ef11426004eda5cac5280ed61d3cb3b96f36/screenshots/1.png"; fillMode: Image.PreserveAspectFit; asynchronous: true; cache: true } }
                    Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 190; color: "#121417"; radius: 8; border.color: "#32363c"; Image { anchors.fill: parent; anchors.margins: 5; source: "https://raw.githubusercontent.com/pctrade/end4-pC/ed05ef11426004eda5cac5280ed61d3cb3b96f36/screenshots/2.png"; fillMode: Image.PreserveAspectFit; asynchronous: true; cache: true } }
                    Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 190; color: "#121417"; radius: 8; border.color: "#32363c"; Image { anchors.fill: parent; anchors.margins: 5; source: "https://raw.githubusercontent.com/pctrade/end4-pC/ed05ef11426004eda5cac5280ed61d3cb3b96f36/screenshots/3.png"; fillMode: Image.PreserveAspectFit; asynchronous: true; cache: true } }
                    Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 190; color: "#121417"; radius: 8; border.color: "#32363c"; Image { anchors.fill: parent; anchors.margins: 5; source: "https://raw.githubusercontent.com/pctrade/end4-pC/ed05ef11426004eda5cac5280ed61d3cb3b96f36/screenshots/4.png"; fillMode: Image.PreserveAspectFit; asynchronous: true; cache: true } }
                    Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 190; color: "#121417"; radius: 8; border.color: "#32363c"; Image { anchors.fill: parent; anchors.margins: 5; source: "https://raw.githubusercontent.com/pctrade/end4-pC/ed05ef11426004eda5cac5280ed61d3cb3b96f36/screenshots/5.png"; fillMode: Image.PreserveAspectFit; asynchronous: true; cache: true } }
                    Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 190; color: "#121417"; radius: 8; border.color: "#32363c"; Image { anchors.fill: parent; anchors.margins: 5; source: "https://raw.githubusercontent.com/pctrade/end4-pC/ed05ef11426004eda5cac5280ed61d3cb3b96f36/screenshots/6.png"; fillMode: Image.PreserveAspectFit; asynchronous: true; cache: true } }
                }

                Label {
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                    color: "#858a91"
                    text: qsTr("Screenshots and project attribution are sourced from the pctrade/end4-pC repository. If the preview cannot load while offline, you can still continue without dots.")
                }
            }
        }
    }
}
