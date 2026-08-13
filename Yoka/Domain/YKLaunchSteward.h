//
//  YKLaunchSteward.h
//  Yoka
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface YKLaunchSteward : NSObject

+ (void)yk_bindWindow:(UIWindow *)window;
+ (void)yk_beginArrival;
+ (void)yk_restoreMemberPlace;
+ (void)yk_presentLanding;
+ (void)yk_presentMainDeck;
+ (void)yk_proceedPastCredentialFrom:(nullable UINavigationController *)navigationController;

@end

NS_ASSUME_NONNULL_END
