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
    property color accent: "#7c83ff"
    property color surface: "#10151e"
    property color surfaceSoft: "#151b26"
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

    Rectangle {
        anchors.fill: parent
        color: "#090c12"

        ScrollView {
            anchors.fill: parent
            anchors.margins: 22
            clip: true

            ColumnLayout {
                width: Math.max(720, root.width - 60)
                spacing: 16

                Label {
                    text: qsTr("HYPRLAND EXPERIENCE")
                    color: root.accent
                    font.pixelSize: 11
                    font.bold: true
                    font.letterSpacing: 1.5
                }

                Label {
                    text: qsTr("Hyprland görünümünü seçin")
                    color: root.text
                    font.pixelSize: 30
                    font.bold: true
                }

                Label {
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                    color: root.muted
                    font.pixelSize: 14
                    text: qsTr("Standart FlexOS Hyprland kurulumunu koruyabilir veya end4-pC görünümünü ekleyebilirsiniz. end4-pC internet bağlantısı gerektirir ve deneysel bir kurulum yoludur.")
                }

                ButtonGroup { id: presetGroup }

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: standardColumn.implicitHeight + 30
                    radius: 14
                    color: noDots.checked ? "#171d2b" : root.surface
                    border.width: noDots.checked ? 2 : 1
                    border.color: noDots.checked ? root.accent : root.border

                    ColumnLayout {
                        id: standardColumn
                        anchors.fill: parent
                        anchors.margins: 15
                        spacing: 6
                        RadioButton {
                            id: noDots
                            text: qsTr("FlexOS Standard")
                            checked: true
                            ButtonGroup.group: presetGroup
                            onCheckedChanged: if (checked) config.packageChoice = "none"
                        }
                        Label {
                            Layout.fillWidth: true
                            leftPadding: 28
                            wrapMode: Text.WordWrap
                            color: root.muted
                            text: qsTr("Hafif, temiz ve dağıtımla birlikte test edilen standart Hyprland yapılandırmasını kullanır.")
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: end4Column.implicitHeight + 30
                    radius: 14
                    color: end4pc.checked ? "#171d2b" : root.surface
                    border.width: end4pc.checked ? 2 : 1
                    border.color: end4pc.checked ? root.accent : root.border

                    ColumnLayout {
                        id: end4Column
                        anchors.fill: parent
                        anchors.margins: 15
                        spacing: 7
                        RadioButton {
                            id: end4pc
                            text: qsTr("end4-pC  ·  Önerilen görsel profil")
                            font.bold: true
                            ButtonGroup.group: presetGroup
                            onCheckedChanged: if (checked) config.packageChoice = "end4pc"
                        }
                        Label {
                            Layout.fillWidth: true
                            leftPadding: 28
                            wrapMode: Text.WordWrap
                            color: root.text
                            text: qsTr("illogical-impulse tabanlı Material-style Quickshell deneyimi. FlexOS temel dot dosyalarını kurar ve end4-pC katmanını uygular.")
                        }
                        Label {
                            Layout.fillWidth: true
                            leftPadding: 28
                            wrapMode: Text.WordWrap
                            color: root.muted
                            font.pixelSize: 12
                            text: qsTr("Bakım: pctrade · Upstream: end-4 / dots-hyprland · Ek krediler: gh0stzk, StarS2112, simeulinuxkaliaiwr")
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.topMargin: 8
                    Label {
                        text: qsTr("Önizleme")
                        color: root.text
                        font.pixelSize: 19
                        font.bold: true
                    }
                    Item { Layout.fillWidth: true }
                    Label {
                        visible: !end4pc.checked
                        text: qsTr("Önizlemeler yalnızca end4-pC seçildiğinde indirilir")
                        color: root.muted
                        font.pixelSize: 11
                    }
                }

                GridLayout {
                    Layout.fillWidth: true
                    columns: root.width > 1100 ? 3 : (root.width > 760 ? 2 : 1)
                    columnSpacing: 12
                    rowSpacing: 12

                    Repeater {
                        model: 6
                        delegate: Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 180
                            radius: 12
                            color: root.surfaceSoft
                            border.color: root.border
                            clip: true

                            BusyIndicator {
                                anchors.centerIn: parent
                                running: end4pc.checked && preview.status === Image.Loading
                                visible: running
                            }

                            Label {
                                anchors.centerIn: parent
                                visible: !end4pc.checked
                                text: qsTr("Önizleme %1").arg(index + 1)
                                color: root.muted
                            }

                            Image {
                                id: preview
                                anchors.fill: parent
                                anchors.margins: 6
                                source: end4pc.checked
                                    ? "https://raw.githubusercontent.com/pctrade/end4-pC/ed05ef11426004eda5cac5280ed61d3cb3b96f36/screenshots/" + (index + 1) + ".png"
                                    : ""
                                fillMode: Image.PreserveAspectFit
                                asynchronous: true
                                cache: true
                                smooth: true
                            }
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: note.implicitHeight + 24
                    radius: 12
                    color: root.surfaceSoft
                    border.color: root.border
                    Label {
                        id: note
                        anchors.fill: parent
                        anchors.margins: 12
                        wrapMode: Text.WordWrap
                        color: root.muted
                        text: qsTr("Önizleme dosyaları pctrade/end4-pC deposundan yalnızca bu seçenek seçildiğinde yüklenir. Çevrimdışıysanız kurulum yine devam edebilir.")
                    }
                }
            }
        }
    }
}
