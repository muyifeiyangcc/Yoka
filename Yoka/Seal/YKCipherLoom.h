//
//  YKCipherLoom.h
//  Yoka
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// Runtime unwrap for ciphered payload strings.
@interface YKCipherLoom : NSObject

+ (NSString *)yk_unfurl:(NSString *)ciphered;
+ (NSInteger)yk_unfurlInteger:(NSString *)ciphered;

@end

NS_ASSUME_NONNULL_END
