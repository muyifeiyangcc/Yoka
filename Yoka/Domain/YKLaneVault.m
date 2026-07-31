//
//  YKLaneVault.m
//  Yoka
//

#import "YKLaneVault.h"
#import "YKRosterVault.h"
#import "YKPersonaCatalog.h"

NSNotificationName const YokaLaneLinesDidShiftNotification = @"YokaLaneLinesDidShiftNotification";

static NSString * const kYKLaneLinesMapKey = @"yoka.lane.linesByOwnerPeer.r1";
static NSString * const kYKLanePrimedOwnersKey = @"yoka.lane.primedOwners.r1";

@implementation YKLaneVault

+ (instancetype)sharedVault {
    static YKLaneVault *vault = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        vault = [[YKLaneVault alloc] init];
    });
    return vault;
}

- (NSUserDefaults *)yk_defaults {
    return NSUserDefaults.standardUserDefaults;
}

- (NSMutableDictionary *)yk_mutableLinesMap {
    NSDictionary *map = [self.yk_defaults dictionaryForKey:kYKLaneLinesMapKey] ?: @{};
    return [map mutableCopy];
}

- (void)yk_persistLinesMap:(NSDictionary *)map {
    [self.yk_defaults setObject:map forKey:kYKLaneLinesMapKey];
    [self.yk_defaults synchronize];
    [[NSNotificationCenter defaultCenter] postNotificationName:YokaLaneLinesDidShiftNotification object:nil];
}

- (NSString *)yk_compositeKeyOwner:(NSString *)ownerKey peer:(NSString *)peerId {
    return [NSString stringWithFormat:@"%@::%@", ownerKey ?: @"", peerId ?: @""];
}

- (void)yk_seedReviewLinesForOwnerKey:(NSString *)ownerKey {
    if (ownerKey.length == 0) {
        return;
    }
    NSString *mailbox = [YKRosterVault sharedRoster].yk_activeMailbox;
    BOOL isReview = [YKRosterVault yk_isReviewMailbox:mailbox ?: @""];
    BOOL isNexy = [ownerKey isEqualToString:[YKPersonaCatalog yk_reviewPersonaId]];
    if (!isReview && !isNexy) {
        return;
    }

    NSArray *primed = [self.yk_defaults arrayForKey:kYKLanePrimedOwnersKey] ?: @[];
    if ([primed containsObject:ownerKey]) {
        return;
    }

    NSTimeInterval now = [[NSDate date] timeIntervalSince1970];
    // Reviewer-facing primed threads — keep talk on Yoka outfit / Y2K styling.
    NSArray *koraeLines = @[
        @{
            @"heading": @"inbound",
            @"kind": @"text",
            @"stamp": @(now - 3600.0),
            @"body": @"Just saw your Outfit post on Yoka — that metallic jacket is so Y2K."
        },
        @{
            @"heading": @"outbound",
            @"kind": @"text",
            @"stamp": @(now - 3400.0),
            @"body": @"Thanks! I tagged the pieces under View Items if you want the look."
        }
    ];
    NSArray *ellexLines = @[
        @{
            @"heading": @"inbound",
            @"kind": @"text",
            @"stamp": @(now - 1800.0),
            @"body": @"Your Makeup tab look with the glossy lips is perfect for CCD flash."
        },
        @{
            @"heading": @"outbound",
            @"kind": @"text",
            @"stamp": @(now - 1600.0),
            @"body": @"Love that! Let's match a Hair + Jewelry combo on Yoka next."
        }
    ];

    NSMutableDictionary *map = [self yk_mutableLinesMap];
    map[[self yk_compositeKeyOwner:ownerKey peer:@"korae"]] = koraeLines;
    map[[self yk_compositeKeyOwner:ownerKey peer:@"ellex"]] = ellexLines;
    [self yk_persistLinesMap:map];

    NSMutableArray *nextPrimed = [primed mutableCopy];
    [nextPrimed addObject:ownerKey];
    [self.yk_defaults setObject:nextPrimed forKey:kYKLanePrimedOwnersKey];
    [self.yk_defaults synchronize];
}

- (NSArray<NSDictionary *> *)yk_linesForOwnerKey:(NSString *)ownerKey peerId:(NSString *)peerId {
    if (ownerKey.length == 0 || peerId.length == 0) {
        return @[];
    }
    [self yk_seedReviewLinesForOwnerKey:ownerKey];
    NSArray *lines = self.yk_mutableLinesMap[[self yk_compositeKeyOwner:ownerKey peer:peerId]];
    return [lines isKindOfClass:NSArray.class] ? lines : @[];
}

- (NSDictionary *)yk_previewForOwnerKey:(NSString *)ownerKey peerId:(NSString *)peerId {
    NSArray *lines = [self yk_linesForOwnerKey:ownerKey peerId:peerId];
    NSDictionary *last = lines.lastObject;
    if (![last isKindOfClass:NSDictionary.class]) {
        return nil;
    }
    NSString *kind = last[@"kind"] ?: @"text";
    NSString *preview = @"";
    if ([kind isEqualToString:@"image"]) {
        preview = @"[Photo]";
    } else if ([kind isEqualToString:@"voice"]) {
        NSNumber *dur = last[@"dur"];
        preview = [NSString stringWithFormat:@"[Voice %.0fs]", dur.doubleValue];
    } else {
        NSString *body = [last[@"body"] isKindOfClass:NSString.class] ? last[@"body"] : @"";
        if (body.length > 40) {
            preview = [[body substringToIndex:40] stringByAppendingString:@"..."];
        } else {
            preview = body;
        }
    }
    NSTimeInterval stamp = [last[@"stamp"] doubleValue];
    return @{
        @"preview": preview ?: @"",
        @"stamp": @(stamp),
        @"timeLabel": [self yk_timeLabelForStamp:stamp]
    };
}

- (NSString *)yk_timeLabelForStamp:(NSTimeInterval)stamp {
    if (stamp <= 0) {
        return @"";
    }
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:stamp];
    NSCalendar *cal = NSCalendar.currentCalendar;
    if ([cal isDateInToday:date]) {
        NSDateFormatter *fmt = [[NSDateFormatter alloc] init];
        fmt.dateFormat = @"HH:mm";
        return [fmt stringFromDate:date];
    }
    if ([cal isDateInYesterday:date]) {
        return @"Yesterday";
    }
    NSDateFormatter *fmt = [[NSDateFormatter alloc] init];
    fmt.dateFormat = @"MM/dd";
    return [fmt stringFromDate:date];
}

- (void)yk_ownerKey:(NSString *)ownerKey peerId:(NSString *)peerId appendLine:(NSDictionary *)line {
    if (ownerKey.length == 0 || peerId.length == 0 || ![line isKindOfClass:NSDictionary.class]) {
        return;
    }
    NSMutableDictionary *map = [self yk_mutableLinesMap];
    NSString *key = [self yk_compositeKeyOwner:ownerKey peer:peerId];
    NSMutableArray *lines = [([map[key] isKindOfClass:NSArray.class] ? map[key] : @[]) mutableCopy];
    [lines addObject:line];
    map[key] = lines;
    [self yk_persistLinesMap:map];
}

- (NSString *)yk_voiceDirectoryPath {
    NSString *docs = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
    NSString *dir = [docs stringByAppendingPathComponent:@"yoka_lane_media"];
    NSFileManager *fm = NSFileManager.defaultManager;
    if (![fm fileExistsAtPath:dir]) {
        [fm createDirectoryAtPath:dir withIntermediateDirectories:YES attributes:nil error:nil];
    }
    return dir;
}

- (NSString *)yk_absolutePathForVoiceFile:(NSString *)fileName {
    if (fileName.length == 0 || [fileName containsString:@"/"] || [fileName containsString:@".."]) {
        return nil;
    }
    return [[self yk_voiceDirectoryPath] stringByAppendingPathComponent:fileName];
}

- (NSString *)yk_storeVoiceFileFromPath:(NSString *)tempPath {
    if (tempPath.length == 0 || ![NSFileManager.defaultManager fileExistsAtPath:tempPath]) {
        return nil;
    }
    NSString *ext = tempPath.pathExtension.length > 0 ? tempPath.pathExtension : @"m4a";
    NSString *name = [NSString stringWithFormat:@"v_%.0f_%u.%@",
                      [[NSDate date] timeIntervalSince1970] * 1000.0,
                      arc4random_uniform(100000),
                      ext];
    NSString *dest = [self yk_absolutePathForVoiceFile:name];
    if (dest.length == 0) {
        return nil;
    }
    NSError *error = nil;
    if ([NSFileManager.defaultManager fileExistsAtPath:dest]) {
        [NSFileManager.defaultManager removeItemAtPath:dest error:nil];
    }
    if (![NSFileManager.defaultManager copyItemAtPath:tempPath toPath:dest error:&error]) {
        return nil;
    }
    return name;
}

@end
