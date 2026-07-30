//
//  YKFindFavorLedger.h
//  Yoka
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// Discover entry favors — yellow/gray star, per account, default-on for linked publishers.
@interface YKFindFavorLedger : NSObject

+ (instancetype)sharedLedger;

+ (NSString *)yk_entryKeyForEntry:(NSDictionary *)entry;

- (NSString *)yk_favoredEntriesDefaultsKey;
- (NSString *)yk_disfavoredEntriesDefaultsKey;

/// Favored if explicitly saved, or publisher is linked (unless explicitly cleared).
- (BOOL)yk_isEntryFavored:(NSDictionary *)entry ownerKey:(NSString *)ownerKey;

- (void)yk_setEntry:(NSDictionary *)entry favored:(BOOL)favored ownerKey:(NSString *)ownerKey;

- (NSArray<NSString *> *)yk_explicitFavoredEntryKeys;

- (NSString *)yk_favoredStarImageName;
- (NSString *)yk_unfavoredStarImageName;

@end

NS_ASSUME_NONNULL_END
