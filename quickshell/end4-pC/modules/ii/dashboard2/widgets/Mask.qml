import QtQuick.Effects

// Thin MultiEffect wrapper used to clip an Image/Item to an arbitrary
// shape (e.g. an M3Shapes MaterialShape) via maskSource. Usage:
//
//   Image {
//       layer.enabled: true
//       layer.effect: Mask { maskSource: someShapeItem }
//   }
MultiEffect {
    maskEnabled: true
    maskSpreadAtMin: 1
    maskThresholdMin: 0.5
}



