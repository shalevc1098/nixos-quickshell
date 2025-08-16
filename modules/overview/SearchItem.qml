import qs.common
import qs.services
import qs.widgets
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Hyprland

Rectangle {
    id: root
    property var entry
    property string query
    property bool entryShown: entry?.shown ?? true
    property string itemType: entry?.type ?? "App"
    property string itemName: entry?.name
    property string itemIcon: entry?.icon ?? ""
    property var itemExecute: entry?.execute
    property string fontType: entry?.fontType ?? "main"
    property string itemClickActionName: entry?.clickActionName
    property string bigText: entry?.bigText ?? ""
    property string iconText: entry?.iconText ?? ""
    property string cliphistRawString: entry?.cliphistRawString ?? ""
    
    visible: root.entryShown
    property int horizontalMargin: 10
    property int buttonHorizontalPadding: 10
    property int buttonVerticalPadding: 5
    property bool keyboardDown: false
    property bool hovered: mouseArea.containsMouse
    property bool down: mouseArea.pressed
    property bool isFocused: false
    
    signal clicked()

    implicitHeight: rowLayout.implicitHeight + root.buttonVerticalPadding * 2
    implicitWidth: rowLayout.implicitWidth + root.buttonHorizontalPadding * 2
    radius: 8
    color: (root.down || root.keyboardDown) ? ColorUtils.transparentize(Appearance.m3colors.secondary_container, 0.7) : 
        ((root.hovered || root.isFocused) ? ColorUtils.transparentize(Appearance.m3colors.secondary_container, 0.85) : 
        "transparent")

    property string highlightPrefix: `<u><font color="${Appearance.m3colors.primary}">`
    property string highlightSuffix: `</font></u>`
    
    function escapeHtml(text) {
        return text
            .replace(/&/g, "&amp;")
            .replace(/</g, "&lt;")
            .replace(/>/g, "&gt;")
            .replace(/"/g, "&quot;")
            .replace(/'/g, "&#39;");
    }
    
    function highlightContent(content, query) {
        if (!query || query.length === 0 || content == query || fontType === "monospace")
            return escapeHtml(content);

        let contentLower = content.toLowerCase();
        let queryLower = query.toLowerCase();

        let result = "";
        let lastIndex = 0;
        let qIndex = 0;

        for (let i = 0; i < content.length && qIndex < query.length; i++) {
            if (contentLower[i] === queryLower[qIndex]) {
                // Add non-highlighted part (escaped)
                if (i > lastIndex)
                    result += escapeHtml(content.slice(lastIndex, i));
                // Add highlighted character (escaped)
                result += root.highlightPrefix + escapeHtml(content[i]) + root.highlightSuffix;
                lastIndex = i + 1;
                qIndex++;
            }
        }
        // Add the rest of the string (escaped)
        if (lastIndex < content.length)
            result += escapeHtml(content.slice(lastIndex));

        return result;
    }
    property string displayContent: highlightContent(root.itemName, root.query)

    property list<string> urls: {
        if (!root.itemName) return [];
        // Regular expression to match URLs
        const urlRegex = /https?:\/\/[^\s<>"{}|\\^`[\]]+/gi;
        const matches = root.itemName?.match(urlRegex)
            ?.filter(url => !url.includes("…")) // Elided = invalid
        return matches ? matches : [];
    }
    
    MouseArea {
        id: mouseArea
        anchors.fill: parent
        anchors.leftMargin: root.horizontalMargin
        anchors.rightMargin: root.horizontalMargin
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        
        onClicked: {
            root.clicked()
        }
    }

    onClicked: {
        root.itemExecute()
        GlobalStates.overviewOpen = false
    }
    Keys.onPressed: (event) => {
        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            root.keyboardDown = true
            root.clicked()
            event.accepted = true;
        }
    }
    Keys.onReleased: (event) => {
        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            root.keyboardDown = false
            event.accepted = true;
        }
    }

    RowLayout {
        id: rowLayout
        spacing: iconLoader.sourceComponent === null ? 0 : 10
        anchors.fill: parent
        anchors.leftMargin: root.horizontalMargin + root.buttonHorizontalPadding
        anchors.rightMargin: root.horizontalMargin + root.buttonHorizontalPadding

        // Icon
        Loader {
            id: iconLoader
            active: true
            sourceComponent: root.iconText !== "" ? iconTextComponent :
                root.bigText ? bigTextComponent :
                root.itemIcon !== "" ? iconImageComponent : 
                null
        }

        Component {
            id: iconImageComponent
            IconImage {
                source: Quickshell.iconPath(root.itemIcon, "image-missing")
                width: 35
                height: 35
            }
        }

        Component {
            id: iconTextComponent
            Text {
                text: root.iconText
                font.family: "JetBrainsMono Nerd Font Propo"
                font.pixelSize: 24
                color: Appearance.m3colors.on_surface
            }
        }

        Component {
            id: bigTextComponent
            Text {
                text: root.bigText
                font.pixelSize: 18
                font.family: "SF Pro Display"
                color: Appearance.m3colors.on_surface
            }
        }

        // Main text
        ColumnLayout {
            id: contentColumn
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 0
            Text {
                font.pixelSize: 11
                font.family: "SF Pro Display"
                color: Appearance.m3colors.on_surface_variant
                visible: root.itemType && root.itemType != "App"
                text: root.itemType
            }
            RowLayout {
                Loader { // Checkmark for copied clipboard entry
                    visible: itemName == Quickshell.clipboardText && root.cliphistRawString
                    active: itemName == Quickshell.clipboardText && root.cliphistRawString
                    sourceComponent: Rectangle {
                        implicitWidth: activeText.implicitHeight
                        implicitHeight: activeText.implicitHeight
                        radius: height / 2
                        color: Appearance.m3colors.primary
                        Text {
                            id: activeText
                            anchors.centerIn: parent
                            text: "✓"
                            font.pixelSize: 12
                            font.family: "SF Pro Display"
                            color: Appearance.m3colors.on_primary
                        }
                    }
                }
                Repeater { // Favicons for links
                    model: root.query == root.itemName ? [] : root.urls
                    delegate: Item {
                        required property var modelData
                        width: 16
                        height: 16
                        // Favicon placeholder - would need actual implementation
                    }
                }
                Text { // Item name/content
                    Layout.fillWidth: true
                    id: nameText
                    textFormat: Text.StyledText // RichText also works, but StyledText ensures elide work
                    font.pixelSize: 14
                    font.family: root.fontType === "monospace" ? "JetBrainsMono Nerd Font Propo" : "SF Pro Display"
                    color: Appearance.m3colors.on_surface
                    horizontalAlignment: Text.AlignLeft
                    elide: Text.ElideRight
                    text: `${root.displayContent}`
                }
            }
            Loader { // Clipboard image preview
                active: root.cliphistRawString && /^\d+\t\[\[.*binary data.*\d+x\d+.*\]\]$/.test(root.cliphistRawString)
                sourceComponent: Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 140
                    color: Appearance.m3colors.surface_container
                    radius: 4
                    Text {
                        anchors.centerIn: parent
                        text: "[Image]"
                        font.pixelSize: 12
                        font.family: "SF Pro Display"
                        color: Appearance.m3colors.on_surface_variant
                    }
                }
            }
        }

        // Action text
        Text {
            Layout.fillWidth: false
            visible: (root.hovered || root.isFocused)
            id: clickAction
            font.pixelSize: 14
            font.family: "SF Pro Display"
            color: Appearance.m3colors.on_surface_variant
            horizontalAlignment: Text.AlignRight
            text: root.itemClickActionName
        }

        RowLayout {
            spacing: 4
            Repeater {
                model: (root.entry.actions ?? []).slice(0, 4)
                delegate: Rectangle {
                    id: actionButton
                    required property var modelData
                    implicitHeight: 34
                    implicitWidth: 34
                    radius: 4
                    color: actionMouseArea.containsMouse ? ColorUtils.transparentize(Appearance.m3colors.secondary_container, 0.9) : "transparent"
                    
                    MouseArea {
                        id: actionMouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: actionButton.modelData.execute()
                    }

                    Loader {
                        anchors.centerIn: parent
                        active: !(actionButton.modelData.icon && actionButton.modelData.icon !== "")
                        sourceComponent: Text {
                            text: "󰅖"
                            font.family: "JetBrainsMono Nerd Font Propo"
                            font.pixelSize: 16
                            color: Appearance.m3colors.on_surface
                        }
                    }
                    Loader {
                        anchors.centerIn: parent
                        active: actionButton.modelData.icon && actionButton.modelData.icon !== ""
                        sourceComponent: IconImage {
                            source: Quickshell.iconPath(actionButton.modelData.icon)
                            implicitSize: 20
                        }
                    }

                    StyledTooltip {
                        visible: actionMouseArea.containsMouse
                        text: actionButton.modelData.name
                    }
                }
            }
        }

    }
}