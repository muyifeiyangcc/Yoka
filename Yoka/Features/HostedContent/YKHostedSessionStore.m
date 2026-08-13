//
//  YKHostedSessionStore.m
//  Yoka
//

#import "YKHostedSessionStore.h"
#import "YKRosterVault.h"
#import <CommonCrypto/CommonDigest.h>
#import <Security/Security.h>

static NSString * const kYKHostedSessionKeychainService = @"com.rejuvenation.yoka.spark.vault.k7";
static NSString * const kYKHostedInstallationAccount = @"yoka.spark.device.ember.k7";
static NSString * const kYKHostedTokenAccount = @"yoka.spark.lane.ribbon.k7";
static NSString * const kYKHostedPasswordAccount = @"yoka.spark.pin.clasp.k7";
static NSString * const kYKHostedPurchaseTracePrefix = @"yoka.spark.ledger.thread.k7.";
static NSString * const kYKHostedSparkAccessStampPrefix = @"yoka.spark.access.stamp.k7.";

@interface YKHostedSessionStore ()

@property (nonatomic, copy) NSString *yk_accountScopeHash;
@property (nonatomic, copy, nullable) NSString *yk_installationIdentifierCache;

@end

@implementation YKHostedSessionStore

- (instancetype)init {
    self = [super init];
    if (self) {
        YKRosterVault *roster = YKRosterVault.sharedRoster;
        NSString *owner = roster.yk_activeMailbox;
        if (owner.length == 0 && roster.yk_activeAppleUserId.length > 0) {
            owner = [@"apple:" stringByAppendingString:roster.yk_activeAppleUserId];
        }
        if (owner.length == 0) { owner = @"visitor"; }
        NSData *source = [owner dataUsingEncoding:NSUTF8StringEncoding] ?: NSData.data;
        unsigned char digest[CC_SHA256_DIGEST_LENGTH] = {0};
        CC_SHA256(source.bytes, (CC_LONG)source.length, digest);
        NSMutableString *tag = [NSMutableString stringWithCapacity:24];
        for (NSUInteger index = 0; index < 12; index++) {
            [tag appendFormat:@"%02x", digest[index]];
        }
        _yk_accountScopeHash = [tag copy];
    }
    return self;
}

- (NSString *)yk_scopedAccount:(NSString *)account {
    return [NSString stringWithFormat:@"%@.%@", account ?: @"", self.yk_accountScopeHash ?: @""];
}

- (NSMutableDictionary *)yk_queryForAccount:(NSString *)account {
    return [@{
        (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
        (__bridge id)kSecAttrService: kYKHostedSessionKeychainService,
        (__bridge id)kSecAttrAccount: account ?: @""
    } mutableCopy];
}

- (nullable NSString *)yk_textForAccount:(NSString *)account {
    NSMutableDictionary *query = [self yk_queryForAccount:account];
    query[(__bridge id)kSecReturnData] = @YES;
    query[(__bridge id)kSecMatchLimit] = (__bridge id)kSecMatchLimitOne;
    CFTypeRef result = NULL;
    OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)query, &result);
    if (status != errSecSuccess || result == NULL) {
        if (result) { CFRelease(result); }
        return nil;
    }
    NSData *data = CFBridgingRelease(result);
    return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}

- (BOOL)yk_putText:(NSString *)text forAccount:(NSString *)account error:(NSError **)error {
    NSData *data = [text dataUsingEncoding:NSUTF8StringEncoding];
    if (data.length == 0 || account.length == 0) {
        if (error) {
            *error = [NSError errorWithDomain:@"YKHostedSessionStore"
                                         code:1
                                     userInfo:@{NSLocalizedDescriptionKey: @"Credential data is invalid."}];
        }
        return NO;
    }
    NSMutableDictionary *query = [self yk_queryForAccount:account];
    NSDictionary *changes = @{(__bridge id)kSecValueData: data};
    OSStatus status = SecItemUpdate((__bridge CFDictionaryRef)query,
                                    (__bridge CFDictionaryRef)changes);
    if (status == errSecItemNotFound) {
        query[(__bridge id)kSecValueData] = data;
        query[(__bridge id)kSecAttrAccessible] = (__bridge id)kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly;
        status = SecItemAdd((__bridge CFDictionaryRef)query, NULL);
    }
    if (status != errSecSuccess && error) {
        *error = [NSError errorWithDomain:@"YKHostedSessionStore"
                                     code:status
                                 userInfo:@{NSLocalizedDescriptionKey: @"Credential storage is unavailable."}];
    }
    return status == errSecSuccess;
}

- (void)yk_removeAccount:(NSString *)account {
    NSDictionary *query = [self yk_queryForAccount:account];
    SecItemDelete((__bridge CFDictionaryRef)query);
}

- (NSString *)installationIdentifier {
    @synchronized (self) {
        if (self.yk_installationIdentifierCache.length > 0) {
            return self.yk_installationIdentifierCache;
        }
        NSString *stored = [self yk_textForAccount:kYKHostedInstallationAccount];
        if (stored.length > 0) {
            self.yk_installationIdentifierCache = stored;
            return self.yk_installationIdentifierCache;
        }
        NSString *created = NSUUID.UUID.UUIDString.lowercaseString;
        [self yk_putText:created forAccount:kYKHostedInstallationAccount error:nil];
        self.yk_installationIdentifierCache = created;
        return self.yk_installationIdentifierCache;
    }
}

- (NSString *)currentSessionToken {
    return [self yk_textForAccount:[self yk_scopedAccount:kYKHostedTokenAccount]];
}

- (NSString *)savedLoginPassword {
    return [self yk_textForAccount:[self yk_scopedAccount:kYKHostedPasswordAccount]];
}

- (NSString *)yk_sparkAccessStampKey {
    return [kYKHostedSparkAccessStampPrefix stringByAppendingString:self.yk_accountScopeHash ?: @""];
}

- (BOOL)hasSparkAccessStamp {
    return [NSUserDefaults.standardUserDefaults boolForKey:[self yk_sparkAccessStampKey]];
}

- (void)yk_setSparkAccessStamp:(BOOL)active {
    NSString *key = [self yk_sparkAccessStampKey];
    if (active) {
        [NSUserDefaults.standardUserDefaults setBool:YES forKey:key];
    } else {
        [NSUserDefaults.standardUserDefaults removeObjectForKey:key];
    }
}

- (BOOL)storeLoginPassword:(NSString *)password error:(NSError **)error {
    if (password.length == 0) {
        if (error) {
            *error = [NSError errorWithDomain:@"YKHostedSessionStore"
                                         code:2
                                     userInfo:@{NSLocalizedDescriptionKey: @"Credential data is invalid."}];
        }
        return NO;
    }
    return [self yk_putText:password
                 forAccount:[self yk_scopedAccount:kYKHostedPasswordAccount]
                      error:error];
}

- (BOOL)storeSessionToken:(NSString *)token password:(NSString *)password error:(NSError **)error {
    NSString *tokenAccount = [self yk_scopedAccount:kYKHostedTokenAccount];
    NSString *passwordAccount = [self yk_scopedAccount:kYKHostedPasswordAccount];
    if (![self yk_putText:token forAccount:tokenAccount error:error]) {
        return NO;
    }
    if (password.length > 0) {
        NSError *passwordError = nil;
        if (![self yk_putText:password forAccount:passwordAccount error:&passwordError]) {
            [self yk_removeAccount:tokenAccount];
            if (error) { *error = passwordError; }
            return NO;
        }
    } else {
        [self yk_removeAccount:passwordAccount];
    }
    [self yk_setSparkAccessStamp:YES];
    return YES;
}

- (void)clearSessionCredentials {
    [self yk_removeAccount:[self yk_scopedAccount:kYKHostedTokenAccount]];
    [self yk_setSparkAccessStamp:NO];
}

- (NSString *)yk_traceAccountForSku:(NSString *)sku {
    NSData *data = [sku dataUsingEncoding:NSUTF8StringEncoding] ?: NSData.data;
    NSString *safe = [data base64EncodedStringWithOptions:0];
    safe = [[safe stringByReplacingOccurrencesOfString:@"/" withString:@"_"]
            stringByReplacingOccurrencesOfString:@"+" withString:@"-"];
    return [NSString stringWithFormat:@"%@%@.%@", kYKHostedPurchaseTracePrefix, self.yk_accountScopeHash ?: @"", safe ?: @""];
}

- (void)storePurchaseTrace:(NSString *)trace forProductID:(NSString *)productID {
    if (trace.length == 0 || productID.length == 0) { return; }
    [self yk_putText:trace forAccount:[self yk_traceAccountForSku:productID] error:nil];
}

- (NSString *)purchaseTraceForProductID:(NSString *)productID {
    if (productID.length == 0) { return nil; }
    return [self yk_textForAccount:[self yk_traceAccountForSku:productID]];
}

- (void)removePurchaseTraceForProductID:(NSString *)productID {
    if (productID.length == 0) { return; }
    [self yk_removeAccount:[self yk_traceAccountForSku:productID]];
}

@end
