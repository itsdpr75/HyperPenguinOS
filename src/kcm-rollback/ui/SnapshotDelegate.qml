import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

ItemDelegate {
    id: delegate
    width: parent ? parent.width : 100
    implicitHeight: 48

    contentItem: RowLayout {
        spacing: Kirigami.Units.largeSpacing

        Label {
            text: model.id
            font.family: "monospace"
            font.weight: Font.Bold
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            Label {
                text: model.name || model.path
                elide: Text.ElideRight
            }
            Label {
                text: model.date || ""
                font.pointSize: 9
                color: Kirigami.Theme.disabledTextColor
            }
        }

        Button {
            text: i18n("Restaurar")
            icon.name: "edit-undo"
            onClicked: kcm.restoreSnapshot(index)
        }
    }
}
