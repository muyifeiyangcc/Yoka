//
//  YKPieceRevealLedger.h
//  Yoka
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// Per-account permanent item-list reveals (once paid, forever free to open).
@interface YKPieceRevealLedger : NSObject

+ (instancetype)sharedLedger;

- (BOOL)yk_ownerKey:(NSString *)ownerKey hasRevealedEntry:(NSDictionary *)entry;
- (void)yk_ownerKey:(NSString *)ownerKey markRevealedEntry:(NSDictionary *)entry;
- (void)yk_eraseRevealsForOwnerKey:(NSString *)ownerKey;

@end

NS_ASSUME_NONNULL_END
