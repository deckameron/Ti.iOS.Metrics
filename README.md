# Ti.iOS.Metrics

A Titanium iOS module that provides accurate measurements of iOS UI elements including status bar, navigation bar, tab bar, and safe area insets. Supports all iPhone and iPad models, including devices with Dynamic Island, notch, and the new floating tab bar design.

![Titanium](https://img.shields.io/badge/Titanium-13.0+-red.svg) ![Platform](https://img.shields.io/badge/platform-iOS-lightgrey.svg) ![License](https://img.shields.io/badge/license-MIT-blue.svg) ![Maintained](https://img.shields.io/badge/Maintained-Yes-green.svg)

## Features

- Status bar height (including Dynamic Island and notch)
- Navigation bar height (correctly detects bars within tab controllers)
- Tab bar height
- Safe area insets (top, bottom, left, right)
- Screen dimensions
- Device type and orientation detection
- iOS version detection

## Requirements

- Titanium SDK 13.0.0+

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

#### getHeights()

Returns a dictionary containing all UI measurements.

**Returns:** `Object`
```javascript
{
    statusBar: Number,           // Status bar height in points
    navigationBar: Number,       // Navigation bar height in points
    tabBar: Number,             // Tab bar height in points
    safeAreaTop: Number,        // Top safe area inset
    safeAreaBottom: Number,     // Bottom safe area inset
    safeAreaLeft: Number,       // Left safe area inset
    safeAreaRight: Number,      // Right safe area inset
    screenWidth: Number,        // Screen width in points
    screenHeight: Number,       // Screen height in points
    isLandscape: Boolean,       // True if device is in landscape
    isStatusBarHidden: Boolean, // True if status bar is hidden
    deviceType: String,         // "iPhone" or "iPad"
    iosVersion: Number          // iOS version (e.g., 17.0)
}
```

#### debug()

Returns detailed information about the view controller hierarchy. Useful for troubleshooting.

**Returns:** `Object`

```javascript
{
  "rootVCClass": "TiRootViewController",
  "safeAreaInsets": "{62, 0, 34, 0}",
  "hasWindow": 1,
  "windowFrame": "{{0, 0}, {440, 956}}",
  "hasRootVC": 1,
  "windowBounds": "{{0, 0}, {440, 956}}"
}
```

## Usage Examples

### Basic Usage
```javascript
const metrics = require('ti.ios.metrics');

function updateLayout() {
    const m = metrics.getHeights();
    
    console.log('Status Bar Height:', m.statusBar);
    console.log('Navigation Bar Height:', m.navigationBar);
    console.log('Tab Bar Height:', m.tabBar);
    console.log('Safe Area Top:', m.safeAreaTop);
    console.log('Safe Area Bottom:', m.safeAreaBottom);
}

// Call when needed
updateLayout();
```

### Calculate Usable Screen Height
```javascript
const metrics = require('ti.ios.metrics');

function getUsableHeight() {
    const m = metrics.getHeights();
    
    const usableHeight = m.screenHeight 
        - m.safeAreaTop 
        - m.safeAreaBottom 
        - m.navigationBar 
        - m.tabBar;
    
    return usableHeight;
}

const contentHeight = getUsableHeight();
console.log('Available content height:', contentHeight);
```

### Responsive Layout with Orientation Changes
```javascript
const metrics = require('ti.ios.metrics');

function adjustLayout() {
    const m = metrics.getHeights();
    
    // Adjust view based on orientation
    if (m.isLandscape) {
        myView.height = m.screenHeight - m.safeAreaTop - m.safeAreaBottom;
        myView.top = m.safeAreaTop;
    } else {
        myView.height = m.screenHeight - m.safeAreaTop - m.safeAreaBottom - m.navigationBar;
        myView.top = m.safeAreaTop + m.navigationBar;
    }
}

// Listen for orientation changes
Ti.Gesture.addEventListener('orientationchange', adjustLayout);

// Initial layout
adjustLayout();
```

### Position View Above Tab Bar
```javascript
const metrics = require('ti.ios.metrics');

const m = metrics.getHeights();

const floatingButton = Ti.UI.createButton({
    title: 'Action',
    width: 200,
    height: 50,
    bottom: m.tabBar + 20  // 20pt above tab bar
});
```

### Adaptive Header Height
```javascript
const metrics = require('ti.ios.metrics');

function createHeader() {
    const m = metrics.getHeights();
    
    const header = Ti.UI.createView({
        top: 0,
        height: m.safeAreaTop + m.navigationBar,
        backgroundColor: '#007AFF'
    });
    
    const title = Ti.UI.createLabel({
        text: 'My App',
        top: m.safeAreaTop,
        height: m.navigationBar,
        textAlign: 'center',
        color: '#fff'
    });
    
    header.add(title);
    return header;
}
```

### Check Device Capabilities
```javascript
const metrics = require('ti.ios.metrics');

const m = metrics.getHeights();

// Check if device has notch/Dynamic Island
const hasNotch = m.safeAreaTop > 20;

// Check if device has home indicator
const hasHomeIndicator = m.safeAreaBottom > 0;

// Adjust UI accordingly
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

const contentView = Ti.UI.createScrollView({
    contentHeight: 'auto',
    top: m.safeAreaTop + m.navigationBar,
    bottom: m.safeAreaBottom + m.tabBar,
    left: m.safeAreaLeft,
    right: m.safeAreaRight
});
```

## Troubleshooting

### Navigation Bar or Tab Bar returns 0

If you're getting 0 for navigation or tab bar heights, ensure you're calling `getHeights()` after the UI is fully laid out:
```javascript
// Wait for window to open
win.addEventListener('open', function() {
    setTimeout(function() {
        const metrics = require('ti.ios.metrics');
        const m = metrics.getHeights();
        console.log(m);
    }, 100);
});
```

### Using the debug() method

If you're experiencing issues, use the `debug()` method to see the view controller hierarchy:
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
