import QtQuick 2.14
import QtQuick.Controls 2.14

ApplicationWindow {
    visible: true
    width: 400
    height: 640
    title: qsTr("Tabs")

    header: Rectangle {
        height: 70
        color: Style.navBarBackgroundColor

        Text {
            anchors.centerIn: parent
            text: qsTr(swipeView.itemAt(swipeView.currentIndex).name)
            color: Style.navBarForegroundColor
            font.pixelSize: Style.navBarTextSize
        }
    }

    SwipeView {
        id: swipeView
        anchors.fill: parent
        currentIndex: tabBar.currentIndex

        PageView {
            name: "Repositories"
        }

        PageView {
            name: "Create repository"
        }

        PageView {
            name: "This is your profile"
        }
    }

    footer: TabBar {
        id: tabBar
        currentIndex: swipeView.currentIndex

        IconTabButton {
            text: qsTr("Repos")
            icon.source: "qrc:/icons/search.svg"
        }

        IconTabButton {
            text: qsTr("Create Repo")
            icon.source: "qrc:/icons/plus.svg"
        }

        IconTabButton {
            text: qsTr("Profile")
            icon.source: "qrc:/icons/user_male.svg"
        }
    }
}
