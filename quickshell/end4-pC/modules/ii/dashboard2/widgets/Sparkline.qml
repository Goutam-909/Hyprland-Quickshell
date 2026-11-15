import QtQuick

Canvas {
    id: root

    clip: true
    property list<real> line1: []
    property color line1Color: "white"
    property real line1FillAlpha: 0.15

    property list<real> line2: []
    property color line2Color: "white"
    property real line2FillAlpha: 0.2

    property real maxValue: 1024
    property int historyLength: 60

    // How often new samples land (ms). The line continuously eases
    // itself one step to the left over this duration, so it flows in
    // real time instead of snapping into place once per sample.
    property int sampleInterval: 1000

    // 0 right after a new sample lands, animates back to 1 over
    // sampleInterval - drives the continuous scroll.
    property real slideProgress: 1

    onLine1Changed: {
        slideAnim.stop();
        root.slideProgress = 0;
        slideAnim.start();
    }
    onSlideProgressChanged: requestPaint()
    onMaxValueChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()

    NumberAnimation {
        id: slideAnim
        target: root
        property: "slideProgress"
        from: 0
        to: 1
        duration: root.sampleInterval
        easing.type: Easing.Linear
    }

    function _points(values) {
        const n = root.historyLength;
        const stepX = width / Math.max(1, n - 1);
        const offset = n - values.length;
        // Continuous conveyor-belt shift: right when a new sample lands,
        // every carried-over point must render at exactly the same pixel
        // it was already sitting at (continuity - no snap), then ease
        // over to its new resting position (one column left) by the time
        // the *next* sample lands. That means points start shifted one
        // full step to the *right* of their settled position and ease
        // down to zero - i.e. shift is added, not subtracted.
        const shift = stepX * (1 - root.slideProgress);

        const pts = [];
        for (let i = 0; i < values.length; i++) {
            pts.push([(offset + i) * stepX + shift, height - Math.min(1, values[i] / root.maxValue) * height]);
        }
        return pts;
    }

    function _drawLine(ctx, values, colour, fillAlpha) {
        const pts = _points(values);
        if (pts.length < 2)
            return;

        ctx.beginPath();
        ctx.moveTo(pts[0][0], pts[0][1]);

        // Smooth the line through quadratic curves between midpoints
        // instead of straight zig-zag segments - much closer to how a
        // live monitoring graph actually reads.
        for (let i = 1; i < pts.length - 1; i++) {
            const [x0, y0] = pts[i];
            const [x1, y1] = pts[i + 1];
            const mx = (x0 + x1) / 2;
            const my = (y0 + y1) / 2;
            ctx.quadraticCurveTo(x0, y0, mx, my);
        }
        const last = pts[pts.length - 1];
        ctx.lineTo(last[0], last[1]);

        ctx.strokeStyle = colour;
        ctx.lineWidth = 2;
        ctx.lineJoin = "round";
        ctx.lineCap = "round";
        ctx.stroke();

        ctx.lineTo(last[0], height);
        ctx.lineTo(pts[0][0], height);
        ctx.closePath();
        ctx.fillStyle = Qt.alpha(colour, fillAlpha);
        ctx.fill();
    }

    onPaint: {
        const ctx = getContext("2d");
        ctx.reset();
        _drawLine(ctx, line2, line2Color, line2FillAlpha);
        _drawLine(ctx, line1, line1Color, line1FillAlpha);
    }
}



