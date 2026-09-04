const metrics = require('ti.ios.metrics');

const displayCornerRadius = metrics.getDisplayCornerRadius();

const win = Ti.UI.createWindow({
    backgroundColor: '#111',
    fullscreen: true
});

const preview = Ti.UI.createView({
    top: 16,
    bottom: 16,
    left: 16,
    right: 16,
    backgroundColor: '#fff',
    borderRadius: Math.max(displayCornerRadius - 16, 0)
});

const label = Ti.UI.createLabel({
    textAlign: Ti.UI.TEXT_ALIGNMENT_CENTER,
    color: '#111'
});

preview.add(label);
win.add(preview);

win.addEventListener('open', () => {
    const currentMetrics = metrics.getHeights();
    label.text = [
        `Display corner radius: ${currentMetrics.displayCornerRadius}`,
        `Known model: ${currentMetrics.displayCornerRadiusKnown}`,
        `Source: ${currentMetrics.displayCornerRadiusSource}`,
        `Curve: ${currentMetrics.displayCornerCurve}`
    ].join('\n');

    Ti.API.info(`Ti.iOS.Metrics: ${JSON.stringify(currentMetrics)}`);
});

win.open();
