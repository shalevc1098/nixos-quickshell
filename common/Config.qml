pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell

Singleton {
    property int arbitraryRaceConditionDelay: 20
}