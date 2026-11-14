# Ti.iOS.Metrics API

Measurements of iOS UI elements: bars, safe area, window and screen size, size classes, fold and camera regions (iPhone Duo) and display corner radius. All values are in points.

```javascript
const metrics = require('ti.ios.metrics');
```

## getHeights()

Returns the module's UI measurements as a dictionary.

```javascript
const values = require('ti.ios.metrics').getHeights();
```

| Key | Type | Description |
| --- | --- | --- |
| `statusBar`, `navigationBar`, `tabBar` | Number | Bar thickness: the height of horizontal bars, the width of vertical bars (iPhone Duo). `0` when a bar is hidden or not laid out yet. |
| `safeAreaTop`, `safeAreaBottom`, `safeAreaLeft`, `safeAreaRight` | Number | Safe area insets. |
| `screenWidth`, `screenHeight` | Number | Physical screen size. |
| `windowWidth`, `windowHeight` | Number | Area the app actually gets. Use these for layout. |
| `horizontalSizeClass`, `verticalSizeClass` | String | `"compact"`, `"regular"` or `"unspecified"`. |
| `bars` | Object | Frame, edge and thickness of each bar (see Bar object). |
| `reservedRegionsSupported` | Boolean | `true` on iOS 27.1+ when the app is built with the iOS 27.1 SDK. |
| `reservedRegions` | Array | Fold and camera regions (see Reserved region object). |
| `isLandscape` | Boolean | `true` when the window is wider than it is tall. |
| `isStatusBarHidden` | Boolean | `true` when the status bar is hidden. |
| `deviceType` | String | `"iPhone"` or `"iPad"`. |
| `iosVersion` | Number | For example `27.1`. |
| `displayCornerRadius` | Number | Physical display corner radius. |
| `displayCornerRadiusKnown` | Boolean | `true` when the model is in the lookup. |
| `displayCornerRadiusSource` | String | `"modelLookup"` or `"unavailable"`. |
| `displayCornerCurve` | String | `"continuous"`, `"square"` or `"unknown"`. |

Call `getHeights()` after the UI is laid out, for example in the window `postlayout` event. Before that, bars report `0` and edge `"none"`.

### Bar object

Each entry in `bars` (`statusBar`, `navigationBar`, `tabBar`) describes where a bar is drawn in window coordinates.

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

When a bar is hidden, not laid out yet, or not present, `edge` is `"none"` and every number is `0`.

### Reserved region object

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

Inactive regions are included so the app can reserve space ahead of time. Filter by `active` when you only need what applies now.

## getDisplayCornerRadius()

Returns the display corner radius in points for a known iPhone or iPad model. It is synchronous and works before a window opens.

```javascript
const radius = require('ti.ios.metrics').getDisplayCornerRadius();
```

The method returns `0` for both known square displays and unknown models. Use `displayCornerRadiusKnown` from `getHeights()` when that distinction matters.

The lookup uses public device-identification APIs and does not access Apple's private `_displayCornerRadius` API.

## isDuo()

Returns `true` when the app is running on an iPhone Duo, including the iPhone Duo simulator.

Detection is based on the hardware model identifier. Prefer size classes, `bars` and `reservedRegions` for layout decisions, and use `isDuo()` for analytics or device-specific features.

## debug()

Returns detailed information about the window and view controller hierarchy, for troubleshooting. Keys include `hasWindow`, `windowFrame`, `windowBounds`, `screenBounds`, `safeAreaInsets`, `horizontalSizeClass`, `verticalSizeClass`, `statusBarFrameRaw`, `hasRootVC`, `rootVCClass`, `reservedRegionsSupported` and `reservedRegionsCount`. When found in the hierarchy, it also returns `tabBarControllerClass`, `tabBarHidden`, `tabBarFrameInWindow`, `navigationControllerClass`, `navBarHidden` and `navBarFrameInWindow`.

## iPhone Duo

Bars are not always at the top and bottom of the window. Read `bars.*.edge` before placing content next to a bar. Use `windowWidth` and `windowHeight` instead of `screenWidth` and `screenHeight`, because the window changes size when the device opens and closes. Keep interactive content away from active `division` (fold) and `occlusion` (camera) regions. Recalculate on the window `postlayout` event instead of `orientationchange`.

## Migrating from previous versions

Existing keys keep their names, and on non-foldable devices they return the same values as before. Points to review:

- `statusBar`, `navigationBar` and `tabBar` return the bar thickness. For horizontal bars this is the height. For vertical bars on iPhone Duo it is the width.
- Fixed fallback values were removed. If a bar is not laid out yet, the module returns `0` instead of a default height.
- `isLandscape` is based on the window proportions instead of the interface orientation.
- Code that subtracts `tabBar` from `screenHeight` assumes a bottom tab bar. Use `bars.tabBar.edge` and `windowHeight` instead.
- `debug()` keys changed: `tabBarFrame` and `navBarFrame` are now `tabBarFrameInWindow` and `navBarFrameInWindow`.

## Corner rendering

Titanium's `borderRadius` uses circular arcs. Rounded Apple displays use a continuous curve, so applying `displayCornerRadius` directly to a standard Titanium view is a numeric approximation. A future view-focused API can apply native concentric or continuous corners.

New Apple hardware may not be in the bundled lookup. In that case `displayCornerRadius` is `0`, `displayCornerRadiusKnown` is `false`, `displayCornerRadiusSource` is `"unavailable"` and `displayCornerCurve` is `"unknown"`.

## Third-party notices

The display corner lookup is adapted from BezelKit. See `third-party-notices.md`.
