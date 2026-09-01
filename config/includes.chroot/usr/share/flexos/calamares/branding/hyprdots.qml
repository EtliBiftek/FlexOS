import io.calamares.core 1.0
import io.calamares.ui 1.0
import QtQuick
import QtQuick.Controls

Item {
    id: root
    width: parent ? parent.width : 1000
    height: parent ? parent.height : 700

    property color accent: "#7c83ff"
    property color surface: "#10151e"
    property color surfaceSelected: "#171d2b"
    property color border: "#273142"
    property color text: "#eef2f8"
    property color muted: "#98a2b3"

    function onActivate() {
        var desktop = String(Global.value("packagechooser_desktop"))
        if (desktop !== "hyprland") {
            config.packageChoice = "none"
            Qt.callLater(function() { ViewManager.next() })
        }
    }

    ButtonGroup {
        id: presetGroup
    }

    Rectangle {
        anchors.fill: parent
        color: "#090c12"

        Column {
            anchors.centerIn: parent
            width: Math.min(760, Math.max(520, root.width - 72))
            spacing: 16

            Text {
                width: parent.width
                text: qsTr("HYPRLAND EXPERIENCE")
                color: root.accent
                font.pixelSize: 12
                font.bold: true
            }

            Text {
                width: parent.width
                text: qsTr("Hyprland görünümünü seçin")
                color: root.text
                font.pixelSize: 30
                font.bold: true
            }

            Text {
                width: parent.width
                text: qsTr("Standart FlexOS Hyprland kurulumunu kullanabilir veya end4-pC görünümünü ekleyebilirsiniz. end4-pC internet bağlantısı gerektirir ve deneysel bir kurulum yoludur.")
                color: root.muted
                font.pixelSize: 14
                wrapMode: Text.WordWrap
            }

            Rectangle {
                width: parent.width
                height: standardContent.implicitHeight + 28
                radius: 12
                color: standardChoice.checked ? root.surfaceSelected : root.surface
                border.width: standardChoice.checked ? 2 : 1
                border.color: standardChoice.checked ? root.accent : root.border

                Column {
                    id: standardContent
                    x: 14
                    y: 14
                    width: parent.width - 28
                    spacing: 6

                    RadioButton {
                        id: standardChoice
                        width: parent.width
                        text: qsTr("FlexOS Standard")
                        checked: true
                        ButtonGroup.group: presetGroup
                        onCheckedChanged: {
                            if (checked) {
                                config.packageChoice = "none"
                            }
                        }
                    }

                    Text {
                        width: parent.width
                        text: qsTr("Hafif, temiz ve dağıtımla birlikte test edilen standart Hyprland yapılandırması.")
                        color: root.muted
                        font.pixelSize: 13
                        wrapMode: Text.WordWrap
                    }
                }
            }

            Rectangle {
                width: parent.width
                height: end4Content.implicitHeight + 28
                radius: 12
                color: end4Choice.checked ? root.surfaceSelected : root.surface
                border.width: end4Choice.checked ? 2 : 1
                border.color: end4Choice.checked ? root.accent : root.border

                Column {
                    id: end4Content
                    x: 14
                    y: 14
                    width: parent.width - 28
                    spacing: 6

                    RadioButton {
                        id: end4Choice
                        width: parent.width
                        text: qsTr("end4-pC · Önerilen görsel profil")
                        font.bold: true
                        ButtonGroup.group: presetGroup
                        onCheckedChanged: {
                            if (checked) {
                                config.packageChoice = "end4pc"
                            }
                        }
                    }

                    Text {
                        width: parent.width
                        text: qsTr("illogical-impulse tabanlı Material-style Quickshell deneyimi. FlexOS temel dot dosyalarını kurar ve end4-pC katmanını uygular.")
                        color: root.text
                        font.pixelSize: 13
                        wrapMode: Text.WordWrap
                    }
                }
            }

            Rectangle {
                width: parent.width
                height: noteText.implicitHeight + 24
                radius: 10
                color: root.surface
                border.width: 1
                border.color: root.border

                Text {
                    id: noteText
                    x: 12
                    y: 12
                    width: parent.width - 24
                    text: qsTr("Kurulum ekranı artık ağdan önizleme indirmez. Böylece internet yavaş veya kapalı olsa bile bu adım anında açılır. end4-pC seçilirse dosyalar yalnızca gerçek kurulum aşamasında indirilir.")
                    color: root.muted
                    font.pixelSize: 12
                    wrapMode: Text.WordWrap
                }
            }
        }
    }
}
