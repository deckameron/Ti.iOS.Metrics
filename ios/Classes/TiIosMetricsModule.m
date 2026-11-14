/**
 * Ti.iOS.Metrics
 *
 * Created by Douglas Alves
 * Copyright (c) 2026 Upflix. All rights reserved.
 */

#import "TiIosMetricsModule.h"
#import <TargetConditionals.h>
#import <UIKit/UIKit.h>
#import <sys/utsname.h>

// Reserved regions (fold / camera) exist only in the iOS 27.1 SDK and later.
// The guard keeps the module compiling with older Xcode versions.
#if defined(__IPHONE_OS_VERSION_MAX_ALLOWED) && __IPHONE_OS_VERSION_MAX_ALLOWED >= 270100
#define TI_METRICS_HAS_RESERVED_REGIONS 1
#else
#define TI_METRICS_HAS_RESERVED_REGIONS 0
#endif

#pragma mark - Geometry helpers

// Which window edge a bar is attached to, based on its frame.
// A bar taller than it is wide is treated as vertical (iPhone Duo side bars).
static NSString *TiMetricsEdgeForFrame(CGRect frame, CGRect bounds)
{
  if (CGRectIsNull(frame) || CGRectIsEmpty(frame)) {
    return @"none";
  }

  BOOL vertical = frame.size.height > frame.size.width;
  if (vertical) {
    return CGRectGetMidX(frame) < CGRectGetMidX(bounds) ? @"left" : @"right";
  }
  return CGRectGetMidY(frame) < CGRectGetMidY(bounds) ? @"top" : @"bottom";
}

// Frame, edge and thickness of a bar in window coordinates.
// "thickness" is the height for horizontal bars and the width for vertical bars.
static NSDictionary *TiMetricsBarInfo(CGRect frame, CGRect bounds)
{
  CGRect clipped = CGRectIsNull(frame) ? CGRectNull : CGRectIntersection(frame, bounds);
  NSString *edge = TiMetricsEdgeForFrame(clipped, bounds);

  if ([edge isEqualToString:@"none"]) {
    return @{
      @"x" : @(0),
      @"y" : @(0),
      @"width" : @(0),
      @"height" : @(0),
      @"edge" : edge,
      @"thickness" : @(0)
    };
  }

  BOOL vertical = [edge isEqualToString:@"left"] || [edge isEqualToString:@"right"];
  CGFloat thickness = vertical ? clipped.size.width : clipped.size.height;

  return @{
    @"x" : @(clipped.origin.x),
    @"y" : @(clipped.origin.y),
    @"width" : @(clipped.size.width),
    @"height" : @(clipped.size.height),
    @"edge" : edge,
    @"thickness" : @(thickness)
  };
}

static NSString *TiMetricsSizeClassName(UIUserInterfaceSizeClass sizeClass)
{
  switch (sizeClass) {
    case UIUserInterfaceSizeClassCompact:
      return @"compact";
    case UIUserInterfaceSizeClassRegular:
      return @"regular";
    default:
      return @"unspecified";
  }
}

static void TiIosMetricsAddDisplayCornerRadius(NSMutableDictionary<NSString *, NSNumber *> *lookup,
                                                NSNumber *radius,
                                                NSArray<NSString *> *modelIdentifiers)
{
    for (NSString *modelIdentifier in modelIdentifiers) {
        lookup[modelIdentifier] = radius;
    }
}

static NSDictionary<NSString *, NSNumber *> *TiIosMetricsDisplayCornerRadiusLookup(void)
{
    static NSDictionary<NSString *, NSNumber *> *lookup;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSMutableDictionary<NSString *, NSNumber *> *values = [NSMutableDictionary dictionary];

        // Display corner measurements are adapted from BezelKit's simulator-derived
        // device database. See documentation/third-party-notices.md for attribution.
        TiIosMetricsAddDisplayCornerRadius(values, @0.0, @[
            @"iPhone1,1", @"iPhone1,2", @"iPhone2,1", @"iPhone3,1", @"iPhone3,2", @"iPhone3,3",
            @"iPhone4,1", @"iPhone5,1", @"iPhone5,2", @"iPhone5,3", @"iPhone5,4", @"iPhone6,1",
            @"iPhone6,2", @"iPhone7,1", @"iPhone7,2", @"iPhone8,1", @"iPhone8,2", @"iPhone8,4",
            @"iPhone9,1", @"iPhone9,2", @"iPhone9,3", @"iPhone9,4", @"iPhone10,1", @"iPhone10,2",
            @"iPhone10,4", @"iPhone10,5", @"iPhone12,8", @"iPhone14,6"
        ]);
        TiIosMetricsAddDisplayCornerRadius(values, @39.0, @[
            @"iPhone10,3", @"iPhone10,6", @"iPhone11,2", @"iPhone11,4", @"iPhone11,6",
            @"iPhone12,3", @"iPhone12,5"
        ]);
        TiIosMetricsAddDisplayCornerRadius(values, @41.5, @[
            @"iPhone11,8", @"iPhone12,1"
        ]);
        TiIosMetricsAddDisplayCornerRadius(values, @44.0, @[
            @"iPhone13,1", @"iPhone14,4"
        ]);
        TiIosMetricsAddDisplayCornerRadius(values, @47.33, @[
            @"iPhone13,2", @"iPhone13,3", @"iPhone14,2", @"iPhone14,5", @"iPhone14,7",
            @"iPhone17,5", @"iPhone18,5"
        ]);
        TiIosMetricsAddDisplayCornerRadius(values, @53.33, @[
            @"iPhone13,4", @"iPhone14,3", @"iPhone14,8"
        ]);
        TiIosMetricsAddDisplayCornerRadius(values, @55.0, @[
            @"iPhone15,2", @"iPhone15,3", @"iPhone15,4", @"iPhone15,5", @"iPhone16,1",
            @"iPhone16,2", @"iPhone17,3", @"iPhone17,4"
        ]);
        TiIosMetricsAddDisplayCornerRadius(values, @62.0, @[
            @"iPhone17,1", @"iPhone17,2", @"iPhone18,1", @"iPhone18,2", @"iPhone18,3", @"iPhone18,4"
        ]);

        TiIosMetricsAddDisplayCornerRadius(values, @0.0, @[
            @"iPad1,1", @"iPad2,1", @"iPad2,2", @"iPad2,3", @"iPad2,4", @"iPad2,5", @"iPad2,6",
            @"iPad2,7", @"iPad3,1", @"iPad3,2", @"iPad3,3", @"iPad3,4", @"iPad3,5", @"iPad3,6",
            @"iPad4,1", @"iPad4,2", @"iPad4,3", @"iPad4,4", @"iPad4,5", @"iPad4,6", @"iPad4,7",
            @"iPad4,8", @"iPad4,9", @"iPad5,1", @"iPad5,2", @"iPad5,3", @"iPad5,4", @"iPad6,3",
            @"iPad6,4", @"iPad6,7", @"iPad6,8", @"iPad6,11", @"iPad6,12", @"iPad7,1", @"iPad7,2",
            @"iPad7,3", @"iPad7,4", @"iPad7,5", @"iPad7,6", @"iPad7,11", @"iPad7,12", @"iPad11,1",
            @"iPad11,2", @"iPad11,3", @"iPad11,4", @"iPad11,6", @"iPad11,7", @"iPad12,1", @"iPad12,2"
        ]);
        TiIosMetricsAddDisplayCornerRadius(values, @18.0, @[
            @"iPad8,1", @"iPad8,2", @"iPad8,3", @"iPad8,4", @"iPad8,5", @"iPad8,6", @"iPad8,7",
            @"iPad8,8", @"iPad8,9", @"iPad8,10", @"iPad8,11", @"iPad8,12", @"iPad13,1", @"iPad13,2",
            @"iPad13,4", @"iPad13,5", @"iPad13,6", @"iPad13,7", @"iPad13,8", @"iPad13,9", @"iPad13,10",
            @"iPad13,11", @"iPad13,16", @"iPad13,17", @"iPad14,3", @"iPad14,4", @"iPad14,5", @"iPad14,6",
            @"iPad14,8", @"iPad14,9", @"iPad14,10", @"iPad14,11", @"iPad15,3", @"iPad15,4", @"iPad15,5",
            @"iPad15,6", @"iPad16,8", @"iPad16,9", @"iPad16,10", @"iPad16,11"
        ]);
        TiIosMetricsAddDisplayCornerRadius(values, @21.5, @[
            @"iPad14,1", @"iPad14,2", @"iPad16,1", @"iPad16,2"
        ]);
        TiIosMetricsAddDisplayCornerRadius(values, @25.0, @[
            @"iPad13,18", @"iPad13,19", @"iPad15,7", @"iPad15,8"
        ]);
        TiIosMetricsAddDisplayCornerRadius(values, @30.0, @[
            @"iPad16,3", @"iPad16,4", @"iPad16,5", @"iPad16,6", @"iPad17,1", @"iPad17,2",
            @"iPad17,3", @"iPad17,4"
        ]);

        lookup = [values copy];
    });

    return lookup;
}

static NSString *TiIosMetricsDeviceModelIdentifier(void)
{
#if TARGET_OS_SIMULATOR
    NSString *simulatorModelIdentifier = NSProcessInfo.processInfo.environment[@"SIMULATOR_MODEL_IDENTIFIER"];
    if (simulatorModelIdentifier.length > 0) {
        return simulatorModelIdentifier;
    }
#endif

    struct utsname systemInfo;
    if (uname(&systemInfo) != 0) {
        return @"";
    }

    NSString *modelIdentifier = [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
    return modelIdentifier ?: @"";
}

@implementation TiIosMetricsModule

#pragma mark - Public APIs

- (NSDictionary *)getHeights:(id)unused
{
  __block NSDictionary *result = nil;

  if ([NSThread isMainThread]) {
    result = [self _getHeightsOnMainThread];
  } else {
    dispatch_sync(dispatch_get_main_queue(), ^{
      result = [self _getHeightsOnMainThread];
    });
  }

  return result;
}

- (NSNumber *)getDisplayCornerRadius:(id)unused
{
    return [self _getDisplayCornerMetrics][@"displayCornerRadius"];
}

- (NSDictionary *)debug:(id)unused
{
  __block NSDictionary *result = nil;

  if ([NSThread isMainThread]) {
    result = [self _debugOnMainThread];
  } else {
    dispatch_sync(dispatch_get_main_queue(), ^{
      result = [self _debugOnMainThread];
    });
  }

  return result;
}

// Returns true when running on an iPhone Duo (or its simulator).
// Based on the hardware model identifier, so new Duo models must be added
// to the list below as Apple releases them.
- (NSNumber *)isDuo:(id)unused
{
  static NSSet<NSString *> *duoIdentifiers = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    duoIdentifiers = [NSSet setWithObjects:
                                @"iPhone19,4", // iPhone Duo (2026)
                                nil];
  });

  return @([duoIdentifiers containsObject:[self _modelIdentifier]]);
}

#pragma mark - Device model

// Hardware model identifier, e.g. "iPhone19,4".
// On the simulator the hardware reports the Mac architecture (e.g. "arm64"),
// so the simulated device identifier is read from the environment instead.
- (NSString *)_modelIdentifier
{
#if TARGET_OS_SIMULATOR
  NSString *simulated = NSProcessInfo.processInfo.environment[@"SIMULATOR_MODEL_IDENTIFIER"];
  if (simulated.length > 0) {
    return simulated;
  }
#endif

  struct utsname systemInfo;
  uname(&systemInfo);
  NSString *identifier = [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
  return identifier ?: @"";
}

#pragma mark - Metrics

- (NSDictionary *)_getHeightsOnMainThread
{
  NSDictionary *displayCornerMetrics = [self _getDisplayCornerMetrics];
  UIWindow *window = [self _getKeyWindow];
  if (!window) {
    return [self _emptyMetrics];
  }

  [window layoutIfNeeded];

  CGRect windowBounds = window.bounds;
  UIViewController *rootVC = window.rootViewController;

  // Bars (frames in window coordinates)
  BOOL isStatusBarHidden = [self _isStatusBarHiddenForWindow:window];
  CGRect statusBarFrame = isStatusBarHidden ? CGRectNull : [self _statusBarFrameForWindow:window];
  CGRect navBarFrame = [self _navigationBarFrameForWindow:window rootVC:rootVC];
  CGRect tabBarFrame = [self _tabBarFrameForWindow:window rootVC:rootVC];

  NSDictionary *statusBarInfo = TiMetricsBarInfo(statusBarFrame, windowBounds);
  NSDictionary *navBarInfo = TiMetricsBarInfo(navBarFrame, windowBounds);
  NSDictionary *tabBarInfo = TiMetricsBarInfo(tabBarFrame, windowBounds);

  // Safe area
  UIEdgeInsets safeAreaInsets = window.safeAreaInsets;

  // Screen (physical display) and window (area the app actually gets)
  CGRect screenBounds = [self _screenBoundsForWindow:window];

  // Size classes
  UITraitCollection *traits = window.traitCollection;

  // Fold and camera regions (iOS 27.1+)
  NSDictionary *reserved = [self _reservedRegionsForWindow:window];

  return @{
    // Existing keys (thickness: height for horizontal bars, width for vertical bars)
    @"statusBar" : statusBarInfo[@"thickness"],
    @"navigationBar" : navBarInfo[@"thickness"],
    @"tabBar" : tabBarInfo[@"thickness"],
    @"safeAreaTop" : @(safeAreaInsets.top),
    @"safeAreaBottom" : @(safeAreaInsets.bottom),
    @"safeAreaLeft" : @(safeAreaInsets.left),
    @"safeAreaRight" : @(safeAreaInsets.right),
    @"screenWidth" : @(screenBounds.size.width),
    @"screenHeight" : @(screenBounds.size.height),
    @"isLandscape" : @(windowBounds.size.width > windowBounds.size.height),
    @"isStatusBarHidden" : @(isStatusBarHidden),
    @"deviceType" : [self _getDeviceType],
    @"iosVersion" : [self _getIOSVersion],

    // New keys
    @"windowWidth" : @(windowBounds.size.width),
    @"windowHeight" : @(windowBounds.size.height),
    @"horizontalSizeClass" : TiMetricsSizeClassName(traits.horizontalSizeClass),
    @"verticalSizeClass" : TiMetricsSizeClassName(traits.verticalSizeClass),
    @"bars" : @{
      @"statusBar" : statusBarInfo,
      @"navigationBar" : navBarInfo,
      @"tabBar" : tabBarInfo
    },
    @"reservedRegionsSupported" : reserved[@"supported"],
    @"reservedRegions" : reserved[@"regions"],

    // Display corner
    @"displayCornerRadius" : displayCornerMetrics[@"displayCornerRadius"],
    @"displayCornerRadiusKnown" : displayCornerMetrics[@"displayCornerRadiusKnown"],
    @"displayCornerRadiusSource" : displayCornerMetrics[@"displayCornerRadiusSource"],
    @"displayCornerCurve" : displayCornerMetrics[@"displayCornerCurve"]
  };
}

#pragma mark - Window

- (UIWindow *)_getKeyWindow
{
  UIWindow *window = nil;

  for (UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
    if (![scene isKindOfClass:[UIWindowScene class]]) {
      continue;
    }

    UIWindowScene *windowScene = (UIWindowScene *)scene;
    if (windowScene.activationState != UISceneActivationStateForegroundActive &&
        windowScene.activationState != UISceneActivationStateForegroundInactive) {
      continue;
    }

    for (UIWindow *w in windowScene.windows) {
      if (w.isKeyWindow) {
        return w;
      }
    }

    if (!window && windowScene.windows.count > 0) {
      window = windowScene.windows.firstObject;
    }
  }

  if (!window) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    window = UIApplication.sharedApplication.keyWindow;
    if (!window) {
      window = UIApplication.sharedApplication.windows.firstObject;
    }
#pragma clang diagnostic pop
  }

  return window;
}

- (CGRect)_screenBoundsForWindow:(UIWindow *)window
{
  UIScreen *screen = window.windowScene.screen;
  if (screen) {
    return screen.bounds;
  }

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
  return [UIScreen mainScreen].bounds;
#pragma clang diagnostic pop
}

#pragma mark - Status bar

- (BOOL)_isStatusBarHiddenForWindow:(UIWindow *)window
{
  UIStatusBarManager *manager = window.windowScene.statusBarManager;
  if (manager) {
    return manager.isStatusBarHidden;
  }

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
  return UIApplication.sharedApplication.isStatusBarHidden;
#pragma clang diagnostic pop
}

- (CGRect)_statusBarFrameForWindow:(UIWindow *)window
{
  UIWindowScene *scene = window.windowScene;
  UIStatusBarManager *manager = scene.statusBarManager;

  if (!manager) {
    return CGRectNull;
  }

  CGRect frame = manager.statusBarFrame;
  if (CGRectIsEmpty(frame)) {
    return CGRectNull;
  }

  // statusBarFrame is reported in the scene's coordinate space.
  return [window convertRect:frame fromCoordinateSpace:scene.coordinateSpace];
}

#pragma mark - Navigation bar

- (CGRect)_navigationBarFrameForWindow:(UIWindow *)window rootVC:(UIViewController *)rootVC
{
  UINavigationController *nav = [self _findNavigationControllerInHierarchy:rootVC];
  if (!nav || nav.navigationBarHidden) {
    return CGRectNull;
  }

  UINavigationBar *bar = nav.navigationBar;
  if (bar.hidden || bar.alpha <= 0.0 || bar.window != window) {
    return CGRectNull;
  }

  return [bar convertRect:bar.bounds toView:window];
}

- (UINavigationController *)_findNavigationControllerInHierarchy:(UIViewController *)vc
{
  if (!vc) {
    return nil;
  }

  if ([vc isKindOfClass:[UINavigationController class]]) {
    return (UINavigationController *)vc;
  }

  if ([vc isKindOfClass:[UITabBarController class]]) {
    UITabBarController *tabController = (UITabBarController *)vc;
    return [self _findNavigationControllerInHierarchy:tabController.selectedViewController];
  }

  if (vc.navigationController) {
    return vc.navigationController;
  }

  for (UIViewController *child in vc.childViewControllers) {
    UINavigationController *found = [self _findNavigationControllerInHierarchy:child];
    if (found) {
      return found;
    }
  }

  return nil;
}

#pragma mark - Tab bar

- (CGRect)_tabBarFrameForWindow:(UIWindow *)window rootVC:(UIViewController *)rootVC
{
  UITabBarController *tabController = [self _findTabBarControllerInHierarchy:rootVC];
  if (!tabController) {
    return CGRectNull;
  }

  UITabBar *bar = tabController.tabBar;
  if (bar.hidden || bar.alpha <= 0.0 || bar.window != window) {
    return CGRectNull;
  }

  return [bar convertRect:bar.bounds toView:window];
}

- (UITabBarController *)_findTabBarControllerInHierarchy:(UIViewController *)vc
{
  if (!vc) {
    return nil;
  }

  if ([vc isKindOfClass:[UITabBarController class]]) {
    return (UITabBarController *)vc;
  }

  if (vc.tabBarController) {
    return vc.tabBarController;
  }

  for (UIViewController *child in vc.childViewControllers) {
    UITabBarController *found = [self _findTabBarControllerInHierarchy:child];
    if (found) {
      return found;
    }
  }

  return nil;
}

#pragma mark - Reserved regions (iPhone Duo)

// Returns @{ supported: BOOL, regions: [ { kind, active, x, y, width, height, margins } ] }
// Frames are in window coordinates and already include the margins.
// Inactive regions are included so the app can reserve space ahead of time.
- (NSDictionary *)_reservedRegionsForWindow:(UIWindow *)window
{
  NSMutableArray *regions = [NSMutableArray array];
  BOOL supported = NO;

#if TI_METRICS_HAS_RESERVED_REGIONS
  if (@available(iOS 27.1, *)) {
    supported = YES;

    NSArray<UIViewReservedRegionKind *> *kinds = @[
      UIViewReservedRegionKind.occlusionRegionKind,
      UIViewReservedRegionKind.divisionRegionKind
    ];
    NSArray<NSString *> *names = @[ @"occlusion", @"division" ];

    for (NSUInteger i = 0; i < kinds.count; i++) {
      NSArray<UIViewReservedRegion *> *found =
          [window reservedRegionsOfKind:kinds[i]
                                options:UIViewReservedRegionQueryOptionsIncludeInactive];

      for (UIViewReservedRegion *region in found) {
        CGRect frame = region.frame;
        UIEdgeInsets margins = region.margins;

        [regions addObject:@{
          @"kind" : names[i],
          @"active" : @(region.isActive),
          @"x" : @(frame.origin.x),
          @"y" : @(frame.origin.y),
          @"width" : @(frame.size.width),
          @"height" : @(frame.size.height),
          @"margins" : @{
            @"top" : @(margins.top),
            @"left" : @(margins.left),
            @"bottom" : @(margins.bottom),
            @"right" : @(margins.right)
          }
        }];
      }
    }
  }
#endif

  return @{
    @"supported" : @(supported),
    @"regions" : regions
  };
}

#pragma mark - Device info

- (NSString *)_getDeviceType
{
  UIUserInterfaceIdiom idiom = UIDevice.currentDevice.userInterfaceIdiom;
  if (idiom == UIUserInterfaceIdiomPad) {
    return @"iPad";
  } else if (idiom == UIUserInterfaceIdiomPhone) {
    return @"iPhone";
  }
  return @"unknown";
}

- (NSNumber *)_getIOSVersion
{
  NSString *version = [[UIDevice currentDevice] systemVersion];
  return @([version doubleValue]);
}

- (NSDictionary *)_getDisplayCornerMetrics
{
    static NSDictionary *displayCornerMetrics;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *modelIdentifier = TiIosMetricsDeviceModelIdentifier();
        NSNumber *knownRadius = TiIosMetricsDisplayCornerRadiusLookup()[modelIdentifier];
        BOOL isKnown = knownRadius != nil;
        NSNumber *radius = knownRadius ?: @0.0;
        NSString *curve = isKnown ? (radius.doubleValue > 0 ? @"continuous" : @"square") : @"unknown";

        displayCornerMetrics = @{
            @"displayCornerRadius": radius,
            @"displayCornerRadiusKnown": @(isKnown),
            @"displayCornerRadiusSource": isKnown ? @"modelLookup" : @"unavailable",
            @"displayCornerCurve": curve
        };
    });

    return displayCornerMetrics;
}

#pragma mark - Debug

- (NSDictionary *)_debugOnMainThread
{
  NSMutableDictionary *info = [NSMutableDictionary dictionary];

  UIWindow *window = [self _getKeyWindow];
  info[@"hasWindow"] = @(window != nil);

  if (!window) {
    return info;
  }

  info[@"windowFrame"] = NSStringFromCGRect(window.frame);
  info[@"windowBounds"] = NSStringFromCGRect(window.bounds);
  info[@"screenBounds"] = NSStringFromCGRect([self _screenBoundsForWindow:window]);
  info[@"safeAreaInsets"] = NSStringFromUIEdgeInsets(window.safeAreaInsets);
  info[@"horizontalSizeClass"] = TiMetricsSizeClassName(window.traitCollection.horizontalSizeClass);
  info[@"verticalSizeClass"] = TiMetricsSizeClassName(window.traitCollection.verticalSizeClass);

  UIStatusBarManager *manager = window.windowScene.statusBarManager;
  if (manager) {
    info[@"statusBarFrameRaw"] = NSStringFromCGRect(manager.statusBarFrame);
  }

  UIViewController *rootVC = window.rootViewController;
  info[@"hasRootVC"] = @(rootVC != nil);
  info[@"rootVCClass"] = rootVC ? NSStringFromClass([rootVC class]) : @"nil";

  UITabBarController *tabController = [self _findTabBarControllerInHierarchy:rootVC];
  if (tabController) {
    info[@"tabBarControllerClass"] = NSStringFromClass([tabController class]);
    info[@"tabBarHidden"] = @(tabController.tabBar.hidden);
    info[@"tabBarFrameInWindow"] = NSStringFromCGRect([tabController.tabBar convertRect:tabController.tabBar.bounds toView:window]);
  }

  UINavigationController *nav = [self _findNavigationControllerInHierarchy:rootVC];
  if (nav) {
    info[@"navigationControllerClass"] = NSStringFromClass([nav class]);
    info[@"navBarHidden"] = @(nav.navigationBarHidden);
    info[@"navBarFrameInWindow"] = NSStringFromCGRect([nav.navigationBar convertRect:nav.navigationBar.bounds toView:window]);
  }

  NSDictionary *reserved = [self _reservedRegionsForWindow:window];
  info[@"reservedRegionsSupported"] = reserved[@"supported"];
  info[@"reservedRegionsCount"] = @([reserved[@"regions"] count]);

  return info;
}

#pragma mark - Empty

- (NSDictionary *)_emptyMetrics
{
  NSDictionary *displayCornerMetrics = [self _getDisplayCornerMetrics];

  NSDictionary *emptyBar = @{
    @"x" : @(0),
    @"y" : @(0),
    @"width" : @(0),
    @"height" : @(0),
    @"edge" : @"none",
    @"thickness" : @(0)
  };

  return @{
    @"statusBar" : @(0),
    @"navigationBar" : @(0),
    @"tabBar" : @(0),
    @"safeAreaTop" : @(0),
    @"safeAreaBottom" : @(0),
    @"safeAreaLeft" : @(0),
    @"safeAreaRight" : @(0),
    @"screenWidth" : @(0),
    @"screenHeight" : @(0),
    @"isLandscape" : @(NO),
    @"isStatusBarHidden" : @(NO),
    @"deviceType" : @"unknown",
    @"iosVersion" : @(0),
    @"windowWidth" : @(0),
    @"windowHeight" : @(0),
    @"horizontalSizeClass" : @"unspecified",
    @"verticalSizeClass" : @"unspecified",
    @"bars" : @{
      @"statusBar" : emptyBar,
      @"navigationBar" : emptyBar,
      @"tabBar" : emptyBar
    },
    @"reservedRegionsSupported" : @(NO),
    @"reservedRegions" : @[],

    // Display corner
    @"displayCornerRadius" : displayCornerMetrics[@"displayCornerRadius"],
    @"displayCornerRadiusKnown" : displayCornerMetrics[@"displayCornerRadiusKnown"],
    @"displayCornerRadiusSource" : displayCornerMetrics[@"displayCornerRadiusSource"],
    @"displayCornerCurve" : displayCornerMetrics[@"displayCornerCurve"]
  };
}

@end
