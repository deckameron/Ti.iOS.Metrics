/**
 * Ti.iOS.Metrics
 *
 * Created by Your Name
 * Copyright (c) 2026 Your Company. All rights reserved.
 */

#import "TiIosMetricsModule.h"
#import <TargetConditionals.h>
#import <UIKit/UIKit.h>
#import <sys/utsname.h>

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

#pragma mark Public APIs

- (NSNumber *)getDisplayCornerRadius:(id)unused
{
    return [self _getDisplayCornerMetrics][@"displayCornerRadius"];
}

// NOVO: Método de debug para ver a hierarchy
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
    
    UIViewController *rootVC = window.rootViewController;
    info[@"hasRootVC"] = @(rootVC != nil);
    info[@"rootVCClass"] = rootVC ? NSStringFromClass([rootVC class]) : @"nil";
    
    if ([rootVC isKindOfClass:[UITabBarController class]]) {
        UITabBarController *tabController = (UITabBarController *)rootVC;
        info[@"isTabBarController"] = @YES;
        info[@"tabBarHidden"] = @(tabController.tabBar.hidden);
        info[@"tabBarFrame"] = NSStringFromCGRect(tabController.tabBar.frame);
        info[@"tabBarBounds"] = NSStringFromCGRect(tabController.tabBar.bounds);
        
        UIViewController *selectedVC = tabController.selectedViewController;
        info[@"hasSelectedVC"] = @(selectedVC != nil);
        info[@"selectedVCClass"] = selectedVC ? NSStringFromClass([selectedVC class]) : @"nil";
        
        if ([selectedVC isKindOfClass:[UINavigationController class]]) {
            UINavigationController *navController = (UINavigationController *)selectedVC;
            info[@"isNavigationController"] = @YES;
            info[@"navBarHidden"] = @(navController.navigationBarHidden);
            info[@"navBarFrame"] = NSStringFromCGRect(navController.navigationBar.frame);
            info[@"navBarBounds"] = NSStringFromCGRect(navController.navigationBar.bounds);
            
            info[@"topVCClass"] = navController.topViewController ? NSStringFromClass([navController.topViewController class]) : @"nil";
        }
    }
    
    if (@available(iOS 11.0, *)) {
        info[@"safeAreaInsets"] = NSStringFromUIEdgeInsets(window.safeAreaInsets);
    }
    
    return info;
}

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

- (NSDictionary *)_getHeightsOnMainThread
{
    NSDictionary *displayCornerMetrics = [self _getDisplayCornerMetrics];
    UIWindow *window = [self _getKeyWindow];
    if (!window) {
        return [self _emptyMetrics];
    }
    
    // Forçar layout antes de pegar medidas
    [window layoutIfNeeded];
    
    UIViewController *rootVC = window.rootViewController;
    UIScreen *screen = window.screen ?: [UIScreen mainScreen];
    
    CGRect screenBounds = screen.bounds;
    UIInterfaceOrientation orientation = [self _getCurrentOrientation];
    BOOL isLandscape = UIInterfaceOrientationIsLandscape(orientation);
    BOOL isStatusBarHidden = [self _isStatusBarHidden];
    
    CGFloat statusBarHeight = [self _getStatusBarHeight:window isHidden:isStatusBarHidden];
    
    // CORRIGIDO: Métodos mais robustos
    CGFloat navBarHeight = [self _getNavigationBarHeightRobust:window rootVC:rootVC];
    CGFloat tabBarHeight = [self _getTabBarHeightRobust:window rootVC:rootVC];
    
    UIEdgeInsets safeAreaInsets = [self _getSafeAreaInsets:window];
    
    CGFloat screenWidth = screenBounds.size.width;
    CGFloat screenHeight = screenBounds.size.height;
    
    return @{
        @"statusBar": @(statusBarHeight),
        @"navigationBar": @(navBarHeight),
        @"tabBar": @(tabBarHeight),
        @"safeAreaTop": @(safeAreaInsets.top),
        @"safeAreaBottom": @(safeAreaInsets.bottom),
        @"safeAreaLeft": @(safeAreaInsets.left),
        @"safeAreaRight": @(safeAreaInsets.right),
        @"screenWidth": @(screenWidth),
        @"screenHeight": @(screenHeight),
        @"isLandscape": @(isLandscape),
        @"isStatusBarHidden": @(isStatusBarHidden),
        @"deviceType": [self _getDeviceType],
        @"iosVersion": [self _getIOSVersion],
        @"displayCornerRadius": displayCornerMetrics[@"displayCornerRadius"],
        @"displayCornerRadiusKnown": displayCornerMetrics[@"displayCornerRadiusKnown"],
        @"displayCornerRadiusSource": displayCornerMetrics[@"displayCornerRadiusSource"],
        @"displayCornerCurve": displayCornerMetrics[@"displayCornerCurve"]
    };
}

#pragma mark - Helper Methods (CORRIGIDOS)

- (UIWindow *)_getKeyWindow
{
    UIWindow *window = nil;
    
    if (@available(iOS 13.0, *)) {
        NSSet<UIScene *> *scenes = UIApplication.sharedApplication.connectedScenes;
        for (UIScene *scene in scenes) {
            if ([scene isKindOfClass:[UIWindowScene class]]) {
                UIWindowScene *windowScene = (UIWindowScene *)scene;
                if (windowScene.activationState == UISceneActivationStateForegroundActive ||
                    windowScene.activationState == UISceneActivationStateForegroundInactive) {
                    for (UIWindow *w in windowScene.windows) {
                        if (w.isKeyWindow) {
                            return w;
                        }
                    }
                    // Se não achou key window, pega a primeira
                    if (windowScene.windows.count > 0) {
                        window = windowScene.windows.firstObject;
                    }
                }
            }
        }
    }
    
    if (!window) {
        #pragma clang diagnostic push
        #pragma clang diagnostic ignored "-Wdeprecated-declarations"
        window = UIApplication.sharedApplication.keyWindow;
        #pragma clang diagnostic pop
    }
    
    if (!window) {
        NSArray *windows = UIApplication.sharedApplication.windows;
        for (UIWindow *w in windows) {
            if (w.isKeyWindow) {
                return w;
            }
        }
        window = windows.firstObject;
    }
    
    return window;
}

// MÉTODO ROBUSTO para Navigation Bar
- (CGFloat)_getNavigationBarHeightRobust:(UIWindow *)window rootVC:(UIViewController *)rootVC
{
    CGFloat height = 0;
    UINavigationController *navController = nil;
    
    // Método 1: Buscar recursivamente por NavigationController
    navController = [self _findNavigationControllerInHierarchy:rootVC];
    
    if (navController && !navController.navigationBarHidden) {
        height = navController.navigationBar.frame.size.height;
        
        // Se o frame ainda é 0, usar altura padrão
        if (height == 0) {
            height = 44.0; // Altura padrão da navigation bar
        }
    }
    
    // Método 2: Se ainda é 0, tentar calcular pela diferença de frames
    if (height == 0 && navController) {
        UIView *navBarView = navController.navigationBar;
        if (navBarView.superview) {
            [navBarView.superview layoutIfNeeded];
            height = navBarView.frame.size.height;
        }
    }
    
    return height;
}

// MÉTODO ROBUSTO para Tab Bar
- (CGFloat)_getTabBarHeightRobust:(UIWindow *)window rootVC:(UIViewController *)rootVC
{
    CGFloat height = 0;
    UITabBarController *tabController = nil;
    
    // Método 1: Buscar TabBarController
    tabController = [self _findTabBarControllerInHierarchy:rootVC];
    
    if (tabController && !tabController.tabBar.hidden) {
        height = tabController.tabBar.frame.size.height;
        
        // Se o frame ainda é 0, usar altura padrão baseada no device
        if (height == 0) {
            if (@available(iOS 11.0, *)) {
                // Usar safe area bottom como base
                UIEdgeInsets safeArea = window.safeAreaInsets;
                height = 49.0 + safeArea.bottom; // 49pt é a altura padrão
            } else {
                height = 49.0;
            }
        }
    }
    
    // Método 2: Calcular pela posição na tela
    if (height == 0 && tabController) {
        UITabBar *tabBar = tabController.tabBar;
        if (tabBar.superview) {
            [tabBar.superview layoutIfNeeded];
            CGFloat tabBarY = tabBar.frame.origin.y;
            CGFloat screenHeight = window.bounds.size.height;
            
            if (tabBarY > 0 && tabBarY < screenHeight) {
                height = screenHeight - tabBarY;
            }
        }
    }
    
    return height;
}

// Buscar NavigationController recursivamente
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
    
    // Buscar em child view controllers
    for (UIViewController *child in vc.childViewControllers) {
        UINavigationController *found = [self _findNavigationControllerInHierarchy:child];
        if (found) {
            return found;
        }
    }
    
    return nil;
}

// Buscar TabBarController recursivamente
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
    
    // Buscar em child view controllers
    for (UIViewController *child in vc.childViewControllers) {
        UITabBarController *found = [self _findTabBarControllerInHierarchy:child];
        if (found) {
            return found;
        }
    }
    
    return nil;
}

- (CGFloat)_getStatusBarHeight:(UIWindow *)window isHidden:(BOOL)isHidden
{
    if (isHidden) {
        return 0;
    }
    
    CGFloat height = 0;
    
    if (@available(iOS 13.0, *)) {
        if (window.windowScene) {
            UIStatusBarManager *manager = window.windowScene.statusBarManager;
            height = manager.statusBarFrame.size.height;
        }
    }
    
    if (height == 0) {
        #pragma clang diagnostic push
        #pragma clang diagnostic ignored "-Wdeprecated-declarations"
        height = UIApplication.sharedApplication.statusBarFrame.size.height;
        #pragma clang diagnostic pop
    }
    
    return height;
}

- (BOOL)_isStatusBarHidden
{
    #pragma clang diagnostic push
    #pragma clang diagnostic ignored "-Wdeprecated-declarations"
    return UIApplication.sharedApplication.isStatusBarHidden;
    #pragma clang diagnostic pop
}

- (UIEdgeInsets)_getSafeAreaInsets:(UIWindow *)window
{
    if (@available(iOS 11.0, *)) {
        return window.safeAreaInsets;
    }
    return UIEdgeInsetsZero;
}

- (UIInterfaceOrientation)_getCurrentOrientation
{
    if (@available(iOS 13.0, *)) {
        for (UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
            if ([scene isKindOfClass:[UIWindowScene class]]) {
                UIWindowScene *windowScene = (UIWindowScene *)scene;
                if (windowScene.activationState == UISceneActivationStateForegroundActive) {
                    return windowScene.interfaceOrientation;
                }
            }
        }
    }
    
    #pragma clang diagnostic push
    #pragma clang diagnostic ignored "-Wdeprecated-declarations"
    return UIApplication.sharedApplication.statusBarOrientation;
    #pragma clang diagnostic pop
}

- (NSString *)_getDeviceType
{
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        return @"iPad";
    } else if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
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

- (NSDictionary *)_emptyMetrics
{
    NSDictionary *displayCornerMetrics = [self _getDisplayCornerMetrics];

    return @{
        @"statusBar": @(0),
        @"navigationBar": @(0),
        @"tabBar": @(0),
        @"safeAreaTop": @(0),
        @"safeAreaBottom": @(0),
        @"safeAreaLeft": @(0),
        @"safeAreaRight": @(0),
        @"screenWidth": @(0),
        @"screenHeight": @(0),
        @"isLandscape": @(NO),
        @"isStatusBarHidden": @(NO),
        @"deviceType": @"unknown",
        @"iosVersion": @(0),
        @"displayCornerRadius": displayCornerMetrics[@"displayCornerRadius"],
        @"displayCornerRadiusKnown": displayCornerMetrics[@"displayCornerRadiusKnown"],
        @"displayCornerRadiusSource": displayCornerMetrics[@"displayCornerRadiusSource"],
        @"displayCornerCurve": displayCornerMetrics[@"displayCornerCurve"]
    };
}

@end
