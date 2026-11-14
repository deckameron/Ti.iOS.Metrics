# Ti.iOS.Metrics API

## getDisplayCornerRadius()

Returns the display corner radius in points for a known iPhone or iPad model.

```javascript
const metrics = require('ti.ios.metrics');
const radius = metrics.getDisplayCornerRadius();
```

The method returns `0` for both known square displays and unknown models. Use the display-corner metadata returned by `getHeights()` when that distinction matters.

The lookup uses public device-identification APIs and does not access Apple's private `_displayCornerRadius` API.

## getHeights()

Returns the module's UI measurements and display-corner metadata.

```javascript
const values = require('ti.ios.metrics').getHeights();

values.displayCornerRadius;       // Number
values.displayCornerRadiusKnown;  // Boolean
values.displayCornerRadiusSource; // "modelLookup" or "unavailable"
values.displayCornerCurve;        // "continuous", "square", or "unknown"
```

The existing status-bar, navigation-bar, tab-bar, safe-area, screen, device-type, orientation, and iOS-version fields remain unchanged.

## Corner rendering

Titanium's `borderRadius` uses circular arcs. Rounded Apple displays use a continuous curve, so applying `displayCornerRadius` directly to a standard Titanium view is a numeric approximation. A future view-focused API can apply native concentric or continuous corners.
