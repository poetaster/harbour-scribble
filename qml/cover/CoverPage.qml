import QtQuick 2.0
import Sailfish.Silica 1.0

CoverBackground {
    /*
    Label {
        id: label
        anchors.centerIn: parent
        text: qsTr("ImageWorks")
    }
    */
    Image {
        id: name
        anchors.centerIn: parent
        source: "scribble.svg"
        width: Theme.iconSizeLarge
        fillMode: Image.PreserveAspectFit
        height: Theme.iconSizeLarge
    }

    /*
    CoverActionList {
        id: coverAction

        CoverAction {
            iconSource: "image://theme/icon-cover-next"
        }

        CoverAction {
            iconSource: "image://theme/icon-cover-pause"
        }
    }
    */
}
