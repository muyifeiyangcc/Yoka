//
//  YKLegalAckVault.h
//  Yoka
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface YKLegalAckVault : NSObject

+ (BOOL)yk_hasAcceptedLicense;
+ (void)yk_markLicenseAccepted;

@end

NS_ASSUME_NONNULL_END
