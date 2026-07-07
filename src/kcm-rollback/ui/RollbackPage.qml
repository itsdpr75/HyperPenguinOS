import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import org.kde.kirigami 2.20 as Kirigami
import org.kde.kcm 1.2 as KCM

KCM.SimpleKCM {
    id: root

    title: i18n("Snapshots & Rollback")
    property var snapshotsModel: []

    Kirigami.FormLayout {
        anchors.fill: parent

        Kirigami.Heading {
            text: i18n("Snapshots del Sistema")
            Kirigami.FormData.isSection: true
        }

        ListView {
            id: snapshotList
            Layout.fillWidth: true
            Layout.preferredHeight: 300
            model: snapshotsModel
            clip: true

            delegate: Kirigami.SwipeListItem {
                contentItem: RowLayout {
                    Kirigami.ListItemDragHandle {}
                    Label {
                        text: modelData.name || modelData.path
                        Layout.fillWidth: true
                    }
                    Label {
                        text: modelData.id
                        color: Kirigami.Theme.disabledTextColor
                    }
                    Button {
                        text: i18n("Restaurar")
                        onClicked: kcm.restoreSnapshot(index)
                    }
                }
            }

            Kirigami.PlaceholderMessage {
                anchors.centerIn: parent
                visible: snapshotList.count === 0
                text: i18n("No hay snapshots disponibles")
            }
        }

        Button {
            Layout.alignment: Qt.AlignRight
            text: i18n("Refrescar")
            icon.name: "view-refresh"
            onClicked: kcm.load()
        }
    }

    Connections {
        target: kcm
        function onOperationFinished(message, success) {
            showPassiveNotification(message, success ? "ok" : "error")
            kcm.load()
        }
    }
}
