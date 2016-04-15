import QtQuick 2.6
import QtQuick.Window 2.2

import QtQuick.Layouts 1.3
import Qt.labs.controls 1.0
import Qt.labs.controls.material 1.0
import Qt.labs.settings 1.0

ApplicationWindow {
    id: application_window
    visible: true
    width: 360 // set window size for desktop test
    height: 520
    title: "Shader Test"

    Component.onCompleted: {
        console.info(Screen.height, Screen.width,
                     Screen.desktopAvailableHeight, Screen.desktopAvailableWidth,
                     Screen.pixelDensity, Screen.devicePixelRatio);
    }

    header: ToolBar {
        id: app_bar

        states: [
        State { name: "BACK" }
        ]

        RowLayout {
            spacing: 20
            anchors.fill: parent

            ToolButton {
                id: nav_icon
                contentItem: Image {
                    anchors.centerIn: parent
                    source: "qrc:/icons/menu-white.png"
                }
                onClicked: drawer.open()
            }

            ToolButton {
                id: back_icon
                visible: false
                contentItem: Image {
                    anchors.centerIn: parent
                    source: "qrc:/icons/arrow-back-white.png"
                }
                onClicked: {
                    if (app_bar.state == "BACK") {
                        app_bar.state == ""
                        back_icon.visible = false
                        nav_icon.visible = true
                    }
                    stack_view.pop(StackView.Transition)
                }
            }

            Label {
                id: title_label
                horizontalAlignment: Qt.AlignHCenter
                verticalAlignment: Qt.AlignVCenter
                Layout.fillWidth: true
                font.pixelSize: 20
                elide: Label.ElideRight
                color: "white"
                text: "Shader Test"
            }

            ToolButton {
                id: menu_icon
                contentItem: Image {
                    anchors.centerIn: parent
                    source: "qrc:/icons/more-vert-white.png"
                }
                onClicked: options_menu.open()

                Menu {
                    id: options_menu
                    x: parent.width - width
                    transformOrigin: Menu.TopRight

                    MenuItem {
                        text: "About"
                        onTriggered: about_dialog.open()
                    }
                }
            }
        }
    }

    Drawer {
        id: drawer

        Pane {
            padding: 0
            width: Math.min(application_window.width, application_window.height) / 3 * 2
            height: application_window.height

            ListView {
                id: list_view
                currentIndex: -1
                anchors.fill: parent

                delegate: ItemDelegate {
                    width: parent.width
                    font.pixelSize: 16
                    text: model.title
                    highlighted: ListView.isCurrentItem
                    onClicked: {
                        if (list_view.currentIndex != index) {
                            list_view.currentIndex = index
                            title_label.text = model.title
                            stack_view.replace(model.source)
                        }
                        drawer.close()
                    }
                }

                model: ListModel {
                    ListElement {
                        title: qsTr("Marker")
                        icon: ""
                        source: "qrc:/pages/Marker.qml"
                    }
                    ListElement {
                        title: qsTr("Arrow Fields")
                        icon: ""
                       source: "qrc:/pages/ArrowFields.qml"
                   }
                    ListElement {
                        title: qsTr("Quadratic Bezier")
                        icon: ""
                        source: "qrc:/pages/QuadraticBezier.qml"
                    }
                    ListElement {
                        title: qsTr("Grid")
                        icon: ""
                        source: "qrc:/pages/Grid.qml"
                    }
                    ListElement {
                        title: qsTr("Polar Grid")
                        icon: ""
                        source: "qrc:/pages/PolarGrid.qml"
                    }
                   ListElement {
                        title: qsTr("Hammer Grid")
                        icon: ""
                        source: "qrc:/pages/HammerGrid.qml"
                    }
                    ListElement {
                        title: qsTr("Transverse Mercator Grid")
                        icon: ""
                       source: "qrc:/pages/TransverseMercatorGrid.qml"
                   }
                }

                ScrollIndicator.vertical: ScrollIndicator {}
            }
        }

        // onClicked: close()
    }

    StackView {
        id: stack_view
        anchors.fill: parent

        initialItem: Pane {
            id: pane
        }
    }

    Popup {
        id: about_dialog
        modal: true
        focus: true
        x: (application_window.width - width) / 2
        y: application_window.height / 6
        width: Math.min(application_window.width, application_window.height) / 3 * 2
        contentHeight: about_column.height
        closePolicy: Popup.OnEscape | Popup.OnPressOutside

        Column {
            id: about_column
            spacing: 20

            Label {
                font.bold: true
                text: "About"
            }

            Label {
                width: about_dialog.availableWidth
                wrapMode: Label.Wrap
                font.pixelSize: 12
                text: "This application demonstrates vector graphic shaders with Qt5."
            }
        }
    }
}
