# Ti.iOS.Metrics

A Titanium iOS module that provides accurate measurements of iOS UI elements including status bar, navigation bar, tab bar, and safe area insets. Supports all iPhone and iPad models, including devices with Dynamic Island, notch, the floating tab bar design, and the foldable iPhone Duo with its vertical bars, fold and camera regions.

![Titanium](https://img.shields.io/badge/Titanium-13.0+-red.svg) ![Platform](https://img.shields.io/badge/platform-iOS-lightgrey.svg) ![License](https://img.shields.io/badge/license-MIT-blue.svg) ![Maintained](https://img.shields.io/badge/Maintained-Yes-green.svg)

## Features

- Status bar, navigation bar and tab bar sizes (including Dynamic Island and notch)
- Bar position and edge detection (top, bottom, left, right), including the vertical bars of iPhone Duo
- Navigation bar detection within tab controllers
- Safe area insets (top, bottom, left, right)
- Screen and window dimensions
- Size classes (compact / regular)
- Reserved regions for the fold and camera areas of iPhone Duo (iOS 27.1+)
- iPhone Duo detection
- Display corner radius for known iPhone and iPad models
- Device type, orientation and iOS version detection

## Requirements

- Titanium SDK 13.0.0+
- iOS 13.0+
- Xcode 27.1 (iOS 27.1 SDK) to use reserved regions and the full iPhone Duo display. The module still builds with older Xcode versions; in that case `reservedRegionsSupported` is `false` and `reservedRegions` is empty.

## Installation

### 1. Copy the module to your Titanium project

```bash
# Copy the compiled module to:
{YOUR_PROJECT}/modules/iphone/
```

### 2. Add to tiapp.xml

```xml
<modules>
    <module platform="iphone">ti.ios.metrics</module>
</modules>
```

## API Documentation

### Methods

#### getDisplayCornerRadius()

Returns the physical display corner radius in points for known iPhone and iPad models. This method is synchronous and does not require an open window.

**Returns:** `Number`

- Returns the known radius for a supported model.
- Returns `0` for a known device with a square display.
- Returns `0` for an unknown model so it can be used safely as a Titanium `borderRadius` fallback. Check `displayCornerRadiusKnown` from `getHeights()` when the distinction matters.

This API uses a model lookup and does not access Apple's private `_displayCornerRadius` API.

```javascript
const metrics = require('ti.ios.metrics');

const radius = metrics.getDisplayCornerRadius();
const view = Ti.UI.createView({
    borderRadius: radius
});
```

#### getHeights()

Returns a dictionary containing all UI measurements. All values are in points.

**Returns:** `Object`

```javascript
{
    // Bar sizes. For horizontal bars this is the height,
    // for vertical bars (iPhone Duo) this is the width.
    statusBar: Number,
    navigationBar: Number,
    tabBar: Number,

    // Safe area insets
    safeAreaTop: Number,
    safeAreaBottom: Number,
    safeAreaLeft: Number,
    safeAreaRight: Number,

    // Physical screen size
    screenWidth: Number,
    screenHeight: Number,

    // Area actually available to the app (use these for layout)
    windowWidth: Number,
    windowHeight: Number,

    // Size classes: "compact", "regular" or "unspecified"
    horizontalSizeClass: String,
    verticalSizeClass: String,

    // Bar frames in window coordinates (see "Bar object" below)
    bars: {
        statusBar: Object,
        navigationBar: Object,
        tabBar: Object
    },

    // Fold and camera regions (see "Reserved region object" below)
    reservedRegionsSupported: Boolean,  // true on iOS 27.1+ when built with the iOS 27.1 SDK
    reservedRegions: Array,

    isLandscape: Boolean,        // true when the window is wider than it is tall
    isStatusBarHidden: Boolean,
    deviceType: String,          // "iPhone" or "iPad"
    iosVersion: Number,          // e.g. 27.1

    // Display corners (known iPhone and iPad models)
    displayCornerRadius: Number,       // Physical display radius in points
    displayCornerRadiusKnown: Boolean, // true when the model is in the lookup
    displayCornerRadiusSource: String, // "modelLookup" or "unavailable"
    displayCornerCurve: String         // "continuous", "square" or "unknown"
}
```

##### Bar object

Each entry in `bars` describes where a bar is drawn inside the window.

```javascript
{
    x: Number,
    y: Number,
    width: Number,
    height: Number,
    edge: String,       // "top", "bottom", "left", "right" or "none"
    thickness: Number   // height for top/bottom bars, width for left/right bars
}
```

When a bar is hidden, not laid out yet, or not present in the current window, `edge` is `"none"` and every number is `0`.

##### Reserved region object

Each entry in `reservedRegions` describes an area the app should keep its content away from.

```javascript
{
    kind: String,       // "occlusion" (camera) or "division" (fold)
    active: Boolean,    // whether the region affects the layout right now
    x: Number,
    y: Number,
    width: Number,
    height: Number,     // frame in window coordinates, margins included
    margins: {
        top: Number,
        left: Number,
        bottom: Number,
        right: Number
    }
}
```

Inactive regions are included so the app can reserve space ahead of time and avoid layout jumps. Filter by `active` when you only need what applies now.

#### isDuo()

Returns `true` when the app is running on an iPhone Duo, including the iPhone Duo simulator.

**Returns:** `Boolean`

Detection is based on the hardware model identifier. Prefer size classes, `bars` and `reservedRegions` for layout decisions, and use `isDuo()` for analytics or device-specific features.

#### debug()

Returns detailed information about the window and view controller hierarchy. Useful for troubleshooting.

**Returns:** `Object`

```javascript
{
    hasWindow: Boolean,
    windowFrame: String,
    windowBounds: String,
    screenBounds: String,
    safeAreaInsets: String,
    horizontalSizeClass: String,
    verticalSizeClass: String,
    statusBarFrameRaw: String,
    hasRootVC: Boolean,
    rootVCClass: String,               // e.g. "TiRootViewController"
    tabBarControllerClass: String,     // present when a tab bar controller is found
    tabBarHidden: Boolean,
    tabBarFrameInWindow: String,
    navigationControllerClass: String, // present when a navigation controller is found
    navBarHidden: Boolean,
    navBarFrameInWindow: String,
    reservedRegionsSupported: Boolean,
    reservedRegionsCount: Number
}
```

## iPhone Duo

iPhone Duo has a 5.4" outer display and a 7.6" inner display. How much of it your app uses depends on the SDK your app is built with:

| Built with | Inner display behavior |
| --- | --- |
| iOS 26 SDK or earlier | Phone-sized window on the inner display |
| iOS 27 SDK | Fills most of the inner display, avoiding the status bar on the right edge |
| iOS 27.1 SDK or later | Full display; tab bars and toolbars become vertical |

What this means for your layout:

- Bars are not always at the top and bottom. Read `bars.*.edge` before placing content next to a bar.
- Use `windowWidth` and `windowHeight` instead of `screenWidth` and `screenHeight`. The window changes size when the device opens and closes.
- The inner display reports `regular` for both size classes, like an iPad. Use them to switch between single-column and two-column layouts.
- Keep interactive content away from active `division` (fold) and `occlusion` (camera) regions.
- Opening or closing the device does not always change the orientation. Recalculate on the window `postlayout` event instead of `orientationchange`.

## Usage Examples

### Basic Usage

```javascript
const metrics = require('ti.ios.metrics');

function updateLayout() {
    const m = metrics.getHeights();

    console.log('Status Bar:', m.statusBar, m.bars.statusBar.edge);
    console.log('Navigation Bar:', m.navigationBar, m.bars.navigationBar.edge);
    console.log('Tab Bar:', m.tabBar, m.bars.tabBar.edge);
    console.log('Safe Area Top:', m.safeAreaTop);
    console.log('Safe Area Bottom:', m.safeAreaBottom);
    console.log('Window:', m.windowWidth + 'x' + m.windowHeight);
    console.log('Display Corner Radius:', m.displayCornerRadius);
}

updateLayout();
```

### Recalculate When the Layout Changes

`postlayout` fires after rotation, after opening or closing iPhone Duo, and after resizing. Remove the listener when the window closes.

```javascript
const metrics = require('ti.ios.metrics');

function onLayout() {
    const m = metrics.getHeights();
    applyLayout(m);
}

win.addEventListener('postlayout', onLayout);

win.addEventListener('close', () => {
    win.removeEventListener('postlayout', onLayout);
});
```

`postlayout` can fire several times in a row. If `applyLayout` changes view sizes, compare the new values with the previous ones before applying them to avoid layout loops.

### Calculate the Content Area

This works whether bars are horizontal or vertical.

```javascript
const metrics = require('ti.ios.metrics');

function getContentArea() {
    const m = metrics.getHeights();

    const insets = {
        top: m.safeAreaTop,
        bottom: m.safeAreaBottom,
        left: m.safeAreaLeft,
        right: m.safeAreaRight
    };

    // Add the space taken by each visible bar on its own edge
    [m.bars.navigationBar, m.bars.tabBar].forEach((bar) => {
        if (bar.edge !== 'none') {
            insets[bar.edge] = Math.max(insets[bar.edge], bar.thickness + (bar.edge === 'top' ? m.safeAreaTop : 0));
        }
    });

    return {
        top: insets.top,
        bottom: insets.bottom,
        left: insets.left,
        right: insets.right,
        width: m.windowWidth - insets.left - insets.right,
        height: m.windowHeight - insets.top - insets.bottom
    };
}

const area = getContentArea();
console.log('Available content area:', area.width + 'x' + area.height);
```

### Position a View Next to the Tab Bar

On most iPhones the tab bar sits at the bottom. On iPhone Duo built with the iOS 27.1 SDK it can be vertical.

```javascript
const metrics = require('ti.ios.metrics');

const m = metrics.getHeights();
const tab = m.bars.tabBar;
const spacing = 20;

const floatingButton = Ti.UI.createButton({
    title: 'Action',
    width: 200,
    height: 50
});

switch (tab.edge) {
    case 'bottom':
        floatingButton.bottom = (m.windowHeight - tab.y) + spacing;
        break;
    case 'left':
        floatingButton.left = tab.x + tab.width + spacing;
        floatingButton.bottom = m.safeAreaBottom + spacing;
        break;
    case 'right':
        floatingButton.right = (m.windowWidth - tab.x) + spacing;
        floatingButton.bottom = m.safeAreaBottom + spacing;
        break;
    default:
        floatingButton.bottom = m.safeAreaBottom + spacing;
}
```

### Adaptive Header Height

```javascript
const metrics = require('ti.ios.metrics');

function createHeader() {
    const m = metrics.getHeights();
    const nav = m.bars.navigationBar;

    // Only build a custom header when the navigation bar is at the top
    const barHeight = nav.edge === 'top' ? nav.thickness : 44;

    const header = Ti.UI.createView({
        top: 0,
        height: m.safeAreaTop + barHeight,
        backgroundColor: '#007AFF'
    });

    const title = Ti.UI.createLabel({
        text: 'My App',
        top: m.safeAreaTop,
        height: barHeight,
        textAlign: 'center',
        color: '#fff'
    });

    header.add(title);
    return header;
}
```

### One or Two Columns with Size Classes

```javascript
const metrics = require('ti.ios.metrics');

function buildLayout() {
    const m = metrics.getHeights();

    if (m.horizontalSizeClass === 'regular') {
        // iPad, or iPhone Duo inner display: list and detail side by side
        showListAndDetail();
    } else {
        // Regular iPhone, or iPhone Duo outer display
        showListOnly();
    }
}
```

### Avoid the Fold and the Camera (iPhone Duo)

```javascript
const metrics = require('ti.ios.metrics');

function arrangeAroundFold() {
    const m = metrics.getHeights();

    if (!m.reservedRegionsSupported) {
        return; // iOS < 27.1 or app built with an older SDK
    }

    const fold = m.reservedRegions.find(r => r.kind === 'division' && r.active);

    if (fold) {
        const verticalFold = fold.height > fold.width;

        if (verticalFold) {
            // Fold runs top to bottom: place content on the left and right sides
            leftPane.width = fold.x;
            rightPane.left = fold.x + fold.width;
        } else {
            // Fold runs left to right: place content above and below
            topPane.height = fold.y;
            bottomPane.top = fold.y + fold.height;
        }
    }

    const cameras = m.reservedRegions.filter(r => r.kind === 'occlusion' && r.active);
    cameras.forEach((camera) => {
        console.log('Keep buttons away from', camera.x, camera.y, camera.width, camera.height);
    });
}
```

### Detect iPhone Duo

```javascript
const metrics = require('ti.ios.metrics');

if (metrics.isDuo()) {
    Ti.Analytics.featureEvent('device.iphone_duo');
}
```

### Check Device Capabilities

```javascript
const metrics = require('ti.ios.metrics');

const m = metrics.getHeights();

// Check if device has notch/Dynamic Island (portrait, status bar at the top)
const hasNotch = m.bars.statusBar.edge === 'top' && m.safeAreaTop > 20;

// Check if device has home indicator
const hasHomeIndicator = m.safeAreaBottom > 0;

if (hasNotch) {
    console.log('Device has notch or Dynamic Island');
}

if (hasHomeIndicator) {
    console.log('Device has home indicator (no home button)');
}
```

### Full Screen Content with Safe Areas

```javascript
const metrics = require('ti.ios.metrics');

const m = metrics.getHeights();
const nav = m.bars.navigationBar;
const tab = m.bars.tabBar;

const contentView = Ti.UI.createScrollView({
    contentHeight: 'auto',
    top: m.safeAreaTop + (nav.edge === 'top' ? nav.thickness : 0),
    bottom: Math.max(m.safeAreaBottom, tab.edge === 'bottom' ? tab.thickness : 0),
    left: Math.max(m.safeAreaLeft, tab.edge === 'left' ? tab.thickness : 0),
    right: Math.max(m.safeAreaRight, tab.edge === 'right' ? tab.thickness : 0)
});
```

### Match a View to the Display Corners

```javascript
const metrics = require('ti.ios.metrics');
const m = metrics.getHeights();

const backgroundView = Ti.UI.createView({
    width: Ti.UI.FILL,
    height: Ti.UI.FILL,
    backgroundColor: '#fff',
    borderRadius: m.displayCornerRadiusKnown ? m.displayCornerRadius : 0
});
```

The returned value is expressed in Apple points, which are equivalent to Titanium density-independent pixels on iOS. It is best suited to a view that follows the display edges. For an evenly inset view, a concentric circular approximation is `Math.max(m.displayCornerRadius - inset, 0)`.

Modern iPhone and iPad displays use a continuous corner curve, while Titanium's `borderRadius` is currently documented as a circular arc. The numeric radius is therefore an approximation when applied directly to a standard Titanium view. Native iOS 26 concentric-corner support is planned as a separate view-focused API.

### Unknown Devices

New Apple hardware may not be present in the bundled model lookup. In that case:

- `displayCornerRadius` and `getDisplayCornerRadius()` return `0`.
- `displayCornerRadiusKnown` is `false`.
- `displayCornerRadiusSource` is `"unavailable"`.
- `displayCornerCurve` is `"unknown"`.

The lookup can be updated without changing the JavaScript API.

## Display Geometry Data

The model lookup is adapted from BezelKit's simulator-derived device database. See the [third-party notices](ios/documentation/third-party-notices.md) for attribution and license information.

## Migrating from Previous Versions

Existing fields keep their names, and on non-foldable devices they return the same values as before. Points to review:

- `statusBar`, `navigationBar` and `tabBar` now return the bar thickness. For horizontal bars this is the same as the height. For vertical bars on iPhone Duo it is the width.
- Fixed fallback values were removed. If a bar is not laid out yet, the module returns `0` instead of a default height (44 for navigation bars, 49 for tab bars).
- `isLandscape` is now based on the window proportions instead of the interface orientation.
- Code that subtracts `tabBar` from `screenHeight` assumes a bottom tab bar. Use `bars.tabBar.edge` and `windowHeight` instead.
- `debug()` keys changed: `tabBarFrame` and `navBarFrame` are now `tabBarFrameInWindow` and `navBarFrameInWindow`, and the hierarchy is searched recursively.

## Troubleshooting

### A bar returns 0 or edge "none"

Call `getHeights()` after the UI is fully laid out. The `postlayout` event is the most reliable place:

```javascript
const metrics = require('ti.ios.metrics');

win.addEventListener('postlayout', function onFirstLayout() {
    win.removeEventListener('postlayout', onFirstLayout);
    console.log(metrics.getHeights());
});
```

### reservedRegions is always empty

- `reservedRegionsSupported` is `false`: the app was built with an SDK older than iOS 27.1, or it is running on iOS older than 27.1.
- `reservedRegionsSupported` is `true` but the list is empty: the device has no fold or camera over the window. On iPhone Duo, check that the app is built with Xcode 27.1.

### isDuo() returns false on a new foldable

Detection uses a list of hardware model identifiers. New iPhone Duo models need a module update. Open an issue with the model name.

### Using the debug() method

```javascript
const metrics = require('ti.ios.metrics');
const debugInfo = metrics.debug();
console.log(JSON.stringify(debugInfo, null, 2));
```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request
