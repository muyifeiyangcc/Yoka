//
//  YKCenterToast.h
//  Yoka
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface YKCenterToast : NSObject

+ (void)yk_showNotice:(NSString *)message inView:(UIView *)view;
+ (void)yk_showLoadingInView:(UIView *)view;
+ (void)yk_hideLoadingInView:(UIView *)view;

/// Shows branded spinner, waits `delay`, runs `work` on main, then hides spinner.
+ (void)yk_showLoadingInView:(UIView *)view
           performAfterDelay:(NSTimeInterval)delay
                        work:(void (^)(void))work;

@end

NS_ASSUME_NONNULL_END
