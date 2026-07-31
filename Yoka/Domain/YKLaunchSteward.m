//
//  YKLaunchSteward.m
//  Yoka
//

#import "YKLaunchSteward.h"
#import "YKRosterVault.h"
#import "YKLoginChoiceViewController.h"
#import "YKProfileInfoViewController.h"
#import "YKNavigationController.h"
#import "YKTabBarController.h"

@implementation YKLaunchSteward

static UIWindow *sYKBootWindow = nil;

+ (void)yk_bindWindow:(UIWindow *)window {
    sYKBootWindow = window;
}

+ (UIWindow *)yk_window {
    if (sYKBootWindow) {
        return sYKBootWindow;
    }
    for (UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
        if (![scene isKindOfClass:UIWindowScene.class]) {
            continue;
        }
        for (UIWindow *window in ((UIWindowScene *)scene).windows) {
            if (window.isKeyWindow) {
                return window;
            }
        }
    }
    return nil;
}

+ (void)yk_swapRoot:(UIViewController *)root {
    UIWindow *window = [self yk_window];
    if (!window) {
        return;
    }
    [UIView transitionWithView:window
                      duration:0.25
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:^{
        window.rootViewController = root;
    } completion:nil];
}

+ (void)yk_steerColdStart {
    YKRosterVault *vault = YKRosterVault.sharedRoster;
    if (!vault.yk_isPresenceActive) {
        [self yk_presentLanding];
        return;
    }
    if (!vault.yk_isDossierReady) {
        YKProfileInfoViewController *profile = [[YKProfileInfoViewController alloc] init];
        profile.yk_firstPassSetup = YES;
        [self yk_swapRoot:[[YKNavigationController alloc] initWithRootViewController:profile]];
        return;
    }
    [self yk_presentMainDeck];
}

+ (void)yk_presentLanding {
    YKLoginChoiceViewController *landing = [[YKLoginChoiceViewController alloc] init];
    [self yk_swapRoot:[[YKNavigationController alloc] initWithRootViewController:landing]];
}

+ (void)yk_presentMainDeck {
    [self yk_swapRoot:[[YKTabBarController alloc] init]];
}

+ (void)yk_proceedPastCredentialFrom:(UINavigationController *)navigationController {
    YKRosterVault *vault = YKRosterVault.sharedRoster;
    if (vault.yk_isDossierReady) {
        [self yk_presentMainDeck];
        return;
    }
    YKProfileInfoViewController *profile = [[YKProfileInfoViewController alloc] init];
    profile.yk_firstPassSetup = YES;
    if (navigationController) {
        [navigationController pushViewController:profile animated:YES];
    } else {
        [self yk_swapRoot:[[YKNavigationController alloc] initWithRootViewController:profile]];
    }
}

@end
