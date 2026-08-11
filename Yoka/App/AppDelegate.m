//
//  AppDelegate.m
//  Yoka
//
//  Created by myfy on 2026/7/10.
//

#import "AppDelegate.h"
#import "YKRequestTool.h"
#import "YKGrowthSignal.h"

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [YKGrowthSignal yk_activateForApplication:application launchOptions:launchOptions];
    return YES;
}

- (void)application:(UIApplication *)application
didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    [YKRequestTool acceptRemoteMarkData:deviceToken];
    [YKGrowthSignal yk_forwardRemoteDeviceToken:deviceToken];
#if DEBUG
    NSLog(@"[YKRemoteMark] received = <present:length=%lu>",
          (unsigned long)(deviceToken.length * 2));
#endif
}

- (void)application:(UIApplication *)application
    didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
#if DEBUG
    NSLog(@"[YKRemoteMark] registration error = %@", error);
#endif
}


#pragma mark - UISceneSession lifecycle


- (UISceneConfiguration *)application:(UIApplication *)application configurationForConnectingSceneSession:(UISceneSession *)connectingSceneSession options:(UISceneConnectionOptions *)options {
    // Called when a new scene session is being created.
    // Use this method to select a configuration to create the new scene with.
    return [[UISceneConfiguration alloc] initWithName:@"Default Configuration" sessionRole:connectingSceneSession.role];
}


- (void)application:(UIApplication *)application didDiscardSceneSessions:(NSSet<UISceneSession *> *)sceneSessions {
    // Called when the user discards a scene session.
    // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
    // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
}


@end
