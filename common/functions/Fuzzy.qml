pragma Singleton

import QtQuick
import "fuzzysort.js" as Fuzzysort

QtObject {
    function single(search, target) {
        return Fuzzysort.single(search, target)
    }
    
    function go(search, targets, options) {
        return Fuzzysort.go(search, targets, options)
    }
    
    function highlight(result, open='<b>', close='</b>') {
        return Fuzzysort.highlight(result, open, close)
    }
    
    function prepare(target) {
        return Fuzzysort.prepare(target)
    }
    
    function cleanup() {
        return Fuzzysort.cleanup()
    }
}