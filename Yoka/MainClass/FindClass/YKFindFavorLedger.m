//
//  YKFindFavorLedger.m
//  Yoka
//

#import "YKFindFavorLedger.h"
#import "../LoginandReClass/YKAccountVault.h"
#import "../LoginandReClass/YKBondLedger.h"
#import "../LoginandReClass/YKPersonaCatalog.h"

@implementation YKFindFavorLedger

+ (instancetype)sharedLedger {
    static YKFindFavorLedger *ledger = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        ledger = [[YKFindFavorLedger alloc] init];
    });
    return ledger;
}

+ (NSString *)yk_entryKeyForEntry:(NSDictionary *)post {
    if (![post isKindOfClass:NSDictionary.class]) {
        return @"name:Yoka";
    }
    NSString *postId = post[@"entryId"];
    if ([postId isKindOfClass:NSString.class] && postId.length > 0) {
        return [NSString stringWithFormat:@"id:%@", postId];
    }
    NSString *video = post[@"video"];
    if ([video isKindOfClass:NSString.class] && video.length > 0) {
        return [NSString stringWithFormat:@"video:%@", video];
    }
    NSString *image = post[@"image"];
    if ([image isKindOfClass:NSString.class] && image.length > 0) {
        return [NSString stringWithFormat:@"image:%@", image];
    }
    NSString *imagePath = post[@"imagePath"];
    if ([imagePath isKindOfClass:NSString.class] && imagePath.length > 0) {
        return [NSString stringWithFormat:@"path:%@", imagePath.lastPathComponent];
    }
    NSString *imageFile = post[@"imageFile"];
    if ([imageFile isKindOfClass:NSString.class] && imageFile.length > 0) {
        return [NSString stringWithFormat:@"path:%@", imageFile];
    }
    NSString *name = post[@"name"];
    return [NSString stringWithFormat:@"name:%@", name.length > 0 ? name : @"Yoka"];
}

- (NSString *)yk_favoredEntriesDefaultsKeyForOwner:(NSString *)ownerKey {
    NSString *owner = ownerKey.length > 0 ? ownerKey : ([[YKAccountVault sharedVault] yk_activeMailbox] ?: @"guest");
    return [NSString stringWithFormat:@"yk.find.favoredEntries.r2.%@", owner];
}

- (NSString *)yk_disfavoredEntriesDefaultsKeyForOwner:(NSString *)ownerKey {
    NSString *owner = ownerKey.length > 0 ? ownerKey : ([[YKAccountVault sharedVault] yk_activeMailbox] ?: @"guest");
    return [NSString stringWithFormat:@"yk.find.disfavoredEntries.r2.%@", owner];
}

- (NSString *)yk_favoredEntriesDefaultsKey {
    return [self yk_favoredEntriesDefaultsKeyForOwner:nil];
}

- (NSString *)yk_disfavoredEntriesDefaultsKey {
    return [self yk_disfavoredEntriesDefaultsKeyForOwner:nil];
}

- (NSMutableArray *)yk_mutableKeysForDefaultsKey:(NSString *)defaultsKey {
    NSArray *saved = [NSUserDefaults.standardUserDefaults arrayForKey:defaultsKey];
    return [saved isKindOfClass:NSArray.class] ? [saved mutableCopy] : [NSMutableArray array];
}

- (void)yk_persistKeys:(NSArray *)keys forDefaultsKey:(NSString *)defaultsKey {
    [NSUserDefaults.standardUserDefaults setObject:keys forKey:defaultsKey];
    [NSUserDefaults.standardUserDefaults synchronize];
}

- (BOOL)yk_isEntryFavored:(NSDictionary *)post ownerKey:(NSString *)ownerKey {
    NSString *postKey = [YKFindFavorLedger yk_entryKeyForEntry:post];
    NSString *likedKey = [self yk_favoredEntriesDefaultsKeyForOwner:ownerKey];
    NSString *dislikedKey = [self yk_disfavoredEntriesDefaultsKeyForOwner:ownerKey];
    if ([[self yk_mutableKeysForDefaultsKey:likedKey] containsObject:postKey]) {
        return YES;
    }
    if ([[self yk_mutableKeysForDefaultsKey:dislikedKey] containsObject:postKey]) {
        return NO;
    }
    NSString *publisherId = [post[@"personaId"] isKindOfClass:NSString.class] ? post[@"personaId"] : @"";
    if (publisherId.length == 0 || ownerKey.length == 0) {
        return NO;
    }
    return [[YKBondLedger sharedLedger] yk_ownerKey:ownerKey isLinkedTo:publisherId];
}

- (void)yk_setEntry:(NSDictionary *)post favored:(BOOL)favored ownerKey:(NSString *)ownerKey {
    NSString *postKey = [YKFindFavorLedger yk_entryKeyForEntry:post];
    NSString *favoredDefaults = [self yk_favoredEntriesDefaultsKeyForOwner:ownerKey];
    NSString *clearedDefaults = [self yk_disfavoredEntriesDefaultsKeyForOwner:ownerKey];
    NSMutableArray *favoredKeys = [self yk_mutableKeysForDefaultsKey:favoredDefaults];
    NSMutableArray *clearedKeys = [self yk_mutableKeysForDefaultsKey:clearedDefaults];
    if (favored) {
        if (![favoredKeys containsObject:postKey]) {
            [favoredKeys addObject:postKey];
        }
        [clearedKeys removeObject:postKey];
    } else {
        [favoredKeys removeObject:postKey];
        if (![clearedKeys containsObject:postKey]) {
            [clearedKeys addObject:postKey];
        }
    }
    [self yk_persistKeys:favoredKeys forDefaultsKey:favoredDefaults];
    [self yk_persistKeys:clearedKeys forDefaultsKey:clearedDefaults];
}

- (NSArray<NSString *> *)yk_explicitFavoredEntryKeys {
    NSString *owner = nil;
    YKAccountVault *vault = [YKAccountVault sharedVault];
    if ([YKAccountVault yk_isReviewMailbox:vault.yk_activeMailbox ?: @""]) {
        owner = [YKPersonaCatalog yk_reviewPersonaId];
    } else {
        owner = vault.yk_activeMailbox.length > 0 ? vault.yk_activeMailbox : @"guest";
    }
    return [[self yk_mutableKeysForDefaultsKey:[self yk_favoredEntriesDefaultsKeyForOwner:owner]] copy];
}

- (NSString *)yk_favoredStarImageName {
    return @"favor_mark_on";
}

- (NSString *)yk_unfavoredStarImageName {
    return @"favor_mark_off";
}

@end
