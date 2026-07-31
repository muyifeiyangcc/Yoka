//
//  YKSparkCoffer.h
//  Yoka
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// Per-account spark tally (default 0).
@interface YKSparkCoffer : NSObject

+ (instancetype)sharedCoffer;

- (NSInteger)yk_tallyForOwnerKey:(NSString *)ownerKey;

/// Deducts `amount` when tally is enough. Returns YES on success.
- (BOOL)yk_ownerKey:(NSString *)ownerKey spend:(NSInteger)amount;

/// Credits sparks after a local top-up.
- (void)yk_ownerKey:(NSString *)ownerKey credit:(NSInteger)amount;

@end

NS_ASSUME_NONNULL_END
