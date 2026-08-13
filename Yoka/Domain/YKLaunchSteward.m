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

static YKNavigationController *sYKRouteShell = nil;

+ (void)yk_bindWindow:(UIWindow *)window {
    if ([window.rootViewController isKindOfClass:YKNavigationController.class]) {
        sYKRouteShell = (YKNavigationController *)window.rootViewController;
        return;
    }
    UIViewController *foundation = window.rootViewController ?: [[UIViewController alloc] init];
    foundation.view.backgroundColor = UIColor.blackColor;
    sYKRouteShell = [[YKNavigationController alloc] initWithRootViewController:foundation];
    [window setRootViewController:sYKRouteShell];
}

+ (void)yk_displayRoute:(UIViewController *)route animated:(BOOL)animated {
    YKNavigationController *shell = sYKRouteShell;
    if (!shell || !route) {
        return;
    }
    void (^replaceStack)(void) = ^{
        [shell setViewControllers:@[route] animated:NO];
    };
    if (!animated || shell.view.window == nil) {
        replaceStack();
        return;
    }
    [UIView transitionWithView:shell.view
                      duration:0.25
                       options:UIViewAnimationOptionTransitionCrossDissolve | UIViewAnimationOptionAllowAnimatedContent
                    animations:replaceStack
                    completion:nil];
}

+ (void)yk_beginArrival {
    YKLoginChoiceViewController *landing = [[YKLoginChoiceViewController alloc] initForArrival];
    [self yk_displayRoute:landing animated:NO];
}

+ (void)yk_restoreMemberPlace {
    YKRosterVault *vault = YKRosterVault.sharedRoster;
    if (!vault.yk_isPresenceActive) {
        YKLoginChoiceViewController *landing = [[YKLoginChoiceViewController alloc] init];
        [self yk_displayRoute:landing animated:NO];
        return;
    }
    if (!vault.yk_isDossierReady) {
        YKProfileInfoViewController *profile = [[YKProfileInfoViewController alloc] init];
        profile.yk_firstPassSetup = YES;
        [self yk_displayRoute:profile animated:NO];
        return;
    }
    [self yk_presentMainDeck];
}

+ (void)yk_presentLanding {
    YKLoginChoiceViewController *landing = [[YKLoginChoiceViewController alloc] init];
    [self yk_displayRoute:landing animated:YES];
}

+ (void)yk_presentMainDeck {
    [self yk_displayRoute:[[YKTabBarController alloc] init] animated:YES];
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
        [self yk_displayRoute:profile animated:YES];
    }
}

@end
