//
//  YKShadeRoster.m
//  Yoka
//

#import "YKShadeRoster.h"

static NSString * const kYKShadeRosterMapKey = @"yoka.shade.rosterByOwner.r1";

NSNotificationName const YokaShadeRosterDidShiftNotification = @"YokaShadeRosterDidShiftNotification";

@implementation YKShadeRoster

+ (instancetype)sharedRoster {
    static YKShadeRoster *roster = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        roster = [[YKShadeRoster alloc] init];
    });
    return roster;
}

- (NSMutableDictionary *)yk_mutableMap {
    NSDictionary *map = [NSUserDefaults.standardUserDefaults dictionaryForKey:kYKShadeRosterMapKey] ?: @{};
    return [map mutableCopy];
}

- (void)yk_persistMap:(NSDictionary *)map {
    [NSUserDefaults.standardUserDefaults setObject:map forKey:kYKShadeRosterMapKey];
    [NSUserDefaults.standardUserDefaults synchronize];
}

- (void)yk_notifyShift {
    [[NSNotificationCenter defaultCenter] postNotificationName:YokaShadeRosterDidShiftNotification object:nil];
}

- (NSArray<NSString *> *)yk_shadedIdsForOwnerKey:(NSString *)ownerKey {
    if (ownerKey.length == 0) {
        return @[];
    }
    NSArray *list = [self yk_mutableMap][ownerKey];
    return [list isKindOfClass:NSArray.class] ? list : @[];
}

- (BOOL)yk_ownerKey:(NSString *)ownerKey hasShadedId:(NSString *)personaId {
    if (personaId.length == 0) {
        return NO;
    }
    return [[self yk_shadedIdsForOwnerKey:ownerKey] containsObject:personaId];
}

- (void)yk_ownerKey:(NSString *)ownerKey shadeId:(NSString *)personaId {
    if (ownerKey.length == 0 || personaId.length == 0) {
        return;
    }
    // Never shade yourself.
    if ([personaId isEqualToString:ownerKey]) {
        return;
    }
    NSMutableDictionary *map = [self yk_mutableMap];
    NSMutableArray *list = [([map[ownerKey] isKindOfClass:NSArray.class] ? map[ownerKey] : @[]) mutableCopy];
    if (![list containsObject:personaId]) {
        [list addObject:personaId];
        map[ownerKey] = list;
        [self yk_persistMap:map];
        [self yk_notifyShift];
    }
}

- (void)yk_ownerKey:(NSString *)ownerKey unshadeId:(NSString *)personaId {
    if (ownerKey.length == 0 || personaId.length == 0) {
        return;
    }
    NSMutableDictionary *map = [self yk_mutableMap];
    NSMutableArray *list = [([map[ownerKey] isKindOfClass:NSArray.class] ? map[ownerKey] : @[]) mutableCopy];
    if (![list containsObject:personaId]) {
        return;
    }
    [list removeObject:personaId];
    map[ownerKey] = list;
    [self yk_persistMap:map];
    [self yk_notifyShift];
}

@end
