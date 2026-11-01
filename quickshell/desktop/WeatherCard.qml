import QtQuick
import QtQuick.Layouts
import qs.services
import qs.widgets

// WEATHER: now (icon, temperature, sky) and the next three days, from
// Open-Meteo (services/Weather.qml). Place and unit are set in STATION
// SETUP; a click on the header fetches again.
Rectangle {
    id: root

    color: Theme.surface
    border.width: 2
    border.color: Theme.border

    Header {
        id: header
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 2
        implicitHeight: 28
        fontSize: 22
        strong: false
        title: "WEATHER · " + (Desktop.weather.place || "?")
        info: Weather.loading ? "…" : Weather.error !== "" ? Weather.error : Weather.updated

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: Weather.refresh()
            Accessible.role: Accessible.Button
            Accessible.name: "Refresh the weather"
        }
    }

    ColumnLayout {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: header.bottom
        anchors.bottom: parent.bottom
        anchors.margins: 14
        anchors.topMargin: 8
        spacing: 6

        // Now
        RowLayout {
            Layout.fillWidth: true
            spacing: 14

            Icon {
                name: Weather.icon(Weather.code, Weather.day)
                size: 52
                stroke: 2
                color: Theme.frame
            }

            PText {
                text: Weather.current ? Weather.temp + Weather.unit : "--"
                font.pixelSize: 58
                color: Theme.fg
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                PText {
                    Layout.fillWidth: true
                    text: Weather.describe(Weather.code)
                    font.pixelSize: 22
                    color: Theme.fg2
                    elide: Text.ElideRight
                }

                PText {
                    Layout.fillWidth: true
                    text: Weather.current ? "FEELS " + Weather.feels + "°" : ""
                    font.pixelSize: 20
                    color: Theme.muted
                    elide: Text.ElideRight
                }
            }
        }

        PText {
            Layout.fillWidth: true
            text: Weather.current ? "HUMIDITY " + Weather.humidity + " % · WIND " + Weather.wind + " " + Weather.windUnit : ""
            font.pixelSize: 20
            color: Theme.muted
            elide: Text.ElideRight
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 2
            color: Theme.line
        }

        // The next days
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 0

            Repeater {
                model: Weather.days

                RowLayout {
                    id: day

                    required property var modelData

                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    spacing: 8

                    Icon {
                        name: Weather.icon(day.modelData.code, true)
                        size: 24
                        stroke: 2
                        color: Theme.fg2
                    }

                    Column {
                        Caps {
                            text: day.modelData.day
                            color: Theme.muted
                        }

                        PText {
                            text: day.modelData.max + "° " + day.modelData.min + "°"
                            font.pixelSize: 20
                        }
                    }
                }
            }
        }
    }
}
