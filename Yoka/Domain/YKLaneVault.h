//
//  YKLaneVault.h
//  Yoka
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSNotificationName const YokaLaneLinesDidShiftNotification;

/// Local 1:1 lane lines keyed by owner + peer. Owner-scoped lane transcript store.
@interface YKLaneVault : NSObject

+ (instancetype)sharedVault;

- (void)yk_seedReviewLinesForOwnerKey:(NSString *)ownerKey;
- (NSArray<NSDictionary *> *)yk_linesForOwnerKey:(NSString *)ownerKey peerId:(NSString *)peerId;
- (nullable NSDictionary *)yk_previewForOwnerKey:(NSString *)ownerKey peerId:(NSString *)peerId;
- (void)yk_ownerKey:(NSString *)ownerKey
             peerId:(NSString *)peerId
         appendLine:(NSDictionary *)line;

/// Documents/yoka_lane_media — relative file names only in line dicts.
- (NSString *)yk_voiceDirectoryPath;
- (nullable NSString *)yk_absolutePathForVoiceFile:(NSString *)fileName;
/// Copies recorded bytes; returns relative file name for the line dict.
- (nullable NSString *)yk_storeVoiceFileFromPath:(NSString *)tempPath;

@end

NS_ASSUME_NONNULL_END
