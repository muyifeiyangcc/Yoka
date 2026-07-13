//
//  YKNavigationController.m
//  Yoka
//

#import "YKNavigationController.h"
#import "YKTabBarController.h"

@interface YKNavigationController () <UINavigationControllerDelegate>

@end

@implementation YKNavigationController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.delegate = self;
    self.navigationBarHidden = YES;
    self.interactivePopGestureRecognizer.delegate = nil;
}

- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated {
    [(YKTabBarController *)self.tabBarController hideSystemTabBarImmediately];
    if (self.viewControllers.count > 0) {
        [(YKTabBarController *)self.tabBarController setCustomTabBarHidden:YES animated:animated];
    }
    [super pushViewController:viewController animated:animated];
}

- (UIViewController *)childViewControllerForStatusBarStyle {
    return self.topViewController;
}

- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated {
    [navigationController setNavigationBarHidden:YES animated:animated];
    [(YKTabBarController *)navigationController.tabBarController hideSystemTabBarImmediately];
    BOOL isRootViewController = (viewController == navigationController.viewControllers.firstObject);
    [(YKTabBarController *)navigationController.tabBarController setCustomTabBarHidden:!isRootViewController animated:animated];
}

- (void)navigationController:(UINavigationController *)navigationController didShowViewController:(UIViewController *)viewController animated:(BOOL)animated {
    [(YKTabBarController *)navigationController.tabBarController hideSystemTabBarImmediately];
}

@end
