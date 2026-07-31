//
//  YKPieceUnlockLedger.h
//  Yoka
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// Per-account permanent item-list unlocks (once paid, forever free to open).
@interface YKPieceUnlockLedger : NSObject

+ (instancetype)sharedLedger;

- (BOOL)yk_ownerKey:(NSString *)ownerKey hasUnlockedEntry:(NSDictionary *)entry;
- (void)yk_ownerKey:(NSString *)ownerKey markUnlockedEntry:(NSDictionary *)entry;
- (void)yk_eraseUnlocksForOwnerKey:(NSString *)ownerKey;

@end

NS_ASSUME_NONNULL_END
