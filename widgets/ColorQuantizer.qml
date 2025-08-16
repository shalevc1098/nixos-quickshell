// This is just a wrapper - ColorQuantizer is actually provided by Quickshell itself
// We re-export it here for consistency with our widget organization

import QtQuick
import Quickshell

// Re-export Quickshell's ColorQuantizer
ColorQuantizer {
    // ColorQuantizer properties:
    // - source: string (URL to image)
    // - colors: list<color> (extracted colors)
    // - depth: int (2^depth colors to extract, default 0 = 1 color)
    // - rescaleSize: int (scale image for faster processing)
}