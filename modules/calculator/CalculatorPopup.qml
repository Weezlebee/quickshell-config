pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../theme"

// Lives in modules/calculator/CalculatorPopup.qml — a sibling folder
// to modules/theme/, so "../theme" resolves correctly from here.

Item {
    id: calcRoot
    anchors.fill: parent

    signal requestClose()

    property string activeSection: "algebra" // "algebra" | "graphing"

    readonly property var sections: [
        { key: "algebra",  name: "Algebra",  desc: "Expressions & equations" },
        { key: "graphing", name: "Graphing", desc: "Plot functions" }
    ]

    Rectangle {
        anchors.fill: parent
        color: Theme.bg0
        radius: 16

        Behavior on color { ColorAnimation { duration: 200 } }

        RowLayout {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 20

            // ---------------- SIDEBAR ----------------
            ColumnLayout {
                Layout.preferredWidth: 220
                Layout.fillHeight: true
                spacing: 4

                Text {
                    text: "Calculator"
                    color: Theme.text
                    font.pixelSize: 20
                    font.bold: true
                    Layout.bottomMargin: 10
                }

                Repeater {
                    model: calcRoot.sections
                    delegate: Rectangle {
                        id: navItem
                        required property var modelData
                        Layout.fillWidth: true
                        height: 56
                        radius: 10
                        color: calcRoot.activeSection === modelData.key
                            ? Theme.bg1
                            : (navMouse.containsMouse ? Theme.hover : "transparent")

                        Behavior on color { ColorAnimation { duration: 120 } }

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 14
                            anchors.rightMargin: 14
                            spacing: 0
                            Text {
                                text: navItem.modelData.name
                                color: Theme.text
                                font.pixelSize: 15
                                font.bold: true
                            }
                            Text {
                                text: navItem.modelData.desc
                                color: Theme.subText
                                font.pixelSize: 11
                            }
                        }

                        MouseArea {
                            id: navMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: calcRoot.activeSection = navItem.modelData.key
                        }
                    }
                }

                Item { Layout.fillHeight: true }
            }

            // ---------------- MAIN CONTENT ----------------
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 16

                RowLayout {
                    Layout.fillWidth: true

                    Text {
                        text: calcRoot.activeSection === "algebra" ? "Algebra" : "Graphing"
                        color: Theme.text
                        font.pixelSize: 28
                        font.bold: true
                        Layout.fillWidth: true
                    }

                    Rectangle {
                        width: 36; height: 36
                        radius: 18
                        color: closeMouse.containsMouse ? Theme.hover : "transparent"

                        Text {
                            anchors.centerIn: parent
                            text: "\u2715"
                            color: Theme.text
                            font.pixelSize: 16
                        }

                        MouseArea {
                            id: closeMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: calcRoot.requestClose()
                        }
                    }
                }

                Loader {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    sourceComponent: calcRoot.activeSection === "algebra" ? algebraPage : graphingPage
                }
            }
        }
    }

    // ================= ALGEBRA PAGE =================
    Component {
        id: algebraPage

        ColumnLayout {
            id: algebraPageRoot
            spacing: 12

            readonly property var examples: [
                "2x + 5 = 15", "x^2 - 9 = 0", "abs(x - 3) < 5",
                "sqrt(144)", "log(1000)", "ln(e^2)", "2^x = 16"
            ]

            function insertAtCursor(str) {
                let pos = exprField.cursorPosition;
                exprField.text = exprField.text.slice(0, pos) + str + exprField.text.slice(pos);
                exprField.cursorPosition = pos + str.length;
                exprField.forceActiveFocus();
                evalTimer.restart();
            }

            // Detects a single top-level "a/b" in the result and splits
            // it into { num, den } for stacked rendering. Returns null
            // for anything more complex (multiple divisions, no slash, etc.)
            // so those just fall back to plain text.
            function parseFraction(str) {
                if (!str) return null;
                let s = str.trim();
                let depth = 0;
                let slashIndex = -1;
                for (let i = 0; i < s.length; i++) {
                    const c = s[i];
                    if (c === "(") depth++;
                    else if (c === ")") depth--;
                    else if (c === "/" && depth === 0) {
                        if (slashIndex !== -1) return null;
                        slashIndex = i;
                    }
                }
                if (slashIndex === -1) return null;

                let num = s.slice(0, slashIndex).trim();
                let den = s.slice(slashIndex + 1).trim();
                if (num === "" || den === "") return null;

                function stripParens(t) {
                    if (t.length > 1 && t[0] === "(" && t[t.length - 1] === ")") {
                        let d = 0;
                        for (let i = 0; i < t.length; i++) {
                            if (t[i] === "(") d++;
                            else if (t[i] === ")") d--;
                            if (d === 0 && i < t.length - 1) return t;
                        }
                        return t.slice(1, -1);
                    }
                    return t;
                }

                return { num: stripParens(num), den: stripParens(den) };
            }

            Rectangle {
                Layout.fillWidth: true
                height: 56
                radius: 12
                color: Theme.bg1

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 12

                    TextField {
                        id: exprField
                        Layout.fillWidth: true
                        placeholderText: "e.g. 2x + 5 = 15,  abs(x - 3) < 5,  sqrt(144),  log(1000)"
                        placeholderTextColor: Theme.placeholder
                        color: Theme.text
                        font.pixelSize: 16
                        background: Rectangle { color: "transparent" }
                        focus: true

                        onTextChanged: evalTimer.restart()
                        Keys.onReturnPressed: evaluateNow()

                        function evaluateNow() {
                            if (text.trim() === "") {
                                qalcProcess.output = "";
                                return;
                            }
                            qalcProcess.command = ["qalc", "-t", text];
                            qalcProcess.running = true;
                        }
                    }
                }
            }

            // ---------------- QUICK-INSERT ROW ----------------
            Flow {
                Layout.fillWidth: true
                spacing: 6

                readonly property var chips: [
                    { label: "|x|",  insert: "abs()" },
                    { label: "\u221ax", insert: "sqrt()" },
                    { label: "x\u00b2", insert: "^2" },
                    { label: "x^y", insert: "^" },
                    { label: "log",  insert: "log()" },
                    { label: "ln",   insert: "ln()" },
                    { label: "\u2264", insert: "<=" },
                    { label: "\u2265", insert: ">=" },
                    { label: "\u2260", insert: "!=" },
                    { label: "\u03c0", insert: "pi" },
                    { label: "\u221e", insert: "infinity" }
                ]

                Repeater {
                    model: parent.chips
                    delegate: Rectangle {
                        id: chip
                        required property var modelData
                        width: chipText.implicitWidth + 20
                        height: 32
                        radius: 8
                        color: chipMouse.containsMouse ? Theme.hover : Theme.bg1

                        Behavior on color { ColorAnimation { duration: 100 } }

                        Text {
                            id: chipText
                            anchors.centerIn: parent
                            text: chip.modelData.label
                            color: Theme.text
                            font.pixelSize: 14
                        }

                        MouseArea {
                            id: chipMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: algebraPageRoot.insertAtCursor(chip.modelData.insert)
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: 12
                color: Theme.bg1

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 20
                    spacing: 8

                    Text {
                        text: "Result"
                        color: Theme.subText
                        font.pixelSize: 12
                    }

                    Item {
                        id: resultWrapper
                        Layout.fillWidth: true
                        property var frac: algebraPageRoot.parseFraction(qalcProcess.output)
                        implicitHeight: resultWrapper.frac ? fractionDisplay.implicitHeight : plainResultText.implicitHeight

                        Text {
                            id: plainResultText
                            visible: !resultWrapper.frac
                            text: qalcProcess.output !== "" ? qalcProcess.output : "..."
                            color: Theme.highlight
                            font.pixelSize: 28
                            font.bold: true
                            wrapMode: Text.WordWrap
                            width: parent.width
                        }

                        Item {
                            id: fractionDisplay
                            visible: !!resultWrapper.frac
                            implicitWidth: Math.max(numLabel.implicitWidth, denLabel.implicitWidth)
                            implicitHeight: numLabel.implicitHeight + lineRect.height + denLabel.implicitHeight + 6

                            Text {
                                id: numLabel
                                text: resultWrapper.frac ? resultWrapper.frac.num : ""
                                color: Theme.highlight
                                font.pixelSize: 22
                                font.bold: true
                                anchors.top: parent.top
                                anchors.horizontalCenter: parent.horizontalCenter
                            }

                            Rectangle {
                                id: lineRect
                                height: 2
                                color: Theme.highlight
                                width: fractionDisplay.implicitWidth
                                anchors.top: numLabel.bottom
                                anchors.topMargin: 3
                                anchors.horizontalCenter: parent.horizontalCenter
                            }

                            Text {
                                id: denLabel
                                text: resultWrapper.frac ? resultWrapper.frac.den : ""
                                color: Theme.highlight
                                font.pixelSize: 22
                                font.bold: true
                                anchors.top: lineRect.bottom
                                anchors.topMargin: 3
                                anchors.horizontalCenter: parent.horizontalCenter
                            }
                        }
                    }

                    Item { Layout.fillHeight: true }

                    Text {
                        text: "Try: " + algebraPageRoot.examples.join("   \u00b7   ")
                        color: Theme.subText
                        font.pixelSize: 11
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                    }
                }
            }

            Timer {
                id: evalTimer
                interval: 250
                onTriggered: exprField.evaluateNow()
            }

            Process {
                id: qalcProcess
                property string output: ""
                stdout: SplitParser {
                    onRead: data => qalcProcess.output = data.trim()
                }
            }
        }
    }

    // ================= GRAPHING PAGE =================
    Component {
        id: graphingPage

        ColumnLayout {
            spacing: 16

            Rectangle {
                Layout.fillWidth: true
                height: 56
                radius: 12
                color: Theme.bg1

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 10

                    Text {
                        text: "f(x) ="
                        color: Theme.subText
                        font.pixelSize: 16
                    }

                    TextField {
                        id: fnField
                        Layout.fillWidth: true
                        text: "sin(x)"
                        color: Theme.text
                        placeholderTextColor: Theme.placeholder
                        font.pixelSize: 16
                        background: Rectangle { color: "transparent" }
                        onTextChanged: plotCanvas.requestPaint()
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: 12
                color: Theme.bg1
                clip: true

                Canvas {
                    id: plotCanvas
                    anchors.fill: parent
                    anchors.margins: 16

                    property real xMin: -10
                    property real xMax: 10
                    property real yMin: -10
                    property real yMax: 10

                    function safeEval(expr, x) {
                        try {
                            let e = expr
                                .replace(/\^/g, "**")
                                .replace(/\bpi\b/g, "Math.PI")
                                .replace(/\bsin\(/g, "Math.sin(")
                                .replace(/\bcos\(/g, "Math.cos(")
                                .replace(/\btan\(/g, "Math.tan(")
                                .replace(/\bsqrt\(/g, "Math.sqrt(")
                                .replace(/\blog\(/g, "Math.log10(")
                                .replace(/\bln\(/g, "Math.log(")
                                .replace(/\babs\(/g, "Math.abs(");
                            const f = new Function("x", "return " + e + ";");
                            return f(x);
                        } catch (err) {
                            return NaN;
                        }
                    }

                    onPaint: {
                        const ctx = getContext("2d");
                        ctx.clearRect(0, 0, width, height);
                        ctx.fillStyle = Theme.bg1;
                        ctx.fillRect(0, 0, width, height);

                        function toPx(x) { return (x - xMin) / (xMax - xMin) * width; }
                        function toPy(y) { return height - (y - yMin) / (yMax - yMin) * height; }

                        // grid
                        ctx.strokeStyle = Theme.hover;
                        ctx.lineWidth = 1;
                        for (let gx = Math.ceil(xMin); gx <= xMax; gx++) {
                            ctx.beginPath();
                            ctx.moveTo(toPx(gx), 0);
                            ctx.lineTo(toPx(gx), height);
                            ctx.stroke();
                        }
                        for (let gy = Math.ceil(yMin); gy <= yMax; gy++) {
                            ctx.beginPath();
                            ctx.moveTo(0, toPy(gy));
                            ctx.lineTo(width, toPy(gy));
                            ctx.stroke();
                        }

                        // axes
                        ctx.strokeStyle = Theme.subText;
                        ctx.lineWidth = 2;
                        ctx.beginPath();
                        ctx.moveTo(0, toPy(0)); ctx.lineTo(width, toPy(0));
                        ctx.moveTo(toPx(0), 0); ctx.lineTo(toPx(0), height);
                        ctx.stroke();

                        // curve
                        ctx.strokeStyle = Theme.highlight;
                        ctx.lineWidth = 2.5;
                        ctx.beginPath();
                        let started = false;
                        const steps = width;
                        for (let i = 0; i <= steps; i++) {
                            const x = xMin + (xMax - xMin) * (i / steps);
                            const y = safeEval(fnField.text, x);
                            if (isNaN(y) || !isFinite(y)) { started = false; continue; }
                            const px = toPx(x);
                            const py = toPy(y);
                            if (!started) { ctx.moveTo(px, py); started = true; }
                            else ctx.lineTo(px, py);
                        }
                        ctx.stroke();
                    }

                    Component.onCompleted: requestPaint()
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Button {
                    text: "Zoom In"
                    onClicked: {
                        plotCanvas.xMin *= 0.7; plotCanvas.xMax *= 0.7;
                        plotCanvas.yMin *= 0.7; plotCanvas.yMax *= 0.7;
                        plotCanvas.requestPaint();
                    }
                }
                Button {
                    text: "Zoom Out"
                    onClicked: {
                        plotCanvas.xMin *= 1.4; plotCanvas.xMax *= 1.4;
                        plotCanvas.yMin *= 1.4; plotCanvas.yMax *= 1.4;
                        plotCanvas.requestPaint();
                    }
                }
                Button {
                    text: "Reset"
                    onClicked: {
                        plotCanvas.xMin = -10; plotCanvas.xMax = 10;
                        plotCanvas.yMin = -10; plotCanvas.yMax = 10;
                        plotCanvas.requestPaint();
                    }
                }
                Item { Layout.fillWidth: true }
                Text {
                    text: "Try: sin(x), x^2, sqrt(x), log(x)"
                    color: Theme.subText
                    font.pixelSize: 11
                }
            }
        }
    }
}
