/**
 * Ti.iOS.Metrics
 *
 * Created by Your Name
 * Copyright (c) 2026 Your Company. All rights reserved.
 */

#import "TiIosMetricsModule.h"
#import <UIKit/UIKit.h>

@implementation TiIosMetricsModule

#pragma mark Public APIs

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
        @"iosVersion": [self _getIOSVersion]
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

- (NSDictionary *)_emptyMetrics
{
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
        @"iosVersion": @(0)
    };
}

@end
