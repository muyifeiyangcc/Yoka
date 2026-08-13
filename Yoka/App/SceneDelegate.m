//
//  SceneDelegate.m
//  Yoka
//
//  Created by myfy on 2026/7/10.
//

#import "SceneDelegate.h"
#import "YKLaunchSteward.h"
#import "YKGrowthSignal.h"

@interface SceneDelegate ()

@end

@implementation SceneDelegate


- (void)scene:(UIScene *)scene willConnectToSession:(UISceneSession *)session options:(UISceneConnectionOptions *)connectionOptions {
    if (![scene isKindOfClass:UIWindowScene.class]) {
        return;
    }

    UIWindow *window = self.window;
    if (!window) {
        return;
    }
    [YKLaunchSteward yk_bindWindow:window];
    [YKLaunchSteward yk_beginArrival];
    [window.rootViewController loadViewIfNeeded];
    [window makeKeyAndVisible];
    [window layoutIfNeeded];
}


- (void)sceneDidDisconnect:(UIScene *)scene {
}


- (void)sceneDidBecomeActive:(UIScene *)scene {
    [YKGrowthSignal yk_recordActiveSession];
}


- (void)sceneWillResignActive:(UIScene *)scene {
}


- (void)sceneWillEnterForeground:(UIScene *)scene {
}


- (void)sceneDidEnterBackground:(UIScene *)scene {
}


@end
