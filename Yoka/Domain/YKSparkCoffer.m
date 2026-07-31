//
//  YKSparkCoffer.m
//  Yoka
//

#import "YKSparkCoffer.h"

static NSString * const kYKSparkTallyPrefix = @"yoka.spark.tally.r1.";
static const NSInteger kYKSparkDefaultTally = 0;

@implementation YKSparkCoffer

+ (instancetype)sharedCoffer {
    static YKSparkCoffer *coffer = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        coffer = [[YKSparkCoffer alloc] init];
    });
    return coffer;
}

- (NSString *)yk_defaultsKeyForOwnerKey:(NSString *)ownerKey {
    NSString *owner = ownerKey.length > 0 ? ownerKey : @"guest";
    return [kYKSparkTallyPrefix stringByAppendingString:owner];
}

- (NSInteger)yk_tallyForOwnerKey:(NSString *)ownerKey {
    NSString *key = [self yk_defaultsKeyForOwnerKey:ownerKey];
    NSNumber *saved = [NSUserDefaults.standardUserDefaults objectForKey:key];
    if ([saved isKindOfClass:NSNumber.class]) {
        return MAX(0, saved.integerValue);
    }
    return kYKSparkDefaultTally;
}

- (void)yk_ownerKey:(NSString *)ownerKey setTally:(NSInteger)tally {
    NSString *key = [self yk_defaultsKeyForOwnerKey:ownerKey];
    [NSUserDefaults.standardUserDefaults setObject:@(MAX(0, tally)) forKey:key];
    [NSUserDefaults.standardUserDefaults synchronize];
}

- (BOOL)yk_ownerKey:(NSString *)ownerKey spend:(NSInteger)amount {
    if (amount <= 0) {
        return YES;
    }
    NSInteger tally = [self yk_tallyForOwnerKey:ownerKey];
    if (tally < amount) {
        return NO;
    }
    [self yk_ownerKey:ownerKey setTally:tally - amount];
    return YES;
}

- (void)yk_ownerKey:(NSString *)ownerKey credit:(NSInteger)amount {
    if (amount <= 0) {
        return;
    }
    NSInteger tally = [self yk_tallyForOwnerKey:ownerKey];
    [self yk_ownerKey:ownerKey setTally:tally + amount];
}

@end
