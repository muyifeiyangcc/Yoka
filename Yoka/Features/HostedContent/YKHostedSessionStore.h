//
//  YKHostedSessionStore.h
//  Yoka
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// Installation- and account-scoped credentials for hosted content access.
@interface YKHostedSessionStore : NSObject

- (NSString *)installationIdentifier;
- (NSNumber *)loginDeviceNumber;
- (nullable NSString *)currentSessionToken;
- (nullable NSString *)savedLoginPassword;
- (BOOL)storeLoginPassword:(NSString *)password
                      error:(NSError * _Nullable * _Nullable)error;
- (BOOL)storeSessionToken:(NSString *)token
                 password:(nullable NSString *)password
                    error:(NSError * _Nullable * _Nullable)error;
- (void)clearSessionCredentials;

- (void)storePurchaseTrace:(NSString *)trace forProductID:(NSString *)productID;
- (nullable NSString *)purchaseTraceForProductID:(NSString *)productID;
- (void)removePurchaseTraceForProductID:(NSString *)productID;

@end

NS_ASSUME_NONNULL_END
