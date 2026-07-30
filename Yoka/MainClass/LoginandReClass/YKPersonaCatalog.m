//
//  YKPersonaCatalog.m
//  Yoka
//

#import "YKPersonaCatalog.h"

@implementation YKPersonaCatalog

+ (NSString *)yk_reviewPersonaId {
    return @"nexy";
}

+ (NSString *)yk_reviewPersonaDisplayName {
    return @"Nexy";
}

+ (NSString *)yk_reviewPersonaAvatarAsset {
    return @"avatar_nexy";
}

+ (NSArray<NSDictionary *> *)yk_allPersonas {
    // Avatar asset names match imported imagesets.
    return @[
        @{ @"id": @"nexy",    @"name": @"Nexy",    @"avatar": @"avatar_nexy", @"isTest": @YES },
        @{ @"id": @"zely",    @"name": @"Zely",    @"avatar": @"avatar_zely",    @"isTest": @NO },
        @{ @"id": @"korae",   @"name": @"Korae",   @"avatar": @"avatar_korae",  @"isTest": @NO },
        @{ @"id": @"ellex",   @"name": @"Ellex",   @"avatar": @"avatar_ellex",  @"isTest": @NO },
        @{ @"id": @"orbelle", @"name": @"Orbelle", @"avatar": @"avatar_orbelle", @"isTest": @NO },
        @{ @"id": @"yuvette", @"name": @"Yuvette", @"avatar": @"avatar_yuvette",     @"isTest": @NO },
    ];
}

+ (NSDictionary *)yk_personaWithId:(NSString *)personaId {
    if (personaId.length == 0) {
        return nil;
    }
    for (NSDictionary *persona in [self yk_allPersonas]) {
        if ([persona[@"id"] isEqualToString:personaId]) {
            return persona;
        }
    }
    return nil;
}

+ (UIImage *)yk_avatarImageForPersonaId:(NSString *)personaId {
    NSDictionary *persona = [self yk_personaWithId:personaId];
    NSString *asset = persona[@"avatar"];
    if (![asset isKindOfClass:NSString.class] || asset.length == 0) {
        return nil;
    }
    return [UIImage imageNamed:asset];
}

+ (NSArray<NSString *> *)yk_primeOutboundIdsForReviewPersona {
    // Nexy mutuals for App Review: follows + links-back with these two.
    return @[ @"korae", @"ellex" ];
}

@end
