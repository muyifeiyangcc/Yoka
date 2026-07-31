//
//  YKTabBarController.m
//  Yoka
//

#import "YKTabBarController.h"
#import "YKCustomTabBarView.h"
#import "YKNavigationController.h"
#import "YKHomeViewController.h"
#import "YKFindViewController.h"
#import "YKInboxViewController.h"
#import "YKMineViewController.h"
#import "YKPublicPublishViewController.h"
#import "YKCipherLoom.h"

@interface YKTabBarController () <YKCustomTabBarViewDelegate>

@property (nonatomic, strong) YKCustomTabBarView *customTabBarView;
@property (nonatomic, strong) NSLayoutConstraint *customTabBarHeightConstraint;

@end

@implementation YKTabBarController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self yk_setupViewControllers];
    [self yk_setupCustomTabBar];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    [self yk_hideSystemTabBar];
    [self yk_updateCustomTabBarHeight];
    [self.view bringSubviewToFront:self.customTabBarView];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    [self yk_hideSystemTabBar];
}

- (void)yk_setupViewControllers {
    YKHomeViewController *home = [[YKHomeViewController alloc] init];
    YKFindViewController *find = [[YKFindViewController alloc] init];
    YKInboxViewController *message = [[YKInboxViewController alloc] init];
    YKMineViewController *mine = [[YKMineViewController alloc] init];

    self.viewControllers = @[
        [self yk_navigationControllerWithRootViewController:home
                                                      title:@"Home"
                                                normalImage:@"tab_home_normal"
                                              selectedImage:@"tab_home_selected"],
        [self yk_navigationControllerWithRootViewController:find
                                                      title:@"Discover"
                                                normalImage:@"tab_discover_normal"
                                              selectedImage:@"tab_discover_selected"],
        [self yk_navigationControllerWithRootViewController:message
                                                      title:[YKCipherLoom yk_unfurl:@"EIDKmIiJFebfyrc8Gz4XSg=="]
                                                normalImage:@"tab_inbox_normal"
                                              selectedImage:@"tab_inbox_selected"],
        [self yk_navigationControllerWithRootViewController:mine
                                                      title:@"Mine"
                                                normalImage:@"tab_mine_normal"
                                              selectedImage:@"tab_mine_selected"]
    ];
}

- (void)yk_setupCustomTabBar {
    [self yk_hideSystemTabBar];

    YKCustomTabBarView *customTabBarView = [[YKCustomTabBarView alloc] init];
    customTabBarView.delegate = self;
    customTabBarView.selectedIndex = self.selectedIndex;
    [self.view addSubview:customTabBarView];
    self.customTabBarView = customTabBarView;

    NSLayoutConstraint *heightConstraint = [customTabBarView.heightAnchor constraintEqualToConstant:CGRectGetHeight(self.tabBar.bounds)];
    self.customTabBarHeightConstraint = heightConstraint;

    [NSLayoutConstraint activateConstraints:@[
        [customTabBarView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [customTabBarView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [customTabBarView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
        heightConstraint
    ]];
}

- (void)yk_hideSystemTabBar {
    self.tabBar.hidden = YES;
    self.tabBar.alpha = 0.0;
    self.tabBar.userInteractionEnabled = NO;
    self.tabBar.translucent = YES;
    self.tabBar.backgroundImage = [UIImage new];
    self.tabBar.shadowImage = [UIImage new];
    CGRect tabBarFrame = self.tabBar.frame;
    tabBarFrame.origin.y = CGRectGetHeight(self.view.bounds);
    tabBarFrame.size.height = 0.0;
    self.tabBar.frame = tabBarFrame;
    [self.view sendSubviewToBack:self.tabBar];
}

- (void)hideSystemTabBarImmediately {
    [self yk_hideSystemTabBar];
}

- (void)yk_updateCustomTabBarHeight {
    CGFloat tabBarHeight = CGRectGetHeight(self.tabBar.bounds);
    if (tabBarHeight <= 0) {
        tabBarHeight = 49.0 + self.view.safeAreaInsets.bottom;
    }
    self.customTabBarHeightConstraint.constant = tabBarHeight;
}

- (YKNavigationController *)yk_navigationControllerWithRootViewController:(UIViewController *)rootViewController
                                                                    title:(NSString *)title
                                                              normalImage:(NSString *)normalImage
                                                            selectedImage:(NSString *)selectedImage {
    UIImage *normal = [[UIImage imageNamed:normalImage] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    UIImage *selected = [[UIImage imageNamed:selectedImage] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    rootViewController.tabBarItem = [[UITabBarItem alloc] initWithTitle:nil image:normal selectedImage:selected];
    rootViewController.tabBarItem.accessibilityLabel = title;
    rootViewController.tabBarItem.imageInsets = UIEdgeInsetsMake(6.0, 0, -6.0, 0);
    return [[YKNavigationController alloc] initWithRootViewController:rootViewController];
}

- (void)setSelectedIndex:(NSUInteger)selectedIndex {
    [super setSelectedIndex:selectedIndex];
    self.customTabBarView.selectedIndex = selectedIndex;
}

- (void)customTabBarView:(YKCustomTabBarView *)tabBarView didSelectIndex:(NSInteger)index {
    if (self.selectedIndex == index) {
        return;
    }

    [UIView performWithoutAnimation:^{
        self.selectedIndex = index;
        self.customTabBarView.selectedIndex = index;
        [self.view bringSubviewToFront:self.customTabBarView];
        [self.view layoutIfNeeded];
    }];
}

- (void)customTabBarViewDidTapPublish:(YKCustomTabBarView *)tabBarView {
    YKPublicPublishViewController *postViewController = [[YKPublicPublishViewController alloc] init];
    UIViewController *selectedViewController = self.selectedViewController;
    if ([selectedViewController isKindOfClass:UINavigationController.class]) {
        [(UINavigationController *)selectedViewController pushViewController:postViewController animated:YES];
    }
}

- (void)setCustomTabBarHidden:(BOOL)hidden animated:(BOOL)animated {
    [self yk_hideSystemTabBar];
    self.customTabBarView.alpha = 1.0;
    self.customTabBarView.transform = CGAffineTransformIdentity;
    self.customTabBarView.hidden = hidden;
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

@end
