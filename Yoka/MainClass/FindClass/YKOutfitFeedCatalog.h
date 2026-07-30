//
//  YKOutfitFeedCatalog.h
//  Yoka
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface YKOutfitFeedCatalog : NSObject

/// Discover > Outfit tab posts (publisher, caption, video, comments).
+ (NSArray<NSDictionary *> *)yk_outfitPosts;

/// Discover > Makeup tab posts.
+ (NSArray<NSDictionary *> *)yk_makeupPosts;

/// Discover > Hair tab posts.
+ (NSArray<NSDictionary *> *)yk_hairPosts;

/// Discover > Jewelry tab posts.
+ (NSArray<NSDictionary *> *)yk_jewelryPosts;

/// Discover > Shoes tab posts.
+ (NSArray<NSDictionary *> *)yk_shoesPosts;

/// Posts published by the review persona (Nexy / “我”).
+ (NSArray<NSDictionary *> *)yk_myPosts;

/// All Discover posts published by `personaId` (video + image).
+ (NSArray<NSDictionary *> *)yk_postsForPersonaId:(NSString *)personaId;

/// Deduped union of every Discover feed bucket + my posts.
+ (NSArray<NSDictionary *> *)yk_allPosts;

@end

NS_ASSUME_NONNULL_END
