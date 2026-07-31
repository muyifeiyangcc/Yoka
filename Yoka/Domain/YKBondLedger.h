//
//  YKBondLedger.h
//  Yoka
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// Per-account link edges. Review persona primes twin links to Korae + Ellex.
@interface YKBondLedger : NSObject

+ (instancetype)sharedLedger;

- (void)yk_primeLinksForOwnerKey:(NSString *)ownerKey;
- (NSArray<NSString *> *)yk_outboundIdsForOwnerKey:(NSString *)ownerKey;
- (NSArray<NSString *> *)yk_inboundIdsForOwnerKey:(NSString *)ownerKey;
- (NSArray<NSString *> *)yk_twinIdsForOwnerKey:(NSString *)ownerKey;
- (BOOL)yk_ownerKey:(NSString *)ownerKey isLinkedTo:(NSString *)personaId;
- (BOOL)yk_ownerKey:(NSString *)ownerKey isTwinWith:(NSString *)personaId;
- (void)yk_ownerKey:(NSString *)ownerKey setLink:(NSString *)personaId on:(BOOL)on;

@end

NS_ASSUME_NONNULL_END
