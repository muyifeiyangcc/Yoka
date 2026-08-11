//
//  YKGrowthSignal.h
//  Yoka
//

#import <Foundation/Foundation.h>

@class UIApplication;

NS_ASSUME_NONNULL_BEGIN

@interface YKGrowthSignal : NSObject

+ (void)yk_activateForApplication:(UIApplication *)application
                    launchOptions:(nullable NSDictionary *)launchOptions;
+ (void)yk_recordActiveSession;
+ (void)yk_forwardRemoteDeviceToken:(NSData *)deviceToken;
+ (void)yk_recordStoreEntry:(nullable NSString *)reference
                       item:(nullable NSString *)item
                     amount:(nullable NSDecimalNumber *)amount
                   currency:(nullable NSString *)currency;

@end

NS_ASSUME_NONNULL_END
