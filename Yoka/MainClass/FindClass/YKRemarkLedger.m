//
//  YKRemarkLedger.m
//  Yoka
//

#import "YKRemarkLedger.h"

static NSString * const kYKRemarkMapKey = @"yoka.remark.byOwnerPost.r1";

@implementation YKRemarkLedger

+ (instancetype)sharedLedger {
    static YKRemarkLedger *ledger = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        ledger = [[YKRemarkLedger alloc] init];
    });
    return ledger;
}

- (NSMutableDictionary *)yk_mutableMap {
    NSDictionary *map = [NSUserDefaults.standardUserDefaults dictionaryForKey:kYKRemarkMapKey] ?: @{};
    return [map mutableCopy];
}

- (void)yk_persistMap:(NSDictionary *)map {
    [NSUserDefaults.standardUserDefaults setObject:map forKey:kYKRemarkMapKey];
    [NSUserDefaults.standardUserDefaults synchronize];
}

- (NSArray<NSDictionary *> *)yk_localRemarksForOwnerKey:(NSString *)ownerKey postKey:(NSString *)postKey {
    if (ownerKey.length == 0 || postKey.length == 0) {
        return @[];
    }
    NSDictionary *byPost = self.yk_mutableMap[ownerKey];
    if (![byPost isKindOfClass:NSDictionary.class]) {
        return @[];
    }
    NSArray *list = byPost[postKey];
    return [list isKindOfClass:NSArray.class] ? list : @[];
}

- (NSArray<NSDictionary *> *)yk_remarksForOwnerKey:(NSString *)ownerKey
                                           postKey:(NSString *)postKey
                                      catalogRemarks:(NSArray *)catalogBundle {
    NSMutableArray *merged = [NSMutableArray array];
    if ([catalogBundle isKindOfClass:NSArray.class]) {
        for (NSDictionary *item in catalogBundle) {
            if ([item isKindOfClass:NSDictionary.class]) {
                [merged addObject:item];
            }
        }
    }
    [merged addObjectsFromArray:[self yk_localRemarksForOwnerKey:ownerKey postKey:postKey]];
    return merged;
}

- (void)yk_ownerKey:(NSString *)ownerKey appendRemark:(NSDictionary *)remark forEntryKey:(NSString *)postKey {
    if (ownerKey.length == 0 || postKey.length == 0 || ![remark isKindOfClass:NSDictionary.class]) {
        return;
    }
    NSMutableDictionary *map = [self yk_mutableMap];
    NSMutableDictionary *byPost = [([map[ownerKey] isKindOfClass:NSDictionary.class] ? map[ownerKey] : @{}) mutableCopy];
    NSMutableArray *list = [([byPost[postKey] isKindOfClass:NSArray.class] ? byPost[postKey] : @[]) mutableCopy];
    [list addObject:remark];
    byPost[postKey] = list;
    map[ownerKey] = byPost;
    [self yk_persistMap:map];
}

@end
