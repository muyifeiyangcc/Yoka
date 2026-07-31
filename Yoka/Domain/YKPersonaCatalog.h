//
//  YKPersonaCatalog.h
//  Yoka
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// Fixed local cast for this app. “我 / my …” in product talk = Nexy (review persona).
@interface YKPersonaCatalog : NSObject

+ (NSString *)yk_reviewPersonaId;          // Nexy
+ (NSString *)yk_reviewPersonaDisplayName; // Nexy
+ (NSString *)yk_reviewPersonaAvatarAsset; // avatar_nexy

+ (NSArray<NSDictionary *> *)yk_allPersonas;
+ (nullable NSDictionary *)yk_personaWithId:(NSString *)personaId;
+ (nullable UIImage *)yk_avatarImageForPersonaId:(NSString *)personaId;
+ (NSArray<NSString *> *)yk_primeOutboundIdsForReviewPersona;

@end

NS_ASSUME_NONNULL_END
