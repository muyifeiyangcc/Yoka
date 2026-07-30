//
//  YKPublishLedger.m
//  Yoka
//

#import "YKPublishLedger.h"

static NSString * const kYKPublishMapKey = @"yk.publish.entriesByOwner.r2";
static NSString * const kYKPublishFolderName = @"yoka_entry_media";

@implementation YKPublishLedger

+ (instancetype)sharedLedger {
    static YKPublishLedger *ledger = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        ledger = [[YKPublishLedger alloc] init];
    });
    return ledger;
}

- (NSUserDefaults *)yk_defaults {
    return NSUserDefaults.standardUserDefaults;
}

- (NSString *)yk_mediaDirectoryPath {
    NSString *docs = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
    NSString *dir = [docs stringByAppendingPathComponent:kYKPublishFolderName];
    NSFileManager *fm = NSFileManager.defaultManager;
    if (![fm fileExistsAtPath:dir]) {
        [fm createDirectoryAtPath:dir withIntermediateDirectories:YES attributes:nil error:nil];
    }
    return dir;
}

- (NSString *)yk_absolutePathForRelativeName:(NSString *)name {
    if (name.length == 0) {
        return nil;
    }
    return [[self yk_mediaDirectoryPath] stringByAppendingPathComponent:name];
}

- (NSMutableDictionary *)yk_mutableMap {
    NSDictionary *saved = [self.yk_defaults dictionaryForKey:kYKPublishMapKey];
    return [saved isKindOfClass:NSDictionary.class] ? [saved mutableCopy] : [NSMutableDictionary dictionary];
}

- (void)yk_persistMap:(NSDictionary *)map {
    [self.yk_defaults setObject:map forKey:kYKPublishMapKey];
    [self.yk_defaults synchronize];
}

- (NSDictionary *)yk_hydratedEntry:(NSDictionary *)raw {
    if (![raw isKindOfClass:NSDictionary.class]) {
        return @{};
    }
    NSMutableDictionary *post = [raw mutableCopy];
    NSString *imageFile = post[@"imageFile"];
    if ([imageFile isKindOfClass:NSString.class] && imageFile.length > 0) {
        post[@"imagePath"] = [self yk_absolutePathForRelativeName:imageFile] ?: @"";
    }
    NSString *videoFile = post[@"videoFile"];
    if ([videoFile isKindOfClass:NSString.class] && videoFile.length > 0) {
        post[@"videoPath"] = [self yk_absolutePathForRelativeName:videoFile] ?: @"";
    }

    NSArray *items = post[@"items"];
    if ([items isKindOfClass:NSArray.class] && items.count > 0) {
        NSMutableArray *hydratedItems = [NSMutableArray arrayWithCapacity:items.count];
        for (NSDictionary *item in items) {
            if (![item isKindOfClass:NSDictionary.class]) {
                continue;
            }
            NSMutableDictionary *copy = [item mutableCopy];
            NSString *goodsFile = copy[@"imageFile"];
            if ([goodsFile isKindOfClass:NSString.class] && goodsFile.length > 0) {
                copy[@"imagePath"] = [self yk_absolutePathForRelativeName:goodsFile] ?: @"";
            }
            [hydratedItems addObject:copy];
        }
        post[@"items"] = hydratedItems;
    }
    return post;
}

- (NSArray<NSDictionary *> *)yk_entriesForOwnerKey:(NSString *)ownerKey {
    NSString *owner = ownerKey.length > 0 ? ownerKey : @"guest";
    NSArray *raw = [self yk_mutableMap][owner];
    if (![raw isKindOfClass:NSArray.class]) {
        return @[];
    }
    NSMutableArray *out = [NSMutableArray arrayWithCapacity:raw.count];
    for (NSDictionary *entry in raw) {
        [out addObject:[self yk_hydratedEntry:entry]];
    }
    return out;
}

- (NSArray<NSDictionary *> *)yk_allPublishedEntries {
    NSDictionary *map = [self yk_mutableMap];
    NSMutableArray *all = [NSMutableArray array];
    for (NSString *owner in map) {
        NSArray *posts = map[owner];
        if (![posts isKindOfClass:NSArray.class]) {
            continue;
        }
        for (NSDictionary *entry in posts) {
            [all addObject:[self yk_hydratedEntry:entry]];
        }
    }
    [all sortUsingComparator:^NSComparisonResult(NSDictionary *a, NSDictionary *b) {
        double ta = [a[@"createdAt"] doubleValue];
        double tb = [b[@"createdAt"] doubleValue];
        if (ta == tb) {
            return NSOrderedSame;
        }
        return ta > tb ? NSOrderedAscending : NSOrderedDescending;
    }];
    return all;
}

- (void)yk_prependEntry:(NSDictionary *)post forOwnerKey:(NSString *)ownerKey {
    if (![post isKindOfClass:NSDictionary.class] || post.count == 0) {
        return;
    }
    NSString *owner = ownerKey.length > 0 ? ownerKey : @"guest";
    NSMutableDictionary *map = [self yk_mutableMap];
    NSMutableArray *list = [map[owner] isKindOfClass:NSArray.class] ? [map[owner] mutableCopy] : [NSMutableArray array];
    [list insertObject:post atIndex:0];
    map[owner] = list;
    [self yk_persistMap:map];
}

- (void)yk_eraseEntriesForOwnerKey:(NSString *)ownerKey {
    if (ownerKey.length == 0) {
        return;
    }
    NSMutableDictionary *map = [self yk_mutableMap];
    NSArray *posts = map[ownerKey];
    if ([posts isKindOfClass:NSArray.class]) {
        for (NSDictionary *entry in posts) {
            [self yk_deleteMediaReferencedByEntry:entry];
        }
    }
    [map removeObjectForKey:ownerKey];
    [self yk_persistMap:map];
}

- (void)yk_deleteRelativeMediaName:(NSString *)name {
    if (name.length == 0) {
        return;
    }
    NSString *path = [self yk_absolutePathForRelativeName:name];
    if (path.length == 0) {
        return;
    }
    [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
}

- (void)yk_deleteMediaReferencedByEntry:(NSDictionary *)post {
    NSString *imageFile = post[@"imageFile"];
    if ([imageFile isKindOfClass:NSString.class]) {
        [self yk_deleteRelativeMediaName:imageFile];
    }
    NSString *videoFile = post[@"videoFile"];
    if ([videoFile isKindOfClass:NSString.class]) {
        [self yk_deleteRelativeMediaName:videoFile];
    }
    NSArray *items = post[@"items"];
    if (![items isKindOfClass:NSArray.class]) {
        return;
    }
    for (NSDictionary *item in items) {
        NSString *goodsFile = item[@"imageFile"];
        if ([goodsFile isKindOfClass:NSString.class]) {
            [self yk_deleteRelativeMediaName:goodsFile];
        }
    }
}

- (nullable NSString *)yk_storeJPEGImage:(UIImage *)image {
    if (!image) {
        return nil;
    }
    NSData *data = UIImageJPEGRepresentation(image, 0.88);
    if (data.length == 0) {
        return nil;
    }
    NSString *name = [NSString stringWithFormat:@"%@.jpg", [NSUUID UUID].UUIDString.lowercaseString];
    NSString *path = [self yk_absolutePathForRelativeName:name];
    if (![data writeToFile:path atomically:YES]) {
        return nil;
    }
    return name;
}

- (nullable NSString *)yk_storeVideoFileAtURL:(NSURL *)url {
    if (!url.isFileURL) {
        return nil;
    }
    NSString *ext = url.pathExtension.lowercaseString;
    if (ext.length == 0) {
        ext = @"mp4";
    }
    NSString *name = [NSString stringWithFormat:@"%@.%@", [NSUUID UUID].UUIDString.lowercaseString, ext];
    NSString *destPath = [self yk_absolutePathForRelativeName:name];
    NSURL *destURL = [NSURL fileURLWithPath:destPath];
    NSFileManager *fm = NSFileManager.defaultManager;
    if ([fm fileExistsAtPath:destPath]) {
        [fm removeItemAtPath:destPath error:nil];
    }
    NSError *copyError = nil;
    if ([fm copyItemAtURL:url toURL:destURL error:&copyError]) {
        return name;
    }
    NSData *data = [NSData dataWithContentsOfURL:url options:NSDataReadingMappedIfSafe error:nil];
    if (data.length == 0 || ![data writeToFile:destPath atomically:YES]) {
        return nil;
    }
    return name;
}

+ (nullable UIImage *)yk_coverImageForEntry:(NSDictionary *)post {
    if (![post isKindOfClass:NSDictionary.class]) {
        return nil;
    }
    NSString *imageName = post[@"image"];
    if ([imageName isKindOfClass:NSString.class] && imageName.length > 0) {
        UIImage *named = [UIImage imageNamed:imageName];
        if (named) {
            return named;
        }
    }
    NSString *imagePath = post[@"imagePath"];
    if ([imagePath isKindOfClass:NSString.class] && imagePath.length > 0) {
        UIImage *fileImage = [UIImage imageWithContentsOfFile:imagePath];
        if (fileImage) {
            return fileImage;
        }
    }
    NSString *imageFile = post[@"imageFile"];
    if ([imageFile isKindOfClass:NSString.class] && imageFile.length > 0) {
        NSString *path = [[YKPublishLedger sharedLedger] yk_absolutePathForRelativeName:imageFile];
        return [UIImage imageWithContentsOfFile:path];
    }
    return nil;
}

+ (nullable UIImage *)yk_goodsImageForItem:(NSDictionary *)item {
    if (![item isKindOfClass:NSDictionary.class]) {
        return nil;
    }
    NSString *imageName = item[@"image"];
    if ([imageName isKindOfClass:NSString.class] && imageName.length > 0) {
        UIImage *named = [UIImage imageNamed:imageName];
        if (named) {
            return named;
        }
    }
    NSString *imagePath = item[@"imagePath"];
    if ([imagePath isKindOfClass:NSString.class] && imagePath.length > 0) {
        UIImage *fileImage = [UIImage imageWithContentsOfFile:imagePath];
        if (fileImage) {
            return fileImage;
        }
    }
    NSString *imageFile = item[@"imageFile"];
    if ([imageFile isKindOfClass:NSString.class] && imageFile.length > 0) {
        NSString *path = [[YKPublishLedger sharedLedger] yk_absolutePathForRelativeName:imageFile];
        return [UIImage imageWithContentsOfFile:path];
    }
    return nil;
}

+ (nullable NSURL *)yk_videoURLForEntry:(NSDictionary *)post {
    if (![post isKindOfClass:NSDictionary.class]) {
        return nil;
    }
    NSFileManager *fm = NSFileManager.defaultManager;
    NSString *videoPath = post[@"videoPath"];
    if ([videoPath isKindOfClass:NSString.class] && videoPath.length > 0 && [fm fileExistsAtPath:videoPath]) {
        return [NSURL fileURLWithPath:videoPath];
    }
    NSString *videoFile = post[@"videoFile"];
    if ([videoFile isKindOfClass:NSString.class] && videoFile.length > 0) {
        NSString *path = [[YKPublishLedger sharedLedger] yk_absolutePathForRelativeName:videoFile];
        if (path.length > 0 && [fm fileExistsAtPath:path]) {
            return [NSURL fileURLWithPath:path];
        }
    }
    return nil;
}

@end
