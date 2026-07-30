//
//  YKBondLedger.m
//  Yoka
//

#import "YKBondLedger.h"
#import "YKPersonaCatalog.h"
#import "YKAccountVault.h"

static NSString * const kYKBondOutboundMapKey = @"yoka.bond.outboundByOwner.r1";
static NSString * const kYKBondLinksBackMapKey = @"yoka.bond.linksBackByOwner.r1";
static NSString * const kYKBondPrimedOwnersKey = @"yoka.bond.primedOwners.r2";

@implementation YKBondLedger

+ (instancetype)sharedLedger {
    static YKBondLedger *ledger = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        ledger = [[YKBondLedger alloc] init];
    });
    return ledger;
}

- (NSUserDefaults *)yk_defaults {
    return NSUserDefaults.standardUserDefaults;
}

- (NSMutableDictionary *)yk_mutableOutboundMap {
    NSDictionary *map = [self.yk_defaults dictionaryForKey:kYKBondOutboundMapKey] ?: @{};
    return [map mutableCopy];
}

- (void)yk_persistOutboundMap:(NSDictionary *)map {
    [self.yk_defaults setObject:map forKey:kYKBondOutboundMapKey];
    [self.yk_defaults synchronize];
}

- (NSMutableDictionary *)yk_mutableLinksBackMap {
    NSDictionary *map = [self.yk_defaults dictionaryForKey:kYKBondLinksBackMapKey] ?: @{};
    return [map mutableCopy];
}

- (void)yk_persistLinksBackMap:(NSDictionary *)map {
    [self.yk_defaults setObject:map forKey:kYKBondLinksBackMapKey];
    [self.yk_defaults synchronize];
}

- (NSMutableSet *)yk_primedOwners {
    NSArray *list = [self.yk_defaults arrayForKey:kYKBondPrimedOwnersKey] ?: @[];
    return [NSMutableSet setWithArray:list];
}

- (void)yk_persistPrimedOwners:(NSSet *)owners {
    [self.yk_defaults setObject:owners.allObjects forKey:kYKBondPrimedOwnersKey];
    [self.yk_defaults synchronize];
}

- (BOOL)yk_shouldPrimeOwnerKey:(NSString *)ownerKey {
    NSString *mailbox = [YKAccountVault sharedVault].yk_activeMailbox;
    BOOL isReview = [YKAccountVault yk_isReviewMailbox:mailbox ?: @""];
    BOOL isNexyKey = [ownerKey isEqualToString:[YKPersonaCatalog yk_reviewPersonaId]];
    return isReview || isNexyKey;
}

- (void)yk_primeLinksForOwnerKey:(NSString *)ownerKey {
    if (ownerKey.length == 0) {
        return;
    }
    if (![self yk_shouldPrimeOwnerKey:ownerKey]) {
        return;
    }

    NSMutableSet *primed = [self yk_primedOwners];
    if ([primed containsObject:ownerKey]) {
        // Older installs may have following without links-back — repair mutuals.
        NSMutableDictionary *linksBack = [self yk_mutableLinksBackMap];
        NSArray *existing = linksBack[ownerKey];
        if (![existing isKindOfClass:NSArray.class] || existing.count == 0) {
            linksBack[ownerKey] = [YKPersonaCatalog yk_primeOutboundIdsForReviewPersona];
            [self yk_persistLinksBackMap:linksBack];
        }
        return;
    }

    NSArray *primeIds = [YKPersonaCatalog yk_primeOutboundIdsForReviewPersona];
    NSMutableDictionary *outboundMap = [self yk_mutableOutboundMap];
    outboundMap[ownerKey] = primeIds;
    [self yk_persistOutboundMap:outboundMap];

    // Twin: Korae + Ellex also link the review persona back.
    NSMutableDictionary *linksBack = [self yk_mutableLinksBackMap];
    linksBack[ownerKey] = primeIds;
    [self yk_persistLinksBackMap:linksBack];

    [primed addObject:ownerKey];
    [self yk_persistPrimedOwners:primed];
}

- (NSArray<NSString *> *)yk_outboundIdsForOwnerKey:(NSString *)ownerKey {
    [self yk_primeLinksForOwnerKey:ownerKey];
    NSArray *list = self.yk_mutableOutboundMap[ownerKey];
    return [list isKindOfClass:NSArray.class] ? list : @[];
}

- (NSArray<NSString *> *)yk_inboundIdsForOwnerKey:(NSString *)ownerKey {
    [self yk_primeLinksForOwnerKey:ownerKey];
    NSArray *list = self.yk_mutableLinksBackMap[ownerKey];
    return [list isKindOfClass:NSArray.class] ? list : @[];
}

- (NSArray<NSString *> *)yk_twinIdsForOwnerKey:(NSString *)ownerKey {
    NSArray *outbound = [self yk_outboundIdsForOwnerKey:ownerKey];
    NSArray *inbound = [self yk_inboundIdsForOwnerKey:ownerKey];
    NSMutableArray *twins = [NSMutableArray array];
    for (NSString *personaId in outbound) {
        if ([inbound containsObject:personaId]) {
            [twins addObject:personaId];
        }
    }
    return twins;
}

- (BOOL)yk_ownerKey:(NSString *)ownerKey isLinkedTo:(NSString *)personaId {
    if (personaId.length == 0) {
        return NO;
    }
    return [[self yk_outboundIdsForOwnerKey:ownerKey] containsObject:personaId];
}

- (BOOL)yk_ownerKey:(NSString *)ownerKey isTwinWith:(NSString *)personaId {
    if (personaId.length == 0) {
        return NO;
    }
    return [[self yk_twinIdsForOwnerKey:ownerKey] containsObject:personaId];
}

- (void)yk_ownerKey:(NSString *)ownerKey setLink:(NSString *)personaId on:(BOOL)on {
    if (ownerKey.length == 0 || personaId.length == 0) {
        return;
    }
    [self yk_primeLinksForOwnerKey:ownerKey];
    NSMutableDictionary *map = [self yk_mutableOutboundMap];
    NSMutableArray *list = [([map[ownerKey] isKindOfClass:NSArray.class] ? map[ownerKey] : @[]) mutableCopy];
    if (on) {
        if (![list containsObject:personaId]) {
            [list addObject:personaId];
        }
    } else {
        [list removeObject:personaId];
    }
    map[ownerKey] = list;
    [self yk_persistOutboundMap:map];
}

@end
