//
//  YKBootNavigator.h
//  Yoka
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface YKBootNavigator : NSObject

+ (void)yk_attachWindow:(UIWindow *)window;
+ (void)yk_routeColdLaunch;
+ (void)yk_showLandingGate;
+ (void)yk_showMainTabs;
+ (void)yk_advanceAfterAuthFrom:(nullable UINavigationController *)navigationController;

@end

NS_ASSUME_NONNULL_END
