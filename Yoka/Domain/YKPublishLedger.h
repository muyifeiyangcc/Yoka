//
//  YKPublishLedger.h
//  Yoka
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// Account-scoped user-published posts (Discover Outfit + Mine Posts).
@interface YKPublishLedger : NSObject

+ (instancetype)sharedLedger;

/// Newest-first posts for one owner (hydrated with absolute imagePath).
- (NSArray<NSDictionary *> *)yk_entriesForOwnerKey:(NSString *)ownerKey;

/// Newest-first union of every owner's published posts.
- (NSArray<NSDictionary *> *)yk_allPublishedEntries;

/// Persist a new post at the front of the owner's list.
- (void)yk_prependEntry:(NSDictionary *)post forOwnerKey:(NSString *)ownerKey;

- (void)yk_eraseEntriesForOwnerKey:(NSString *)ownerKey;

/// Save JPEG under Documents/yoka_atelier_media; returns relative filename.
- (nullable NSString *)yk_storeJPEGImage:(UIImage *)image;

/// Copy a movie into Documents/yoka_atelier_media; returns relative filename.
/// Must be called while the source URL is still valid (e.g. inside PHPicker loadFileRepresentation).
- (nullable NSString *)yk_storeVideoFileAtURL:(NSURL *)url;

/// Remove a previously stored relative media file (image or video).
- (void)yk_deleteRelativeMediaName:(nullable NSString *)name;

+ (nullable UIImage *)yk_coverImageForEntry:(NSDictionary *)post;
+ (nullable UIImage *)yk_goodsImageForItem:(NSDictionary *)item;
+ (nullable NSURL *)yk_videoURLForEntry:(NSDictionary *)post;

@end

NS_ASSUME_NONNULL_END
