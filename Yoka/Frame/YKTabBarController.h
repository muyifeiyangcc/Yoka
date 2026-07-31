//
//  YKTabBarController.h
//  Yoka
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface YKTabBarController : UITabBarController

- (void)setCustomTabBarHidden:(BOOL)hidden animated:(BOOL)animated;
- (void)hideSystemTabBarImmediately;

@end

NS_ASSUME_NONNULL_END
