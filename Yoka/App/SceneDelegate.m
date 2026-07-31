//
//  SceneDelegate.m
//  Yoka
//
//  Created by myfy on 2026/7/10.
//

#import "SceneDelegate.h"
#import "YKLaunchSteward.h"

@interface SceneDelegate ()

@end

@implementation SceneDelegate


- (void)scene:(UIScene *)scene willConnectToSession:(UISceneSession *)session options:(UISceneConnectionOptions *)connectionOptions {
    if (![scene isKindOfClass:UIWindowScene.class]) {
        return;
    }

    UIWindowScene *windowScene = (UIWindowScene *)scene;
    UIWindow *window = [[UIWindow alloc] initWithWindowScene:windowScene];
    self.window = window;
    [YKLaunchSteward yk_bindWindow:window];
    [YKLaunchSteward yk_steerColdStart];
    [window makeKeyAndVisible];
}


- (void)sceneDidDisconnect:(UIScene *)scene {
}


- (void)sceneDidBecomeActive:(UIScene *)scene {
}


- (void)sceneWillResignActive:(UIScene *)scene {
}


- (void)sceneWillEnterForeground:(UIScene *)scene {
}


- (void)sceneDidEnterBackground:(UIScene *)scene {
}


@end
