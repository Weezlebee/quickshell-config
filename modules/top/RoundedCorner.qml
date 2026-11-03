import QtQuick

Item {
    id: root

    property color color: "black"
    property real size: 12
    property int corner: 0 // 0: TopLeft, 1: TopRight, 2: BottomRight, 3: BottomLeft

    implicitWidth: size
    implicitHeight: size

    Canvas {
        anchors.fill: parent

        onPaint: {
            var ctx = getContext("2d");
            ctx.reset();
            ctx.fillStyle = root.color;

            var w = width;
            var h = height;

            ctx.beginPath();

            switch (root.corner) {
            case 0: // Top-Left Convex Fillet
                ctx.moveTo(0, h);
                ctx.lineTo(w, h);
                ctx.arcTo(0, h, 0, 0, root.size);
                ctx.lineTo(0, h);
                break;
            case 1: // Top-Right Convex Fillet
                ctx.moveTo(w, h);
                ctx.lineTo(0, h);
                ctx.arcTo(w, h, w, 0, root.size);
                ctx.lineTo(w, h);
                break;
            case 2: // Bottom-Right Convex Fillet
                ctx.moveTo(w, 0);
                ctx.lineTo(0, 0);
                ctx.arcTo(w, 0, w, h, root.size);
                ctx.lineTo(w, 0);
                break;
            case 3: // Bottom-Left Convex Fillet
                ctx.moveTo(0, 0);
                ctx.lineTo(w, 0);
                ctx.arcTo(0, 0, 0, h, root.size);
                ctx.lineTo(0, 0);
                break;
            }

            ctx.closePath();
            ctx.fill();
        }

        Connections {
            target: root
            function onColorChanged() { canvas.requestPaint(); }
            function onSizeChanged() { canvas.requestPaint(); }
            function onCornerChanged() { canvas.requestPaint(); }
        }
    }
}