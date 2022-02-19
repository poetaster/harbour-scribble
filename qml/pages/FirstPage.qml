import QtQuick 2.6
import Sailfish.Silica 1.0
import Sailfish.Pickers 1.0 // File-Loader
//import Sailfish.Silica.private 1.0 // library, disable system gestures not allowed in Jolla store. Sigh.


Page {
    id: page
    allowedOrientations: Orientation.Portrait
    property bool debug: false
    // drawing variables
    property var myThickness:  [ 0.8, 1.1, 1.3, 1.6, 1.9, 2.1 ]
    property var myColors: [
        "white", Theme.highlightColor, Theme.highlightBackgroundColor, Theme.highlightDimmerColor, "black",
        "darkSlateGray", "slateGray", "dimGray", "gray", "silver",
        "red", "crimson", "#e6007c", "#e700cc", "#9d00e7",
        "darkBlue", "blue", "#0077e7", "#01a9e7", "#00cce7",
        "darkGreen", "green", "#00e600", "#99e600", "#e3e601",
        "maroon", "brown", "chocolate" , "#e78601", "goldenRod",]
    property var paintPageColor : "#e78601"
    property var paintToolColor : "white"
    property var paintToolSize : 2
    property var freeDrawXpos
    property var freeDrawYpos

    // path variables
    property var backImageFilePath : ""
    property string fileName : idFilenameNew.text.toString()
    // this is a workaround until we get file picker working.

    property var savePath : StandardPaths.home + '/Pictures/' //.writableLocation(StandardPaths.DocumentsLocation) //StandardPaths.PicturesLocation

    // UI variables
    property bool displayLock : false
    property var fixedHeight
    property var fixedWidth
    property bool toolColorsPenVisible : false
    property bool toolColorsPageVisible: false
    property bool toolImageVisible : false
    property bool toolThicknessVisible : false
    property bool toolLineCapVisible : false
    property bool toolSaveVisible : false
    property var zoomFactorRotation : 1
    property var firstDown
    property string lineCapStyle : 'butt'

    // undo variables
    property var imageData : []
    property var cStep : -1



    Component.onCompleted: {
        fixedHeight = page.height - idPageHeader.height
        fixedWidth = page.width
    }
   /* WindowGestureOverride {
        id: idGestureOverride
        active: (displayLock === true) ? true : false
        onActiveChanged: {
            console.log("Sailfish gestures active = " + active)
        }
    }*/
    RemorseItem {
        z: 8
        id: remorse
    }
    Component {
        id: imagePickerPage
        ImagePickerPage {
            onSelectedContentPropertiesChanged: {
                backImageFilePath = selectedContentProperties.filePath
                idBackImageLoaded.source = encodeURI(backImageFilePath)
                getScaleOnImageLoad()
            }
        }
    }
    Component {
        id: savePickerPage
        ImagePickerPage {
            onSelectedContentPropertiesChanged: {
                if (debug) console.debug(savePath)
                savePath = selectedContentProperties.filePath
            }
        }
    }
    Timer {
        id: idRefreshCanvastimer
        running: false
        repeat: false
        interval: 10
        onTriggered: {
            freeDrawCanvas.visible = true
        }
    }
    Timer {
        id: idSaveCanvastimer
        running: false
        repeat: false
        interval: 5
        onTriggered: {
            freeDrawCanvas.saveCurrentCanvas()
        }
    }



    PageHeader {
        z: 5
        id: idPageHeader
        width: parent.width
        height: Theme.itemSizeSmall

        Rectangle {
            z: -1
            anchors.fill: parent
            color: Theme.highlightDimmerColor
        }

        Grid {
            id: idHeaderGrid
            width: page.width
            height: Theme.itemSizeSmall
            columns: 9

            IconButton {
                id: idUndoButton
                enabled: ( (cStep+1) > 0 ) ? true : false
                width: parent.width / 9
                height: parent.height
                icon.source: "../symbols/icon-m-undo.svg"
                icon.width: Theme.iconSizeMedium
                icon.height: Theme.iconSizeMedium
                icon.scale: 1.1
                Image {
                    opacity: (idUndoButton.enabled) ? 1 : 0.4
                    anchors.centerIn: parent
                    source: "image://theme/icon-m-delete"
                    mirror:  true
                    scale: 0.45
                }
                onClicked: {
                    toolThicknessVisible = false
                    toolImageVisible = false
                    toolColorsPenVisible = false
                    toolColorsPageVisible = false
                    toolLineCapVisible = false
                    freeDrawCanvas.undo_draw()
                }
                onPressAndHold: {
                    toolThicknessVisible = false
                    toolImageVisible = false
                    toolColorsPenVisible = false
                    toolColorsPageVisible = false
                    toolSaveVisible = false
                    remorse.execute( parent, qsTr("Clear drawing?"), function() {
                        freeDrawCanvas.clear_canvas()
                    })
                }
            }
            Item {
                width: parent.width / 9
                height: parent.height
            }

            IconButton {
                id:toolLineCap
                down: (toolLineCapVisible === true)
                width: parent.width / 9
                icon.source: "../symbols/icon-m-line.svg"
                icon.width: Theme.iconSizeMedium
                icon.height: Theme.iconSizeMedium
                icon.scale: 0.85
                onClicked: {
                    if (toolLineCapVisible === false) {
                        toolLineCapVisible = true
                    }
                    else {
                        toolLineCapVisible = false
                    }
                    toolColorsPenVisible = false
                    toolColorsPageVisible = false
                    toolImageVisible = false
                    toolSaveVisible = false
                }
            }

            IconButton {
                down: (toolColorsPenVisible === true)
                width: parent.width / 9
                icon.width: Theme.iconSizeMedium * 0.6
                icon.height: Theme.iconSizeMedium * 0.6
                //icon.scale: 0.5
                onClicked: {
                    toolThicknessVisible = false
                    toolImageVisible = false
                    toolColorsPageVisible = false
                    toolSaveVisible = false
                    toolLineCapVisible = false
                    if (toolColorsPenVisible === false) {
                        toolColorsPenVisible = true
                    }
                    else {
                        toolColorsPenVisible = false
                    }
                }
                Rectangle {
                    anchors.centerIn: parent
                    width: parent.icon.width
                    height: width
                    radius: width/2
                    scale: 0.63 * 1.05
                    color: (toolColorsPenVisible === true) ? Theme.highlightColor : Theme.primaryColor
                }
                Rectangle {
                    anchors.centerIn: parent
                    width: parent.icon.width
                    height: width
                    radius: width/2
                    scale: 0.58
                    color: (toolColorsPenVisible === true) ? Theme.highlightColor : paintToolColor
                }
            }

            IconButton {
                down: (toolThicknessVisible === true)
                width: parent.width / 9
                icon.source: "image://theme/icon-m-edit"
                icon.width: Theme.iconSizeMedium
                icon.height: Theme.iconSizeMedium
                icon.scale: 0.85
                onClicked: {
                    if (toolThicknessVisible === false) {
                        toolThicknessVisible = true
                    }
                    else {
                        toolThicknessVisible = false
                    }
                    toolColorsPenVisible = false
                    toolColorsPageVisible = false
                    toolImageVisible = false
                    toolSaveVisible = false
                    toolLineCapVisible = false
                }
                Label {
                    id: idPenSizeLabel
                    anchors.right: parent.right
                    anchors.rightMargin: Theme.paddingMedium * 1.1
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: Theme.paddingMedium * 1.1
                    font.pixelSize: Theme.fontSizeTiny
                    text: paintToolSize
                }
            }
            IconButton {
                down: (toolImageVisible === true)
                width: parent.width / 9
                icon.source: "../symbols/icon-m-backimage.svg"
                icon.width: Theme.iconSizeMedium
                icon.height: Theme.iconSizeMedium
                icon.scale: 0.85
                onClicked: {
                    toolThicknessVisible = false
                    toolColorsPenVisible = false
                    toolColorsPageVisible = false
                    toolSaveVisible = false
                    toolLineCapVisible = false
                    if (toolImageVisible === false) {
                        toolImageVisible = true
                    }
                    else {
                        toolImageVisible = false
                    }
                }
            }
            IconButton {
                down: (toolColorsPageVisible === true)
                width: parent.width / 9
                icon.source: "../symbols/icon-m-backcolor.svg"
                icon.width: Theme.iconSizeMedium
                icon.height: Theme.iconSizeMedium
                icon.scale: 0.92
                icon.color: Theme.primaryColor
                onClicked: {
                    toolThicknessVisible = false
                    toolImageVisible = false
                    toolColorsPenVisible = false
                    toolSaveVisible = false
                    toolLineCapVisible = false
                    if (toolColorsPageVisible === false) {
                        toolColorsPageVisible = true
                    }
                    else {
                        toolColorsPageVisible = false
                    }
                }
                Icon {
                    anchors.centerIn: parent
                    width: parent.icon.width
                    height: parent.icon.height
                    source: "../symbols/icon-m-backcolor.svg"
                    scale: parent.icon.scale * 0.925
                    color: paintPageColor
                }

            }

            Item {
                width: parent.width / 9
                height: parent.height
            }
            IconButton {
                down: (toolSaveVisible === true)
                width: parent.width / 9
                icon.source: "image://theme/icon-m-developer-mode"
                icon.width: Theme.iconSizeMedium
                icon.height: Theme.iconSizeMedium
                icon.scale: 0.85
                onClicked: {
                    if (toolSaveVisible === false) {
                        toolSaveVisible = true
                    }
                    else {
                        toolSaveVisible = false
                    }
                    toolThicknessVisible = false
                    toolColorsPenVisible = false
                    toolColorsPageVisible = false
                    toolLineCapVisible = false
                    toolImageVisible = false
                }
                Icon {
                    visible: (displayLock === true)
                    anchors.right: parent.right
                    anchors.rightMargin: -Theme.paddingSmall * 0.85
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: Theme.paddingMedium * 0.9
                    scale: 0.5
                    source: "image://theme/icon-s-secure"
                }
            }
        }
    }



    Rectangle {
        id: idImage
        anchors.top: idPageHeader.bottom
        height: fixedHeight
        width: fixedWidth
        color: paintPageColor

        Item {
            id: photoFrame
            width: parent.width
            height: parent.height

            Image {
                id: idBackImageLoaded
                anchors.fill: parent
                fillMode: Image.PreserveAspectFit
                source: backImageFilePath
                cache: false

                PinchArea {
                    enabled: (toolImageVisible === true && idBackImageLoaded.status !== Image.Null)
                    anchors.fill: parent
                    pinch.target: photoFrame
                    pinch.minimumRotation: 0
                    pinch.maximumRotation: 0
                    pinch.minimumScale: 0.1
                    pinch.maximumScale: 10
                    onPinchUpdated: {
                        if(photoFrame.x < dragArea.drag.minimumX)
                            photoFrame.x = dragArea.drag.minimumX
                        else if(photoFrame.x > dragArea.drag.maximumX)
                            photoFrame.x = dragArea.drag.maximumX

                        if(photoFrame.y < dragArea.drag.minimumY)
                            photoFrame.y = dragArea.drag.minimumY
                        else if(photoFrame.y > dragArea.drag.maximumY)
                            photoFrame.y = dragArea.drag.maximumY
                    }

                    MouseArea {
                        id: dragArea
                        enabled: (toolImageVisible === true && idBackImageLoaded.status !== Image.Null)
                        hoverEnabled: true
                        anchors.fill: parent
                        drag.target: photoFrame
                        drag.minimumX: -idBackImageLoaded.width / 10 * 9
                        drag.maximumX: idBackImageLoaded.width / 10 * 9
                        drag.minimumY: -idBackImageLoaded.height / 10 * 9
                        drag.maximumY: idBackImageLoaded.height / 10 * 9
                        onDoubleClicked: { //Reset size and location of camera
                            photoFrame.x = 0
                            photoFrame.y = 0
                            photoFrame.scale = 1
                        }
                    }
                }

                Rectangle {
                    id: idLoadBackgroundImageFrame
                    visible: (toolImageVisible === true && idBackImageLoaded.status !== Image.Null)
                    anchors.centerIn: parent
                    width: idBackImageLoaded.paintedWidth
                    height: idBackImageLoaded.paintedHeight
                    color: "transparent" //Theme.errorColor
                    opacity: 0.65
                    border.color: Theme.highlightColor //errorColor
                    border.width: Theme.paddingLarge
                }
            }
        }

        Canvas {
            id: freeDrawCanvas
            enabled: (toolImageVisible === true) ? false : true
            anchors.fill: parent
            antialiasing:true
            smooth: true
            renderTarget: Canvas.FramebufferObject // default slower: Canvas.Image
            renderStrategy: Canvas.Immediate // less memory: Canvas.Cooperative
            onPaint: {
                freeDrawCanvas.requestPaint()
            }

            function clear_canvas() {
                cStep = -1
                var ctx = getContext("2d")
                //ctx.clearRect( 0, 0, freeDrawCanvas.width, freeDrawCanvas.height )
                ctx.reset()
                freeDrawCanvas.requestPaint()
            }

            function draw_line() {
                var ctx = getContext('2d')
                ctx.lineJoin = ctx.lineCap = lineCapStyle
                ctx.strokeStyle = paintToolColor
                ctx.lineWidth = paintToolSize * paintToolSize * 2
                ctx.beginPath()
                ctx.moveTo(freeDrawXpos, freeDrawYpos)
                ctx.lineTo(point2.x, point2.y)
                ctx.stroke()
                freeDrawCanvas.requestPaint()
            }

            function draw_point() {
                var ctx = getContext('2d')
                ctx.lineJoin = ctx.lineCap = lineCapStyle
                ctx.strokeStyle = paintToolColor
                ctx.lineWidth = paintToolSize * paintToolSize * 2
                ctx.beginPath()
                ctx.moveTo(point1.x, point1.y)
                ctx.lineTo(point1.x+1, point1.y+1)
                ctx.stroke()
                freeDrawCanvas.requestPaint()
            }

            function draw_spline() {
                var ctx = getContext('2d')
                ctx.lineJoin = ctx.lineCap = lineCapStyle
                if (debug) console.debug(ctx.lineCap)

                ctx.strokeStyle = paintToolColor
                ctx.lineWidth = paintToolSize * paintToolSize * 2
                ctx.beginPath()
                ctx.moveTo(freeDrawXpos, freeDrawYpos)
                ctx.lineTo(point1.x, point1.y)
                ctx.stroke()
                freeDrawXpos = point1.x
                freeDrawYpos = point1.y
                freeDrawCanvas.requestPaint()
            }

            function undo_draw() {
                cStep--
                var ctx = getContext('2d')
                ctx.clearRect( 0, 0, freeDrawCanvas.width, freeDrawCanvas.height )
                if ( (cStep+1) > 0) {
                    ctx.drawImage( imageData[cStep+1], 0, 0, freeDrawCanvas.width, freeDrawCanvas.height )
                }
                freeDrawCanvas.requestPaint()
                freeDrawCanvas.visible = false
                idRefreshCanvastimer.start() // needs to reload canvas, to show clear screen
            }

            function saveCurrentCanvas() {
                cStep++
                var ctx = getContext('2d')
                imageData[cStep+1] = ctx.getImageData( 0, 0, freeDrawCanvas.width, freeDrawCanvas.height )
            }

            MultiPointTouchArea {
                id: mouseCanvasArea
                anchors.fill: parent
                maximumTouchPoints: 2
                touchPoints: [
                    TouchPoint { id: point1 },
                    TouchPoint { id: point2 }
                ]
                onPressed: {
                    freeDrawXpos = point1.x
                    freeDrawYpos = point1.y
                    if(point1.pressed && point2.pressed) {
                        freeDrawCanvas.draw_line()
                    }
                    else {
                        freeDrawCanvas.draw_point()
                    }
                    if (point1.pressed && point2.pressed === false) {
                        firstDown = touchPoints[0]
                    }
                }
                onUpdated: {
                    freeDrawCanvas.draw_spline()
                }

                onReleased: {
                    if(touchPoints.toString() === firstDown.toString() ) {
                        idSaveCanvastimer.start()
                    }

                }

            }
        }
        Rectangle {
            visible: (toolLineCapVisible === true) ? true : false
            anchors.top: freeDrawCanvas.top
            anchors.left: freeDrawCanvas.left
            anchors.leftMargin: Theme.paddingLarge
            anchors.right: freeDrawCanvas.right
            anchors.rightMargin: Theme.paddingLarge
            //color: "transparent"
            color: Theme.highlightDimmerColor
            height: idComboBoxLineCap.height
            width: idComboBoxLineCap.width
            Grid {
            //color: Theme.primaryColor
                id: idComboBoxLineCap
                anchors.centerIn: parent
                //width: parent.width // (itemsPerRowLess-1) * (itemsPerRowLess-2)
                columns: 3
                spacing: 30
                IconButton {
                    icon.source: "../symbols/icon-m-point.svg"
                    icon.scale: 1.6
                    onClicked: {
                        lineCapStyle = "round"
                        toolLineCapVisible = false
                        toolLineCap.icon.source = "../symbols/icon-m-point.svg"
                    }
                }
                IconButton {
                    icon.source: "../symbols/icon-m-area.svg"
                    icon.scale: 1.6
                    onClicked: {
                        lineCapStyle = "square"
                        toolLineCapVisible = false
                        toolLineCap.icon.source = "../symbols/icon-m-area.svg"
                    }
                }
                IconButton {
                    icon.source: "../symbols/icon-m-line.svg"
                    icon.scale: 1.6
                    onClicked: {
                        lineCapStyle = "butt"
                        toolLineCapVisible = false
                        toolLineCap.icon.source = "../symbols/icon-m-line.svg"
                    }
                }
            }
            /*
            Rectangle {
                z: -1
                anchors.fill: parent
                anchors.bottomMargin: -Theme.paddingMedium
                anchors.leftMargin: -Theme.paddingMedium
                anchors.rightMargin: -Theme.paddingMedium
                color: Theme.highlightDimmerColor
            }*/
        }
        Rectangle {
            id: idSubmenuThickness
            visible: (toolThicknessVisible === true) ? true : false
            anchors.top: freeDrawCanvas.top
            anchors.left: freeDrawCanvas.left
            anchors.leftMargin: Theme.paddingLarge
            anchors.right: freeDrawCanvas.right
            anchors.rightMargin: Theme.paddingLarge
            color: "transparent"
            height: idThicknessGrid.height

            Grid {
                id: idThicknessGrid
                width: parent.width
                columns: 6
                Repeater {
                    id: idRepeater
                    model: myThickness
                    IconButton {
                        width: parent.width / parent.columns
                        height: Theme.itemSizeSmall
                        onClicked: {
                            toolThicknessVisible = false
                            paintToolSize = index+1
                        }

                        Rectangle {
                            anchors.centerIn: parent
                            width: (index+1) * (index+1) * 2.2
                            height: parent.height * 0.9
                            radius: width/2
                            color: Theme.primaryColor
                        }
                    }
                }

            }

            Rectangle {
                z: -1
                anchors.fill: parent
                anchors.bottomMargin: -Theme.paddingMedium
                anchors.leftMargin: -Theme.paddingMedium
                anchors.rightMargin: -Theme.paddingMedium
                color: Theme.highlightDimmerColor
            }
        }

        Rectangle {
            id: idSubmenuColorPen
            visible: (toolColorsPenVisible === true) ? true : false
            anchors.top: freeDrawCanvas.top
            anchors.left: freeDrawCanvas.left
            anchors.leftMargin: Theme.paddingLarge
            anchors.right: freeDrawCanvas.right
            anchors.rightMargin: Theme.paddingLarge
            color: "transparent"
            height: idColorGridPen.height

            Grid {
                id: idColorGridPen
                width: parent.width
                columns: 5
                Repeater {
                    model: myColors
                    Rectangle {
                        width: parent.width / parent.columns
                        height: (modelData !== "none") ? width : Theme.paddingMedium
                        color: (modelData !== "none") ? modelData : Theme.highlightDimmerColor
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                //if (modelData !== "none") {
                                    paintToolColor = modelData.toString()
                                    toolColorsPenVisible = false
                                //}
                            }
                        }
                    }
                }
            }
            Rectangle {
                z: -1
                anchors.fill: parent
                anchors.bottomMargin: -Theme.paddingMedium
                anchors.leftMargin: -Theme.paddingMedium
                anchors.rightMargin: -Theme.paddingMedium
                color: Theme.highlightDimmerColor
            }
        }

        Rectangle {
            id: idSubmenuColorPage
            visible: (toolColorsPageVisible === true) ? true : false
            anchors.top: freeDrawCanvas.top
            anchors.left: freeDrawCanvas.left
            anchors.leftMargin: Theme.paddingLarge
            anchors.right: freeDrawCanvas.right
            anchors.rightMargin: Theme.paddingLarge
            color: "transparent"
            height: idColorGridPage.height

            Grid {
                id: idColorGridPage
                width: parent.width
                columns: 5
                Repeater {
                    model: myColors
                    Rectangle {
                        width: parent.width / parent.columns
                        height: (modelData !== "none") ? width : Theme.paddingMedium
                        color: (modelData !== "none") ? modelData : Theme.highlightDimmerColor
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                if (modelData !== "none") {
                                    paintPageColor = modelData.toString()
                                    toolColorsPageVisible = false
                                }
                            }
                        }
                    }
                }
            }
            Rectangle {
                z: -1
                anchors.fill: parent
                anchors.bottomMargin: -Theme.paddingMedium
                anchors.leftMargin: -Theme.paddingMedium
                anchors.rightMargin: -Theme.paddingMedium
                color: Theme.highlightDimmerColor
            }
        }

        Rectangle {
            id: idSubmenuBackgroundmage
            visible: (toolImageVisible === true) ? true : false
            anchors.top: freeDrawCanvas.top
            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width / 6 * 4 - Theme.paddingLarge
            color: "transparent"
            height: idImageGrid.height

            Grid {
                id: idImageGrid
                width: parent.width
                columns: 4

                IconButton {
                    width: parent.width / parent.columns
                    height: Theme.itemSizeSmall
                    icon.source: "image://theme/icon-m-file-folder"
                    icon.width: Theme.iconSizeMedium
                    icon.height: Theme.iconSizeMedium
                    icon.scale: 0.85
                    onClicked: {
                        pageStack.push(imagePickerPage)
                    }
                }

                IconButton {
                    opacity: (idBackImageLoaded.status !== Image.Null) ? 1 : 0.3
                    width: parent.width / parent.columns
                    height: Theme.itemSizeSmall
                    icon.source: "image://theme/icon-m-rotate-left"
                    icon.width: Theme.iconSizeMedium
                    icon.height: Theme.iconSizeMedium
                    icon.scale: 0.85
                    onClicked: {
                        //toolImageVisible = false
                        if (idBackImageLoaded.status !== Image.Null) {
                            idBackImageLoaded.rotation = idBackImageLoaded.rotation - 90
                            if ( idBackImageLoaded.rotation % 180 === 0) {
                                idBackImageLoaded.scale = 1
                            }
                            else {
                                idBackImageLoaded.scale = 1/zoomFactorRotation
                            }
                        }
                    }
                }

                IconButton {
                    opacity: (idBackImageLoaded.status !== Image.Null) ? 1 : 0.3
                    width: parent.width / parent.columns
                    height: Theme.itemSizeSmall
                    icon.source: "image://theme/icon-m-rotate-right"
                    icon.width: Theme.iconSizeMedium
                    icon.height: Theme.iconSizeMedium
                    icon.scale: 0.85
                    onClicked: {
                        //toolImageVisible = false
                        if (idBackImageLoaded.status !== Image.Null) {
                            idBackImageLoaded.rotation = idBackImageLoaded.rotation + 90
                            if ( idBackImageLoaded.rotation % 180 === 0) {
                                idBackImageLoaded.scale = 1
                            }
                            else {
                                idBackImageLoaded.scale = 1/zoomFactorRotation
                            }
                        }
                    }
                }

                IconButton {
                    opacity: (idBackImageLoaded.status !== Image.Null) ? 1 : 0.3
                    width: parent.width / parent.columns
                    height: Theme.itemSizeSmall
                    icon.source: "image://theme/icon-m-cancel" //delete //remove
                    icon.width: Theme.iconSizeMedium
                    icon.height: Theme.iconSizeMedium
                    icon.scale: 0.85
                    onClicked: {
                        if (idBackImageLoaded.status !== Image.Null) {
                            idBackImageLoaded.source = ""
                            getScaleOnImageLoad()
                        }
                    }
                }

            }
            Rectangle {
                z: -1
                anchors.fill: parent
                anchors.bottomMargin: -Theme.paddingMedium
                anchors.leftMargin: -Theme.paddingMedium
                anchors.rightMargin: -Theme.paddingMedium
                color: Theme.highlightDimmerColor
            }
        }

        Rectangle {
            id: idSubmenuSave
            visible: (toolSaveVisible === true) ? true : false
            anchors.top: freeDrawCanvas.top
            anchors.left: freeDrawCanvas.left
            anchors.leftMargin: Theme.paddingLarge
            anchors.right: freeDrawCanvas.right
            anchors.rightMargin: Theme.paddingLarge
            color: "transparent"
            height: idThicknessGrid.height

            Row {
                id: idSaveGrid
                width: parent.width
                IconButton {
                    width: parent.width / 6
                    icon.source: ( displayLock === false ) ? "../symbols/icon-m-nogestures.svg" : "../symbols/icon-m-gestures.svg"
                    icon.width: Theme.iconSizeMedium
                    icon.height: Theme.iconSizeMedium
                    icon.scale: 0.85 // 0.92
                    onClicked: {
                        toolSaveVisible = false
                        if (displayLock === true) {
                            displayLock = false
                        }
                        else displayLock = true
                    }
                }
                TextField {
                    id: idFilenameNew
                    width: parent.width / 6 * 4
                    height: Theme.itemSizeSmall * 1.1
                    anchors.top: parent.top
                    anchors.topMargin: parent.height / 4.75
                    font.pixelSize: Theme.fontSizeExtraSmall
                    horizontalAlignment: Text.AlignLeft
                    text: "Scribble"
                    EnterKey.onClicked: {
                        if (text.length === 0) {
                            text = "Scribble"
                        }
                        idFilenameNew.focus = false
                    }
                    validator: RegExpValidator { regExp: /^[^<>'\"/;*:`#?]*$/ } // negative list
                    onTextChanged: {
                        var oldText = text
                        if (text.length >= 16) {
                            text = ""
                            text = oldText
                        }
                    }
                    Label {
                        anchors.top: parent.baseline
                        anchors.right: parent.right
                        font.pixelSize: Theme.fontSizeExtraSmall
                        text: ". png"
                    }
                }

                IconButton {
                    width: parent.width / 6
                    icon.source: "image://theme/icon-m-message-forward" //file-other-light"
                    icon.width: Theme.iconSizeMedium
                    icon.height: Theme.iconSizeMedium
                    icon.scale: 0.85
                    onClicked: {
                        toolSaveVisible = false;
                        //pageStack.push(savePickerPage)
                        if (debug) console.debug(savePath)
                        idImage.grabToImage(function(image) {
                            image.saveToFile(  savePath + fileName + ".png" )
                        })
                    }
                }
            }

            Rectangle {
                z: -1
                anchors.fill: parent
                anchors.bottomMargin: -Theme.paddingMedium
                anchors.leftMargin: -Theme.paddingMedium
                anchors.rightMargin: -Theme.paddingMedium
                color: Theme.highlightDimmerColor
            }
        }
    }



    function getScaleOnImageLoad() {
        //toolImageVisible = false
        idBackImageLoaded.rotation = 0
        idBackImageLoaded.scale = 1
        photoFrame.x = 0
        photoFrame.y = 0
        photoFrame.scale = 1
        var var1 = idBackImageLoaded.sourceSize.width / idBackImageLoaded.sourceSize.height
        var var2 = idImage.width / idImage.height
        if (var1 > var2) {
            zoomFactorRotation = idBackImageLoaded.width / idImage.height
        }
        else {
            zoomFactorRotation = idBackImageLoaded.height / idImage.width
        }
    }



}
