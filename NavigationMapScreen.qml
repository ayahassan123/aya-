import QtQuick 2.15
import QtLocation 5.15
import QtPositioning 5.15
import QtQml 2.15
import QtQuick.Controls 2.15
import QtGraphicalEffects 1.15
import Style 1.0
import QtQuick.Layouts 1.15

Page {
    id: pageMap
    property var currentLoc: QtPositioning.coordinate(30.33, 31.75)
    property bool isRoutingStart: true
    property bool runMapAnimation: true
    property bool enableGradient: true
    padding: 0

    function startAnimation() {
        // Disabled to avoid interference with searchGeoModel
    }

    RadialGradient {
        z: 1
        visible: enableGradient
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#80000000" }
            GradientStop { position: 0.72; color: "#00000000" }
        }
    }

    Map {
        id: map
        anchors.fill: parent
        copyrightsVisible: true
        center: QtPositioning.coordinate(30.33, 31.75)
        zoomLevel: 13.3

        plugin: Plugin {
            id: mapPlugin
            name: "osm"
            Component.onCompleted: {
                console.log("Map plugin initialized, supported: ", mapPlugin.supported())
                if (!mapPlugin.supported()) {
                    console.log("Map plugin not supported, check OpenSSL or internet connection")
                }
            }
        }

        PinchArea {
            anchors.fill: parent
            onPinchUpdated: {
                var newZoom = map.zoomLevel + (pinch.scale - pinch.previousScale)
                map.zoomLevel = Math.min(Math.max(newZoom, 2), 20)
            }
            onPinchFinished: {
                map.zoomLevel = Math.min(Math.max(map.zoomLevel, 2), 20)
            }

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.NoButton
                onWheel: {
                    if (wheel.angleDelta.y > 0 && map.zoomLevel < 20) {
                        map.zoomLevel += 0.5
                    } else if (wheel.angleDelta.y < 0 && map.zoomLevel > 2) {
                        map.zoomLevel -= 0.5
                    }
                }
            }
        }

        MapItemView {
            id: mapRouteLine
            model: routeModel
            delegate: Component {
                MapRoute {
                    route: routeData
                    line.color: "aqua"
                    line.width: adaptive.width(7)
                }
            }
        }

        MapQuickItem {
            id: currentLocationMarker
            coordinate: QtPositioning.coordinate(30.31, 31.726)
            visible: true
            z: 1
            onCoordinateChanged: {
                if (isRoutingStart) map.center = coordinate
            }
            sourceItem: Rectangle {
                width: adaptive.width(100) * (map.zoomLevel / 17)
                height: adaptive.height(100) * (map.zoomLevel / 17)
                color: "transparent"
                anchors.centerIn: parent
                radius: 180
                Image {
                    id: car
                    width: adaptive.width(100) * (map.zoomLevel / 17)
                    height: adaptive.height(100) * (map.zoomLevel / 17)
                    source: "qrc:/Map/CarMarker.png"
                    anchors.centerIn: parent
                }
            }
            Behavior on coordinate { PropertyAnimation { duration: 5000 } }
        }

        MapQuickItem {
            id: destinationMarker
            visible: false
            z: 1
            sourceItem: Rectangle {
                width: adaptive.width(50) * (map.zoomLevel / 17)
                height: adaptive.height(50) * (map.zoomLevel / 17)
                color: "transparent"
                anchors.centerIn: parent
                radius: 180
                AnimatedImage {
                    width: adaptive.width(50) * (map.zoomLevel / 17)
                    height: adaptive.height(50) * (map.zoomLevel / 17)
                    source: "qrc:/animIcons/icons8-destination.gif"
                    anchors.centerIn: parent
                }
            }
        }

        MapQuickItem {
            id: startMarker
            visible: false
            z: 1
            sourceItem: Rectangle {
                width: adaptive.width(50) * (map.zoomLevel / 17)
                height: adaptive.height(50) * (map.zoomLevel / 17)
                color: "transparent"
                anchors.centerIn: parent
                radius: 180
                Image {
                    width: adaptive.width(50) * (map.zoomLevel / 17)
                    height: adaptive.height(50) * (map.zoomLevel / 17)
                    source: "qrc:/Map/LocationMarker.png"
                    anchors.centerIn: parent
                }
            }
        }

        RouteModel {
            id: routeModel
            plugin: mapPlugin
            query: RouteQuery { id: routeQuery }
            onRoutesChanged: {
                if (count > 0) {
                    map.center = routeModel.get(0).path[Math.floor(routeModel.get(0).path.length / 2)]
                    startMarker.coordinate = currentLoc
                    destinationMarker.visible = true
                    startMarker.visible = true
                    animationTimer.running = true
                }
            }
        }

        Timer {
            id: animationTimer
            interval: 3000
            onTriggered: {
                startMarker.visible = true
                currentLocationMarker.visible = true
                isRoutingStart = true
                simulateDrive.path = routeModel.get(0).path
                routeStartAnimation.running = true
                simulateDrive.running = true
            }
        }

        Timer {
            id: simulateDrive
            property var path
            property int index
            interval: 1000
            repeat: true
            onTriggered: {
                if (path && index < path.length) {
                    currentLocationMarker.coordinate = path[index]
                    index++
                } else {
                    simulateDrive.stop()
                }
            }
        }
    }

    Column {
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 10
        spacing: 10
        z: 2

        Button {
            id: zoomInButton
            width: adaptive.width(50)
            height: adaptive.height(50)
            text: "+"
            font.family: Style.fontFamily
            font.pixelSize: 24
            onClicked: {
                if (map.zoomLevel < 20) map.zoomLevel += 0.5
            }
            background: Rectangle {
                color: Style.isDark ? Style.black10 : Style.white
                radius: 25
                border.color: Style.isDark ? Style.black40 : Style.black20
                border.width: 1
            }
            contentItem: Text {
                text: parent.text
                font: parent.font
                color: Style.isDark ? Style.white : Style.black20
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
            DropShadow {
                anchors.fill: parent
                horizontalOffset: 2
                verticalOffset: 2
                radius: 8
                samples: 17
                color: "#80000000"
                source: parent.background
            }
        }

        Button {
            id: zoomOutButton
            width: adaptive.width(50)
            height: adaptive.height(50)
            text: "-"
            font.family: Style.fontFamily
            font.pixelSize: 24
            onClicked: {
                if (map.zoomLevel > 2) map.zoomLevel -= 0.5
            }
            background: Rectangle {
                color: Style.isDark ? Style.black10 : Style.white
                radius: 25
                border.color: Style.isDark ? Style.black40 : Style.black20
                border.width: 1
            }
            contentItem: Text {
                text: parent.text
                font: parent.font
                color: Style.isDark ? Style.white : Style.black20
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
            DropShadow {
                anchors.fill: parent
                horizontalOffset: 2
                verticalOffset: 2
                radius: 8
                samples: 17
                color: "#80000000"
                source: parent.background
            }
        }
    }

    TextField {
        id: searchField
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.margins: 40
        width: adaptive.width(400)
        height: adaptive.height(60)
        placeholderText: virtualKeyboard.isEnglish ? "Enter location..." : "أدخل الموقع..."
        font.family: Style.fontFamily
        font.pixelSize: 18
        color: Style.isDark ? Style.white : Style.black20
        background: Rectangle {
            color: Style.isDark ? Style.black10 : Style.white
            radius: 15
            border.color: Style.isDark ? Style.black40 : Style.black20
            border.width: 2
        }
        onTextChanged: {
            console.log("Text changed to:", searchField.text)
            searchTimer.restart()
        }
        MouseArea {
            anchors.fill: parent
            onClicked: {
                virtualKeyboard.visible = true
                console.log("Search field clicked, keyboard visible:", virtualKeyboard.visible)
            }
        }
    }

    Timer {
        id: searchTimer
        interval: 500
        onTriggered: {
            var queryText = searchField.text.trim()
            console.log("Timer triggered, queryText:", queryText)
            if (queryText !== "") {
                console.log("Starting search with query:", queryText)
                searchGeoModel.query = queryText
                searchGeoModel.update()
            } else {
                console.log("Empty text, resetting map")
                map.center = QtPositioning.coordinate(30.33, 31.75)
                map.zoomLevel = 13.3
                destinationMarker.visible = false
            }
        }
    }

    Rectangle {
        id: virtualKeyboard
        width: adaptive.width(600)
        height: adaptive.height(300)
        color: "#e0e0e0"
        radius: 10
        visible: false
        anchors {
            horizontalCenter: parent.horizontalCenter
            top: searchField.bottom
            topMargin: 20
        }
        z: 2
        property bool isEnglish: true
        property bool isShift: false

        Column {
            anchors.centerIn: parent
            spacing: 10
            Row {
                spacing: 5
                anchors.horizontalCenter: parent.horizontalCenter
                Repeater {
                    model: virtualKeyboard.isEnglish ? ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0"] : ["١", "٢", "٣", "٤", "٥", "٦", "٧", "٨", "٩", "٠"]
                    Rectangle {
                        width: adaptive.width(40)
                        height: adaptive.height(40)
                        color: "#ffffff"
                        radius: 5
                        border.color: "#666666"
                        Text {
                            anchors.centerIn: parent
                            text: modelData
                            font.pixelSize: 18
                            color: "#333333"
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                searchField.text += modelData
                                console.log("Key pressed:", modelData)
                            }
                            onPressed: parent.color = "#cccccc"
                            onReleased: parent.color = "#ffffff"
                        }
                    }
                }
            }
            Row {
                spacing: 5
                anchors.horizontalCenter: parent.horizontalCenter
                Repeater {
                    model: virtualKeyboard.isEnglish ? ["q", "w", "e", "r", "t", "y", "u", "i", "o", "p"] : ["ض", "ص", "ث", "ق", "ف", "غ", "ع", "ه", "خ", "ح"]
                    Rectangle {
                        width: adaptive.width(40)
                        height: adaptive.height(40)
                        color: "#ffffff"
                        radius: 5
                        border.color: "#666666"
                        Text {
                            anchors.centerIn: parent
                            text: virtualKeyboard.isShift && virtualKeyboard.isEnglish ? modelData.toUpperCase() : modelData
                            font.pixelSize: 18
                            color: "#333333"
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                searchField.text += virtualKeyboard.isShift && virtualKeyboard.isEnglish ? modelData.toUpperCase() : modelData
                                console.log("Key pressed:", virtualKeyboard.isShift && virtualKeyboard.isEnglish ? modelData.toUpperCase() : modelData)
                            }
                            onPressed: parent.color = "#cccccc"
                            onReleased: parent.color = "#ffffff"
                        }
                    }
                }
            }
            Row {
                spacing: 5
                anchors.horizontalCenter: parent.horizontalCenter
                Repeater {
                    model: virtualKeyboard.isEnglish ? ["a", "s", "d", "f", "g", "h", "j", "k", "l"] : ["ش", "س", "ي", "ب", "ل", "ا", "ت", "ن", "م"]
                    Rectangle {
                        width: adaptive.width(40)
                        height: adaptive.height(40)
                        color: "#ffffff"
                        radius: 5
                        border.color: "#666666"
                        Text {
                            anchors.centerIn: parent
                            text: virtualKeyboard.isShift && virtualKeyboard.isEnglish ? modelData.toUpperCase() : modelData
                            font.pixelSize: 18
                            color: "#333333"
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                searchField.text += virtualKeyboard.isShift && virtualKeyboard.isEnglish ? modelData.toUpperCase() : modelData
                                console.log("Key pressed:", virtualKeyboard.isShift && virtualKeyboard.isEnglish ? modelData.toUpperCase() : modelData)
                            }
                            onPressed: parent.color = "#cccccc"
                            onReleased: parent.color = "#ffffff"
                        }
                    }
                }
            }
            Row {
                spacing: 5
                anchors.horizontalCenter: parent.horizontalCenter
                Rectangle {
                    width: adaptive.width(60)
                    height: adaptive.height(40)
                    color: virtualKeyboard.isShift ? "#cccccc" : "#ffffff"
                    radius: 5
                    border.color: "#666666"
                    Text {
                        anchors.centerIn: parent
                        text: "Shift"
                        font.pixelSize: 18
                        color: "#333333"
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            virtualKeyboard.isShift = !virtualKeyboard.isShift
                            console.log("Shift toggled, isShift:", virtualKeyboard.isShift)
                        }
                        onPressed: parent.color = "#999999"
                        onReleased: parent.color = virtualKeyboard.isShift ? "#cccccc" : "#ffffff"
                    }
                }
                Repeater {
                    model: virtualKeyboard.isEnglish ? ["z", "x", "c", "v", "b", "n", "m", "."] : ["ظ", "ط", "ذ", "د", "ز", "ج", "و", "ر"]
                    Rectangle {
                        width: adaptive.width(40)
                        height: adaptive.height(40)
                        color: "#ffffff"
                        radius: 5
                        border.color: "#666666"
                        Text {
                            anchors.centerIn: parent
                            text: virtualKeyboard.isShift && virtualKeyboard.isEnglish ? modelData.toUpperCase() : modelData
                            font.pixelSize: 18
                            color: "#333333"
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                searchField.text += virtualKeyboard.isShift && virtualKeyboard.isEnglish ? modelData.toUpperCase() : modelData
                                console.log("Key pressed:", virtualKeyboard.isShift && virtualKeyboard.isEnglish ? modelData.toUpperCase() : modelData)
                            }
                            onPressed: parent.color = "#cccccc"
                            onReleased: parent.color = "#ffffff"
                        }
                    }
                }
            }
            Row {
                spacing: 5
                anchors.horizontalCenter: parent.horizontalCenter
                Rectangle {
                    width: adaptive.width(100)
                    height: adaptive.height(40)
                    color: "#ffffff"
                    radius: 5
                    border.color: "#666666"
                    Text {
                        anchors.centerIn: parent
                        text: "Space"
                        font.pixelSize: 18
                        color: "#333333"
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            searchField.text += " "
                            console.log("Space pressed")
                        }
                        onPressed: parent.color = "#cccccc"
                        onReleased: parent.color = "#ffffff"
                    }
                }
                Rectangle {
                    width: adaptive.width(60)
                    height: adaptive.height(40)
                    color: "#ff9999"
                    radius: 5
                    border.color: "#666666"
                    Text {
                        anchors.centerIn: parent
                        text: "Back"
                        font.pixelSize: 18
                        color: "#333333"
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            searchField.text = searchField.text.slice(0, -1)
                            console.log("Back pressed, text:", searchField.text)
                        }
                        onPressed: parent.color = "#ff6666"
                        onReleased: parent.color = "#ff9999"
                    }
                }
                Rectangle {
                    width: adaptive.width(60)
                    height: adaptive.height(40)
                    color: "#99ff99"
                    radius: 5
                    border.color: "#666666"
                    Text {
                        anchors.centerIn: parent
                        text: "Search"
                        font.pixelSize: 18
                        color: "#333333"
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            var queryText = searchField.text.trim()
                            console.log("Search button pressed, query:", queryText)
                            if (queryText !== "") {
                                searchGeoModel.query = queryText
                                searchGeoModel.update()
                                virtualKeyboard.visible = false
                            } else {
                                console.log("Empty search query, resetting map")
                                map.center = QtPositioning.coordinate(30.33, 31.75)
                                map.zoomLevel = 13.3
                                destinationMarker.visible = false
                                virtualKeyboard.visible = false
                            }
                        }
                        onPressed: parent.color = "#66cc66"
                        onReleased: parent.color = "#99ff99"
                    }
                }
                Rectangle {
                    width: adaptive.width(60)
                    height: adaptive.height(40)
                    color: "#ffcc99"
                    radius: 5
                    border.color: "#666666"
                    Text {
                        anchors.centerIn: parent
                        text: "Close"
                        font.pixelSize: 18
                        color: "#333333"
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            virtualKeyboard.visible = false
                            console.log("Close keyboard pressed")
                        }
                        onPressed: parent.color = "#ff9966"
                        onReleased: parent.color = "#ffcc99"
                    }
                }
                Rectangle {
                    width: adaptive.width(60)
                    height: adaptive.height(40)
                    color: "#99ccff"
                    radius: 5
                    border.color: "#666666"
                    Text {
                        anchors.centerIn: parent
                        text: virtualKeyboard.isEnglish ? "AR" : "EN"
                        font.pixelSize: 18
                        color: "#333333"
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            virtualKeyboard.isEnglish = !virtualKeyboard.isEnglish
                            virtualKeyboard.isShift = false
                            console.log("Language toggled, isEnglish:", virtualKeyboard.isEnglish)
                        }
                        onPressed: parent.color = "#66b3ff"
                        onReleased: parent.color = "#99ccff"
                    }
                }
            }
        }
    }

    GeocodeModel {
        id: searchGeoModel
        plugin: mapPlugin
        autoUpdate: false
        onLocationsChanged: {
            console.log("SearchGeoModel locations changed, count:", count, "First location:", count > 0 ? get(0).coordinate : "N/A")
            if (count > 0) {
                var locationCoord = get(0).coordinate
                if (locationCoord.isValid) {
                    console.log("Search success, moving map to:", locationCoord.latitude, locationCoord.longitude)
                    map.center = locationCoord
                    map.zoomLevel = 15
                    destinationMarker.coordinate = locationCoord
                    destinationMarker.visible = true
                    routeQuery.clearWaypoints()
                    routeQuery.addWaypoint(currentLoc)
                    routeQuery.addWaypoint(locationCoord)
                    routeModel.update()
                } else {
                    console.log("Invalid coordinates returned for query:", searchGeoModel.query)
                    map.center = QtPositioning.coordinate(30.33, 31.75)
                    map.zoomLevel = 13.3
                    destinationMarker.visible = false
                }
            } else {
                console.log("Search failed, no locations found for query:", searchGeoModel.query)
                map.center = QtPositioning.coordinate(30.33, 31.75)
                map.zoomLevel = 13.3
                destinationMarker.visible = false
            }
        }
        onErrorChanged: {
            if (error !== GeocodeModel.NoError) {
                console.log("SearchGeoModel error:", error, "Error string:", errorString)
                map.center = QtPositioning.coordinate(30.33, 31.75)
                map.zoomLevel = 13.3
                destinationMarker.visible = false
            }
        }
        onStatusChanged: {
            console.log("SearchGeoModel status:", status, "Query:", query, "Is loading:", status === GeocodeModel.Loading)
        }
    }

    SequentialAnimation {
        id: routeStartAnimation
        running: false
        NumberAnimation {
            id: tiltAnimation
            target: map
            duration: 6000
            properties: "tilt"
            from: map.tilt
            to: 45
        }
        NumberAnimation {
            id: bearingAnimation
            target: map
            duration: 6000
            properties: "bearing"
            from: map.bearing
            to: 90
        }
    }
}
