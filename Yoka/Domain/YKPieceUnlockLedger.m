//
//  YKPieceUnlockLedger.m
//  Yoka
//

#import "YKPieceUnlockLedger.h"
#import "YKFindFavorLedger.h"
#import "YKRosterVault.h"

@implementation YKPieceUnlockLedger

+ (instancetype)sharedLedger {
    static YKPieceUnlockLedger *ledger = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        ledger = [[YKPieceUnlockLedger alloc] init];
    });
    return ledger;
}

- (NSString *)yk_defaultsKeyForOwner:(NSString *)ownerKey {
    NSString *owner = ownerKey.length > 0 ? ownerKey : ([[YKRosterVault sharedRoster] yk_activeMailbox] ?: @"guest");
    return [NSString stringWithFormat:@"yoka.browse.unlockedPieces.r1.%@", owner];
}

- (NSMutableArray *)yk_mutableKeysForOwner:(NSString *)ownerKey {
    NSArray *saved = [NSUserDefaults.standardUserDefaults arrayForKey:[self yk_defaultsKeyForOwner:ownerKey]];
    return [saved isKindOfClass:NSArray.class] ? [saved mutableCopy] : [NSMutableArray array];
}

- (void)yk_persistKeys:(NSArray *)keys ownerKey:(NSString *)ownerKey {
    [NSUserDefaults.standardUserDefaults setObject:keys forKey:[self yk_defaultsKeyForOwner:ownerKey]];
    [NSUserDefaults.standardUserDefaults synchronize];
}

- (BOOL)yk_ownerKey:(NSString *)ownerKey hasUnlockedEntry:(NSDictionary *)entry {
    NSString *key = [YKFindFavorLedger yk_entryKeyForEntry:entry];
    if (key.length == 0) {
        return NO;
    }
    return [[self yk_mutableKeysForOwner:ownerKey] containsObject:key];
}

- (void)yk_ownerKey:(NSString *)ownerKey markUnlockedEntry:(NSDictionary *)entry {
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

- (void)yk_eraseUnlocksForOwnerKey:(NSString *)ownerKey {
    if (ownerKey.length == 0) {
        return;
    }
    [NSUserDefaults.standardUserDefaults removeObjectForKey:[self yk_defaultsKeyForOwner:ownerKey]];
    [NSUserDefaults.standardUserDefaults synchronize];
}

@end
