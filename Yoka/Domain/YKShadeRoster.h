//
//  YKShadeRoster.h
//  Yoka
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSNotificationName const YokaShadeRosterDidShiftNotification;

/// Per-account block list (Yoka shade roster — not Cubixa blockedPeople).
@interface YKShadeRoster : NSObject

+ (instancetype)sharedRoster;

- (NSArray<NSString *> *)yk_shadedIdsForOwnerKey:(NSString *)ownerKey;
- (BOOL)yk_ownerKey:(NSString *)ownerKey hasShadedId:(NSString *)personaId;
- (void)yk_ownerKey:(NSString *)ownerKey shadeId:(NSString *)personaId;
- (void)yk_ownerKey:(NSString *)ownerKey unshadeId:(NSString *)personaId;

@end

NS_ASSUME_NONNULL_END
