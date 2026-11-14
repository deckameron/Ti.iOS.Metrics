/**
 * Ti.iOS.Metrics
 *
 * Created by Douglas Alves
 * Copyright (c) 2026 Upflix. All rights reserved.
 */

#import "TiIosMetricsModule.h"
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
    @"reservedRegions" : reserved[@"regions"]
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
    @"reservedRegions" : @[]
  };
}

@end
