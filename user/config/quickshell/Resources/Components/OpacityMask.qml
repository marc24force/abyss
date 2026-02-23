// From: https://github.com/caelestia-dots/shell

import Quickshell
import QtQuick

ShaderEffect {
    required property Item source
    required property Item maskSource

    fragmentShader: Qt.resolvedUrl(`${Quickshell.shellDir}/Resources/Shaders/opacitymask.frag.qsb`)
}
