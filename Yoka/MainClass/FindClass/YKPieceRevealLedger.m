//
//  YKPieceRevealLedger.m
//  Yoka
//

#import "YKPieceRevealLedger.h"
#import "YKFindFavorLedger.h"
#import "../LoginandReClass/YKAccountVault.h"

@implementation YKPieceRevealLedger

+ (instancetype)sharedLedger {
    static YKPieceRevealLedger *ledger = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        ledger = [[YKPieceRevealLedger alloc] init];
    });
    return ledger;
}

- (NSString *)yk_defaultsKeyForOwner:(NSString *)ownerKey {
    NSString *owner = ownerKey.length > 0 ? ownerKey : ([[YKAccountVault sharedVault] yk_activeMailbox] ?: @"guest");
    return [NSString stringWithFormat:@"yk.piece.revealedEntries.r1.%@", owner];
}

- (NSMutableArray *)yk_mutableKeysForOwner:(NSString *)ownerKey {
    NSArray *saved = [NSUserDefaults.standardUserDefaults arrayForKey:[self yk_defaultsKeyForOwner:ownerKey]];
    return [saved isKindOfClass:NSArray.class] ? [saved mutableCopy] : [NSMutableArray array];
}

- (void)yk_persistKeys:(NSArray *)keys ownerKey:(NSString *)ownerKey {
    [NSUserDefaults.standardUserDefaults setObject:keys forKey:[self yk_defaultsKeyForOwner:ownerKey]];
    [NSUserDefaults.standardUserDefaults synchronize];
}

- (BOOL)yk_ownerKey:(NSString *)ownerKey hasRevealedEntry:(NSDictionary *)entry {
    NSString *key = [YKFindFavorLedger yk_entryKeyForEntry:entry];
    if (key.length == 0) {
        return NO;
    }
    return [[self yk_mutableKeysForOwner:ownerKey] containsObject:key];
}

- (void)yk_ownerKey:(NSString *)ownerKey markRevealedEntry:(NSDictionary *)entry {
    NSString *key = [YKFindFavorLedger yk_entryKeyForEntry:entry];
    if (key.length == 0) {
        return;
    }
    NSMutableArray *keys = [self yk_mutableKeysForOwner:ownerKey];
    if ([keys containsObject:key]) {
        return;
    }
    [keys addObject:key];
    [self yk_persistKeys:keys ownerKey:ownerKey];
}

- (void)yk_eraseRevealsForOwnerKey:(NSString *)ownerKey {
    if (ownerKey.length == 0) {
        return;
    }
    [NSUserDefaults.standardUserDefaults removeObjectForKey:[self yk_defaultsKeyForOwner:ownerKey]];
    [NSUserDefaults.standardUserDefaults synchronize];
}

@end
