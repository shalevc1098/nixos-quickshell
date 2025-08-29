import qs.common
import qs.widgets
import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

Scope {
    id: calendarScope
    
    property alias anchorWindow: popupBox.anchorWindow
    property alias anchorItem: popupBox.anchorItem
    property alias showing: popupBox.showing
    
    // Debug shortcut for testing
    GlobalShortcut {
        appid: "quickshell"
        name: "calendarToggle"
        description: "Toggle calendar popup"
        
        onPressed: {
            popupBox.showing = !popupBox.showing
        }
    }
    
    PopupBox {
        id: popupBox
        
        popupWidth: 340
        popupHeight: 380
        xOffset: 0
        autoHeight: true
        
        content: Component {
            Item {
                implicitWidth: popupBox.popupWidth
                implicitHeight: mainColumn.implicitHeight + 20
                
                Column {
                    id: mainColumn
                    anchors.centerIn: parent
                    width: parent.width - 20
                    spacing: 12
                    
                    // Header with month/year and navigation
                    Item {
                        width: parent.width
                        height: 32
                        
                        Row {
                            anchors.centerIn: parent
                            spacing: 16
                            
                            MouseArea {
                                width: 24
                                height: 24
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: calendar.previousMonth()
                                
                                Text {
                                    anchors.centerIn: parent
                                    text: "󰅁"  // Chevron right rotated to point left
                                    font.family: "SF Pro Display, JetBrainsMono Nerd Font Propo"
                                    font.pixelSize: 16
                                    color: parent.containsMouse ? Appearance.m3colors.primary : Appearance.m3colors.on_surface
                                }
                            }
                            
                            Text {
                                id: monthYearText
                                text: calendar.monthYear
                                font.family: "SF Pro Display"
                                font.pixelSize: 18
                                font.weight: Font.Medium
                                color: Appearance.m3colors.on_surface
                            }
                            
                            MouseArea {
                                width: 24
                                height: 24
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: calendar.nextMonth()
                                
                                Text {
                                    anchors.centerIn: parent
                                    text: "󰅁"  // Chevron right
                                    font.family: "SF Pro Display, JetBrainsMono Nerd Font Propo"
                                    font.pixelSize: 16
                                    rotation: 180
                                    color: parent.containsMouse ? Appearance.m3colors.primary : Appearance.m3colors.on_surface
                                }
                            }
                        }
                    }
                    
                    // Day headers
                    Row {
                        width: parent.width
                        
                        Repeater {
                            model: ["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"]
                            
                            Item {
                                width: parent.parent.width / 7
                                height: 24
                                
                                Text {
                                    anchors.centerIn: parent
                                    text: modelData
                                    font.family: "SF Pro Display"
                                    font.pixelSize: 12
                                    font.weight: Font.Medium
                                    color: Appearance.m3colors.on_surface_variant
                                }
                            }
                        }
                    }
                    
                    // Calendar grid
                    Grid {
                        width: parent.width
                        columns: 7
                        rows: 6
                        
                        Repeater {
                            model: 42  // 6 weeks * 7 days
                            
                            Item {
                                width: parent.width / 7
                                height: 36
                                
                                Rectangle {
                                    anchors.centerIn: parent
                                    width: 32
                                    height: 32
                                    radius: 16
                                    color: calendar.isToday(index) ? Appearance.m3colors.primary : 
                                           (dayMouseArea.containsMouse && calendar.isCurrentMonth(index) ? Appearance.m3colors.surface_container_highest : "transparent")
                                    
                                    Behavior on color {
                                        ColorAnimation { duration: 150 }
                                    }
                                    
                                    MouseArea {
                                        id: dayMouseArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: calendar.isCurrentMonth(index) ? Qt.PointingHandCursor : Qt.ArrowCursor
                                        
                                        onClicked: {
                                            if (calendar.isCurrentMonth(index)) {
                                                const day = calendar.getDayNumber(index)
                                                console.log("Selected date:", calendar.year, calendar.month + 1, day)
                                            }
                                        }
                                    }
                                    
                                    Text {
                                        anchors.centerIn: parent
                                        text: calendar.getDayNumber(index).toString()
                                        font.family: "SF Pro Display"
                                        font.pixelSize: 14
                                        color: calendar.isToday(index) ? Appearance.m3colors.on_primary : 
                                               (calendar.isCurrentMonth(index) ? Appearance.m3colors.on_surface : Appearance.m3colors.on_surface_variant)
                                        opacity: calendar.isCurrentMonth(index) ? 1.0 : 0.5
                                    }
                                }
                            }
                        }
                    }
                    
                    // Today button
                    Rectangle {
                        width: parent.width
                        height: 36
                        radius: 18
                        color: todayMouseArea.containsMouse ? Appearance.m3colors.primary : Appearance.m3colors.surface_container_high
                        
                        Behavior on color {
                            ColorAnimation { duration: 150 }
                        }
                        
                        MouseArea {
                            id: todayMouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: calendar.goToToday()
                            
                            Text {
                                anchors.centerIn: parent
                                text: "Today"
                                font.family: "SF Pro Display"
                                font.pixelSize: 14
                                font.weight: Font.Medium
                                color: todayMouseArea.containsMouse ? Appearance.m3colors.on_primary : Appearance.m3colors.on_surface
                            }
                        }
                    }
                }
                
                // Calendar logic
                QtObject {
                    id: calendar
                    
                    property int year: new Date().getFullYear()
                    property int month: new Date().getMonth()
                    property int today: new Date().getDate()
                    property int todayMonth: new Date().getMonth()
                    property int todayYear: new Date().getFullYear()
                    property string monthYear: ""
                    property var firstDay: new Date(year, month, 1)
                    property int firstDayOfWeek: firstDay.getDay()
                    property int daysInMonth: new Date(year, month + 1, 0).getDate()
                    property int daysInPrevMonth: new Date(year, month, 0).getDate()
                    
                    function updateMonthYear() {
                        const monthNames = ["January", "February", "March", "April", "May", "June",
                                          "July", "August", "September", "October", "November", "December"]
                        monthYear = monthNames[month] + " " + year
                        firstDay = new Date(year, month, 1)
                        firstDayOfWeek = firstDay.getDay()
                        daysInMonth = new Date(year, month + 1, 0).getDate()
                        daysInPrevMonth = new Date(year, month, 0).getDate()
                    }
                    
                    function getDayNumber(index) {
                        if (index < firstDayOfWeek) {
                            // Previous month days
                            return daysInPrevMonth - firstDayOfWeek + index + 1
                        } else if (index < firstDayOfWeek + daysInMonth) {
                            // Current month days
                            return index - firstDayOfWeek + 1
                        } else {
                            // Next month days
                            return index - firstDayOfWeek - daysInMonth + 1
                        }
                    }
                    
                    function isCurrentMonth(index) {
                        return index >= firstDayOfWeek && index < firstDayOfWeek + daysInMonth
                    }
                    
                    function isToday(index) {
                        const day = getDayNumber(index)
                        return isCurrentMonth(index) && day === today && month === todayMonth && year === todayYear
                    }
                    
                    function previousMonth() {
                        if (month === 0) {
                            month = 11
                            year--
                        } else {
                            month--
                        }
                        updateMonthYear()
                    }
                    
                    function nextMonth() {
                        if (month === 11) {
                            month = 0
                            year++
                        } else {
                            month++
                        }
                        updateMonthYear()
                    }
                    
                    function goToToday() {
                        const now = new Date()
                        year = now.getFullYear()
                        month = now.getMonth()
                        updateMonthYear()
                    }
                    
                    Component.onCompleted: updateMonthYear()
                }
            }
        }
    }
}