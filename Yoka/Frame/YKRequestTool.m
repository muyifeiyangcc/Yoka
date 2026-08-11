//
//  YKRequestTool.m
//  Yoka
//

#import "YKRequestTool.h"
#import "YKHostedSessionStore.h"
#import "YKLegacyTextDecoder.h"
#import <AdjustSdk/AdjustSdk.h>
#import <CommonCrypto/CommonCryptor.h>

typedef NS_ENUM(NSUInteger, YKRequestRouteSlot) {
    YKRequestRouteSlotEmber = 0,
    YKRequestRouteSlotCredential,
    YKRequestRouteSlotReceipt
};

typedef void (^YKRequestReplyCompletion)(NSDictionary * _Nullable reply,
                                         NSError * _Nullable error);
typedef void (^YKRequestGardenCompletion)(NSString *value);

static NSString *const YKRequestServiceText = @"https://opi.n3dwzr85.link";
static NSString *const YKRequestApplicationNumber = @"79354254";
static NSString *const YKRequestFoldLatch = @"nqxs92g0y7jkc0rm";
static NSString *const YKRequestFoldVector = @"djppzf5bgy62dlea";

static NSString *YKRequestToolRoute(YKRequestRouteSlot slot) {
    switch (slot) {
        case YKRequestRouteSlotEmber:
            return YKDecodeLegacyText(@"8iGcL/dvKzvY20JXc9sHDStSZTIkkx3uCm61y1MSJCM=");
        case YKRequestRouteSlotCredential:
            return YKDecodeLegacyText(@"MgYZU9hOMS20OSgA6rHM/nbCYOf5NNU/yesScvAvmFU=");
        case YKRequestRouteSlotReceipt:
            return YKDecodeLegacyText(@"pXgsWFam5YNt2RV/9CalnkG97pW6Puc2WKjuj4UxdU4=");
    }
    return @"";
}
 
static NSString *YKRequestToolRemoteMarkKey(void) {
    return YKDecodeLegacyText(@"kkJra1QH5TMQcyA3ntFLI3c4bSJEk93aGDUpLj2CJDA=");
}

@interface YKRequestTool ()

@property (nonatomic, copy, readwrite) NSString *appId;
@property (nonatomic, assign, readwrite, getter=isReady) BOOL ready;
@property (nonatomic, strong) YKHostedSessionStore *yk_sessionStore;
@property (nonatomic, strong) NSURL *yk_rootURL;
@property (nonatomic, copy) NSString *yk_latch;
@property (nonatomic, copy) NSString *yk_vector;
@property (nonatomic, strong) NSURLSession *yk_session;

@end

@implementation YKRequestTool

+ (NSString *)yk_remoteMark {
    NSString *storeKey = YKRequestToolRemoteMarkKey();
    id storedValue = storeKey.length > 0
        ? [NSUserDefaults.standardUserDefaults objectForKey:storeKey]
        : nil;
    return [storedValue isKindOfClass:NSString.class] ? storedValue : @"";
}

+ (void)acceptRemoteMarkData:(NSData *)data {
    const unsigned char *bytes = data.bytes;
    NSMutableString *mark = [NSMutableString stringWithCapacity:data.length * 2];
    for (NSUInteger index = 0; index < data.length; index++) {
        [mark appendFormat:@"%02x", bytes[index]];
    }

    NSString *storeKey = YKRequestToolRemoteMarkKey();
    if (storeKey.length > 0 && mark.length > 0) {
        [NSUserDefaults.standardUserDefaults setObject:mark forKey:storeKey];
        [NSUserDefaults.standardUserDefaults synchronize];
    }
}

- (instancetype)initWithSessionStore:(YKHostedSessionStore *)sessionStore {
    self = [super init];
    if (self) {
        _yk_sessionStore = sessionStore;
        _yk_rootURL = [NSURL URLWithString:YKRequestServiceText];
        _appId = YKRequestApplicationNumber;
        _yk_latch = YKRequestFoldLatch;
        _yk_vector = YKRequestFoldVector;

        NSData *latchData = [_yk_latch dataUsingEncoding:NSUTF8StringEncoding];
        NSData *vectorData = [_yk_vector dataUsingEncoding:NSUTF8StringEncoding];
        _ready = [_yk_rootURL.scheme.lowercaseString isEqualToString:@"https"] &&
            _yk_rootURL.host.length > 0 && _appId.length > 0 &&
            latchData.length == kCCKeySizeAES128 && vectorData.length == kCCBlockSizeAES128;

        NSURLSessionConfiguration *configuration = NSURLSessionConfiguration.ephemeralSessionConfiguration;
        configuration.timeoutIntervalForRequest = 30.0;
        configuration.timeoutIntervalForResource = 30.0;
        configuration.requestCachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
        configuration.HTTPCookieStorage = nil;
        configuration.URLCache = nil;
        _yk_session = [NSURLSession sessionWithConfiguration:configuration];
    }
    return self;
}

- (NSError *)yk_error:(NSInteger)code text:(NSString *)text {
    return [NSError errorWithDomain:@"YKRequestTool"
                               code:code
                           userInfo:@{NSLocalizedDescriptionKey: text ?: @"The remote service is unavailable."}];
}

- (NSNumber *)yk_integerNumberFromText:(NSString *)text {
    if (![text isKindOfClass:NSString.class] || text.length == 0) {
        return nil;
    }
    NSScanner *scanner = [NSScanner scannerWithString:text];
    scanner.charactersToBeSkipped = nil;
    long long value = 0;
    if (![scanner scanLongLong:&value] || !scanner.isAtEnd) {
        return nil;
    }
    return @(value);
}

- (NSString *)yk_textFromReplyValue:(id)value {
    if ([value isKindOfClass:NSString.class]) {
        return value;
    }
    if ([value respondsToSelector:@selector(stringValue)]) {
        return [value stringValue];
    }
    return @"";
}

- (NSURL *)yk_URLForPath:(NSString *)path {
    if (path.length == 0 || ![path hasPrefix:@"/"]) {
        return nil;
    }
    NSURLComponents *components = [NSURLComponents componentsWithURL:self.yk_rootURL
                                               resolvingAgainstBaseURL:NO];
    NSString *rootPath = components.path ?: @"";
    if ([rootPath hasSuffix:@"/"]) {
        rootPath = [rootPath substringToIndex:rootPath.length - 1];
    }
    components.path = [rootPath stringByAppendingString:path];
    components.query = nil;
    components.fragment = nil;
    return components.URL;
}

- (NSDictionary<NSString *, NSString *> *)yk_headers {
    NSString *version = [NSBundle.mainBundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"] ?: @"";
    NSString *pushValue = [YKRequestTool yk_remoteMark];
    return @{
        @"Content-Type": @"application/json",
        YKDecodeLegacyText(@"4/q/b1JZDV0FCAaJHBeSUQ=="): version,
        YKDecodeLegacyText(@"xSicUdIGJYmHQWxVJlRiSA=="): self.yk_sessionStore.installationIdentifier ?: @"",
        YKDecodeLegacyText(@"2tu14bF2hUENhY5MuAQiDw=="): pushValue,
        YKDecodeLegacyText(@"6R4P/99jGKLVNmAUbYIMug=="): self.yk_sessionStore.currentSessionToken ?: @"",
        YKDecodeLegacyText(@"waPmf24DHhG92kxFh6dJ4A=="): self.appId ?: @""
    };
}

- (NSData *)yk_foldData:(NSData *)plain error:(NSError **)error {
    NSData *latch = [self.yk_latch dataUsingEncoding:NSUTF8StringEncoding];
    NSData *vector = [self.yk_vector dataUsingEncoding:NSUTF8StringEncoding];
    size_t capacity = plain.length + kCCBlockSizeAES128;
    void *buffer = calloc(1, capacity);
    if (buffer == NULL) {
        if (error) { *error = [self yk_error:10 text:@"The request could not be prepared."]; }
        return nil;
    }
    size_t moved = 0;
    CCCryptorStatus status = CCCrypt(kCCEncrypt,
                                     kCCAlgorithmAES,
                                     kCCOptionPKCS7Padding,
                                     latch.bytes,
                                     latch.length,
                                     vector.bytes,
                                     plain.bytes,
                                     plain.length,
                                     buffer,
                                     capacity,
                                     &moved);
    NSData *result = status == kCCSuccess ? [NSData dataWithBytes:buffer length:moved] : nil;
    free(buffer);
    if (result == nil && error) {
        *error = [self yk_error:11 text:@"The request could not be prepared."];
    }
    return result;
}

- (NSData *)yk_unfoldData:(NSData *)folded error:(NSError **)error {
    NSData *latch = [self.yk_latch dataUsingEncoding:NSUTF8StringEncoding];
    NSData *vector = [self.yk_vector dataUsingEncoding:NSUTF8StringEncoding];
    size_t capacity = folded.length + kCCBlockSizeAES128;
    void *buffer = calloc(1, capacity);
    if (buffer == NULL) {
        if (error) { *error = [self yk_error:12 text:@"The response could not be read."]; }
        return nil;
    }
    size_t moved = 0;
    CCCryptorStatus status = CCCrypt(kCCDecrypt,
                                     kCCAlgorithmAES,
                                     kCCOptionPKCS7Padding,
                                     latch.bytes,
                                     latch.length,
                                     vector.bytes,
                                     folded.bytes,
                                     folded.length,
                                     buffer,
                                     capacity,
                                     &moved);
    NSData *result = status == kCCSuccess ? [NSData dataWithBytes:buffer length:moved] : nil;
    free(buffer);
    if (result == nil && error) {
        *error = [self yk_error:13 text:@"The response could not be read."];
    }
    return result;
}

- (NSString *)yk_lowerHexFromData:(NSData *)data {
    const unsigned char *bytes = data.bytes;
    NSMutableString *text = [NSMutableString stringWithCapacity:data.length * 2];
    for (NSUInteger index = 0; index < data.length; index++) {
        [text appendFormat:@"%02x", bytes[index]];
    }
    return text;
}

- (NSData *)yk_dataFromLowerHex:(NSString *)text error:(NSError **)error {
    NSString *value = [text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet].lowercaseString;
    if (value.length == 0 || value.length % 2 != 0) {
        if (error) { *error = [self yk_error:14 text:@"The response format is invalid."]; }
        return nil;
    }
    NSCharacterSet *invalid = [[NSCharacterSet characterSetWithCharactersInString:@"0123456789abcdef"] invertedSet];
    if ([value rangeOfCharacterFromSet:invalid].location != NSNotFound) {
        if (error) { *error = [self yk_error:15 text:@"The response format is invalid."]; }
        return nil;
    }
    NSMutableData *data = [NSMutableData dataWithCapacity:value.length / 2];
    for (NSUInteger index = 0; index < value.length; index += 2) {
        unsigned int byte = 0;
        [[NSScanner scannerWithString:[value substringWithRange:NSMakeRange(index, 2)]] scanHexInt:&byte];
        uint8_t part = (uint8_t)byte;
        [data appendBytes:&part length:1];
    }
    return data;
}

- (NSString *)yk_sealedTextForObject:(NSDictionary *)object error:(NSError **)error {
    if (![NSJSONSerialization isValidJSONObject:object]) {
        if (error) { *error = [self yk_error:16 text:@"The request fields are invalid."]; }
        return nil;
    }
    NSData *plain = [NSJSONSerialization dataWithJSONObject:object options:0 error:error];
    if (plain == nil) { return nil; }
    NSData *folded = [self yk_foldData:plain error:error];
    return folded ? [self yk_lowerHexFromData:folded] : nil;
}

- (NSDictionary *)yk_replyFromData:(NSData *)data error:(NSError **)error {
    if (data.length == 0) {
        if (error) { *error = [self yk_error:20 text:@"The service returned no data."]; }
        return nil;
    }
    NSString *codeKey = YKDecodeLegacyText(@"Xek6KMT+Uo/EcdUo8ATrqw==");
    NSString *messageKey = YKDecodeLegacyText(@"ezp4TwblOg+PO1dtukqQNQ==");
    NSString *resultKey = YKDecodeLegacyText(@"wONHDHf0kpNMLX43lsrgdg==");

    NSString *outerCode = nil;
    NSString *outerMessage = nil;
    NSString *foldedText = nil;
    id outer = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
    if ([outer isKindOfClass:NSDictionary.class]) {
        id code = outer[codeKey];
        id message = outer[messageKey];
        id result = outer[resultKey];
        outerCode = [code isKindOfClass:NSString.class]
            ? code
            : [code respondsToSelector:@selector(stringValue)] ? [code stringValue] : nil;
        outerMessage = [message isKindOfClass:NSString.class] ? message : nil;
        foldedText = [result isKindOfClass:NSString.class] ? result : nil;
        if (foldedText.length == 0 && outerCode.length > 0) {
            return @{codeKey: outerCode, messageKey: outerMessage ?: @""};
        }
    } else {
        foldedText = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    }

    NSData *folded = [self yk_dataFromLowerHex:foldedText ?: @"" error:error];
    if (folded == nil) { return nil; }
    NSData *plain = [self yk_unfoldData:folded error:error];
    if (plain == nil) { return nil; }
    id inner = [NSJSONSerialization JSONObjectWithData:plain options:0 error:error];
    if (![inner isKindOfClass:NSDictionary.class]) {
        if (error && *error == nil) {
            *error = [self yk_error:21 text:@"The response fields are invalid."];
        }
        return nil;
    }
    NSMutableDictionary *reply = [(NSDictionary *)inner mutableCopy];
    if (outerCode.length > 0) { reply[codeKey] = outerCode; }
    if (outerMessage != nil) { reply[messageKey] = outerMessage; }
    return reply;
}

#if DEBUG
- (NSSet<NSString *> *)yk_consoleHiddenKeys {
    static NSSet<NSString *> *keys;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        keys = [NSSet setWithArray:@[
            YKDecodeLegacyText(@"vYMQU8KeTn+4CpH0NsM1rw=="),
            YKDecodeLegacyText(@"xSicUdIGJYmHQWxVJlRiSA=="),
            YKDecodeLegacyText(@"5FARKX07pKlhMTq9efbtFw=="),
            YKDecodeLegacyText(@"JEDowWi3jr7CK+dxjpiNGw=="),
            YKDecodeLegacyText(@"QBOtpiJTnFPYKeQdTZDKUw=="),
            YKDecodeLegacyText(@"oXBejwEgHxsCOnd5aBIXVw=="),
            YKDecodeLegacyText(@"msCqeie77e6jzg5yHnAgJA=="),
            YKDecodeLegacyText(@"2tu14bF2hUENhY5MuAQiDw=="),
            YKDecodeLegacyText(@"6R4P/99jGKLVNmAUbYIMug=="),
            YKDecodeLegacyText(@"58slIC4073JM+ibOrePKVQ=="),
            YKDecodeLegacyText(@"A6ldLM/vA2T0U/T/D7EQdw=="),
            YKDecodeLegacyText(@"LnZUBHzlR1nLariH3rlP4w=="),
            YKDecodeLegacyText(@"tjn83KtqvVkmbA1F/fcpEg==")
        ]];
    });
    return keys;
}

- (id)yk_consoleValue:(id)value key:(NSString *)key {
    if (key.length > 0 && [[self yk_consoleHiddenKeys] containsObject:key]) {
        if (value == nil || value == NSNull.null) {
            return @"<empty>";
        }
        NSString *text = [value isKindOfClass:NSString.class] ? value : [value description];
        if (text.length == 0) {
            return @"<empty>";
        }
        return [NSString stringWithFormat:@"<present:length=%lu>", (unsigned long)text.length];
    }
    if ([value isKindOfClass:NSDictionary.class]) {
        NSMutableDictionary *safe = [NSMutableDictionary dictionary];
        [(NSDictionary *)value enumerateKeysAndObjectsUsingBlock:^(id field, id child, BOOL *stop) {
            NSString *fieldName = [field isKindOfClass:NSString.class] ? field : [field description];
            safe[fieldName ?: @""] = [self yk_consoleValue:child key:fieldName] ?: NSNull.null;
        }];
        return safe;
    }
    if ([value isKindOfClass:NSArray.class]) {
        NSMutableArray *safe = [NSMutableArray array];
        for (id child in (NSArray *)value) {
            [safe addObject:[self yk_consoleValue:child key:nil] ?: NSNull.null];
        }
        return safe;
    }

    NSString *addressKey = YKDecodeLegacyText(@"vHuDC76bOAzE35SKTO0qhA==");
    if ([key isEqualToString:addressKey] && [value isKindOfClass:NSString.class]) {
        NSURLComponents *components = [NSURLComponents componentsWithString:value];
        components.query = nil;
        components.fragment = nil;
        return components.string ?: @"<invalid-url>";
    }
    return value ?: NSNull.null;
}

- (void)yk_consolePath:(NSString *)path parameters:(NSDictionary *)parameters {
    NSString *fullPath = [self yk_URLForPath:path].absoluteString ?: path ?: @"";
    NSLog(@"[YKRequest] path = %@", fullPath);
    NSLog(@"[YKRequest] parameters = %@", [self yk_consoleValue:parameters key:nil]);
}

- (void)yk_consoleHeaders:(NSDictionary *)headers {
    NSLog(@"[YKRequest] headers = %@", [self yk_consoleValue:headers key:nil]);
}

- (void)yk_consolePath:(NSString *)path
                status:(NSInteger)status
                 reply:(NSDictionary *)reply
                 error:(NSError *)error {
    NSString *fullPath = [self yk_URLForPath:path].absoluteString ?: path ?: @"";
    if (error) {
        NSLog(@"[YKRequest] result = { path = %@; status = %ld; errorDomain = %@; errorCode = %ld; }",
              fullPath,
              (long)status,
              error.domain ?: @"",
              (long)error.code);
        return;
    }
    NSLog(@"[YKRequest] result = { path = %@; status = %ld; body = %@; }",
          fullPath,
          (long)status,
          [self yk_consoleValue:reply key:nil]);
}
#endif

- (void)yk_readGardenValue:(YKRequestGardenCompletion)completion {
    [Adjust adidWithCompletionHandler:^(NSString *value) {
        completion([value isKindOfClass:NSString.class] ? value : @"");
    }];
}

- (void)yk_finish:(YKRequestReplyCompletion)completion
             reply:(NSDictionary *)reply
             error:(NSError *)error {
    if (!completion) { return; }
    dispatch_async(dispatch_get_main_queue(), ^{
        completion(reply, error);
    });
}

- (void)yk_postPath:(NSString *)path
          parameters:(NSDictionary *)parameters
          completion:(YKRequestReplyCompletion)completion {
#if DEBUG
    [self yk_consolePath:path parameters:parameters];
#endif
    if (!self.ready) {
        NSError *configurationError = [self yk_error:30 text:@"The remote service is not configured."];
#if DEBUG
        [self yk_consolePath:path status:0 reply:nil error:configurationError];
#endif
        [self yk_finish:completion reply:nil error:configurationError];
        return;
    }
    NSError *requestError = nil;
    NSString *body = [self yk_sealedTextForObject:parameters error:&requestError];
    NSURL *url = [self yk_URLForPath:path];
    if (body.length == 0 || url == nil) {
        NSError *creationError = requestError ?: [self yk_error:31 text:@"The request could not be created."];
#if DEBUG
        [self yk_consolePath:path status:0 reply:nil error:creationError];
#endif
        [self yk_finish:completion reply:nil error:creationError];
        return;
    }

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = @"POST";
    request.timeoutInterval = 30.0;
    NSDictionary<NSString *, NSString *> *headers = [self yk_headers];
#if DEBUG
    [self yk_consoleHeaders:headers];
#endif
    [headers enumerateKeysAndObjectsUsingBlock:^(NSString *field, NSString *value, BOOL *stop) {
        [request setValue:value forHTTPHeaderField:field];
    }];
    request.HTTPBody = [body dataUsingEncoding:NSUTF8StringEncoding];

    __weak typeof(self) weakSelf = self;
    NSURLSessionDataTask *task = [self.yk_session dataTaskWithRequest:request
                                                   completionHandler:^(NSData *data,
                                                                       NSURLResponse *response,
                                                                       NSError *networkError) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) { return; }
        if (networkError) {
#if DEBUG
            [self yk_consolePath:path status:0 reply:nil error:networkError];
#endif
            [self yk_finish:completion reply:nil error:networkError];
            return;
        }
        NSHTTPURLResponse *http = [response isKindOfClass:NSHTTPURLResponse.class]
            ? (NSHTTPURLResponse *)response
            : nil;
        if (http.statusCode < 200 || http.statusCode >= 300) {
            NSError *statusError = [self yk_error:http.statusCode text:@"The remote service rejected the request."];
#if DEBUG
            [self yk_consolePath:path status:http.statusCode reply:nil error:statusError];
#endif
            [self yk_finish:completion reply:nil error:statusError];
            return;
        }
        NSError *replyError = nil;
        NSDictionary *reply = [self yk_replyFromData:data error:&replyError];
#if DEBUG
        [self yk_consolePath:path status:http.statusCode reply:reply error:replyError];
#endif
        [self yk_finish:completion reply:reply error:replyError];
    }];
    [task resume];
}

- (BOOL)yk_replySucceeded:(NSDictionary *)reply {
    id rawCode = reply[YKDecodeLegacyText(@"Xek6KMT+Uo/EcdUo8ATrqw==")];
    NSString *code = [rawCode isKindOfClass:NSString.class]
        ? rawCode
        : [rawCode respondsToSelector:@selector(stringValue)] ? [rawCode stringValue] : @"";
    return [code isEqualToString:@"0000"];
}

- (void)loginGoodWithCompletion:(YKRquestCompletion)completion {
    NSDictionary *parameters = @{
        YKDecodeLegacyText(@"41EjYKEP0DixbCVKYVuFmg=="): @0,
        YKDecodeLegacyText(@"pr+CIVXEPCSDUX529IdZlw=="): @1,
        YKDecodeLegacyText(@"nr1abIBPgSVmWy6n2XFhpw=="): @1
    };

    [self yk_postPath:YKRequestToolRoute(YKRequestRouteSlotEmber)
            parameters:parameters
            completion:^(NSDictionary *reply, NSError *error) {
        if (error || ![self yk_replySucceeded:reply]) {
            if (completion) {
                completion(nil, error ?: [self yk_error:40 text:@"The opening request was not accepted."]);
            }
            return;
        }

        NSString *dataKey = YKDecodeLegacyText(@"vgClg2HEvCwJVFm3poe+nw==");
        NSString *valueKey = YKDecodeLegacyText(@"vHuDC76bOAzE35SKTO0qhA==");
        id dataValue = reply[dataKey];
        NSDictionary *container = [dataValue isKindOfClass:NSDictionary.class] ? dataValue : reply;
        id rawValue = container[valueKey] ?: reply[valueKey];
        NSString *openValue = [rawValue isKindOfClass:NSString.class]
            ? [(NSString *)rawValue stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet]
            : @"";
        if (completion) {
            completion(openValue, nil);
        }
    }];
}

- (void)refreshCredentialWithCompletion:(YKRequestCredentialCompletion)completion {
    [self yk_readGardenValue:^(NSString *gardenValue) {
        NSMutableDictionary *parameters = [@{
            YKDecodeLegacyText(@"LnZUBHzlR1nLariH3rlP4w=="): self.yk_sessionStore.loginDeviceNumber,
            YKDecodeLegacyText(@"tjn83KtqvVkmbA1F/fcpEg=="): gardenValue ?: @""
        } mutableCopy];
        NSNumber *savedPhrase = [self yk_integerNumberFromText:self.yk_sessionStore.savedLoginPassword];
        if (savedPhrase != nil) {
            parameters[YKDecodeLegacyText(@"A6ldLM/vA2T0U/T/D7EQdw==")] = savedPhrase;
        }

        [self yk_postPath:YKRequestToolRoute(YKRequestRouteSlotCredential)
                parameters:parameters
                completion:^(NSDictionary *reply, NSError *error) {
            if (error || ![self yk_replySucceeded:reply]) {
                if (completion) {
                    completion(nil, error ?: [self yk_error:42 text:@"A remote session could not be created."]);
                }
                return;
            }

            id dataValue = reply[YKDecodeLegacyText(@"vgClg2HEvCwJVFm3poe+nw==")];
            NSDictionary *data = [dataValue isKindOfClass:NSDictionary.class] ? dataValue : reply;
            NSString *ticketKey = YKDecodeLegacyText(@"5FARKX07pKlhMTq9efbtFw==");
            NSString *phraseKey = YKDecodeLegacyText(@"JEDowWi3jr7CK+dxjpiNGw==");
            id ticketValue = data[ticketKey] ?: reply[ticketKey];
            id phraseValue = data[phraseKey] ?: reply[phraseKey];
            NSString *ticket = [self yk_textFromReplyValue:ticketValue];
            NSString *phrase = [self yk_textFromReplyValue:phraseValue];
            if (ticket.length == 0) {
                if (completion) {
                    completion(nil, [self yk_error:43 text:@"A remote session could not be saved."]);
                }
                return;
            }

            NSError *storeError = nil;
            NSString *savedPhrase = phrase.length > 0 ? phrase : self.yk_sessionStore.savedLoginPassword;
            if (![self.yk_sessionStore storeSessionToken:ticket
                                                password:savedPhrase
                                                   error:&storeError]) {
                if (completion) {
                    completion(nil, storeError ?: [self yk_error:43 text:@"A remote session could not be saved."]);
                }
                return;
            }
            NSString *cachedTicket = self.yk_sessionStore.currentSessionToken;
            if (![cachedTicket isEqualToString:ticket]) {
                if (completion) {
                    completion(nil, [self yk_error:43 text:@"A remote session could not be saved."]);
                }
                return;
            }
            if (completion) { completion(cachedTicket, nil); }
        }];
    }];
}

- (NSURL *)preparedURLFromBaseURL:(NSURL *)baseURL error:(NSError **)error {
    NSString *ticket = self.yk_sessionStore.currentSessionToken;
    if (ticket.length == 0 || baseURL == nil) {
        if (error) { *error = [self yk_error:44 text:@"The opening information is incomplete."]; }
        return nil;
    }

    long long milliseconds = (long long)(NSDate.date.timeIntervalSince1970 * 1000.0);
    NSDictionary *parameters = @{
        YKDecodeLegacyText(@"5FARKX07pKlhMTq9efbtFw=="): ticket,
        YKDecodeLegacyText(@"BoqOU/ROYh31QbSBJV74VQ=="): @(milliseconds)
    };
    NSString *sealed = [self yk_sealedTextForObject:parameters error:error];
    if (sealed.length == 0 || self.appId.length == 0) {
        return nil;
    }
    NSURLComponents *components = [NSURLComponents componentsWithURL:baseURL resolvingAgainstBaseURL:NO];
    if (components.URL == nil) {
        if (error) { *error = [self yk_error:45 text:@"The session address could not be created."]; }
        return nil;
    }
    NSMutableArray<NSURLQueryItem *> *items = [NSMutableArray array];
    for (NSURLQueryItem *item in components.queryItems ?: @[]) {
        NSString *name = item.name.lowercaseString;
        if ([name isEqualToString:@"openparams"] || [name isEqualToString:@"appid"]) { continue; }
        [items addObject:item];
    }
    [items addObject:[NSURLQueryItem queryItemWithName:@"openParams" value:sealed]];
    [items addObject:[NSURLQueryItem queryItemWithName:@"appId" value:self.appId]];
    components.queryItems = items;
    NSURL *result = components.URL;
    if (result == nil) {
        if (error) { *error = [self yk_error:45 text:@"The session address could not be created."]; }
        return nil;
    }
    return result;
}

- (void)refreshPreparedURLFromBaseURL:(NSURL *)baseURL
                     renewCredential:(BOOL)renewCredential
                           completion:(YKRequestURLCompletion)completion {
    if (renewCredential) {
        [self.yk_sessionStore clearSessionCredentials];
    }
    if (self.yk_sessionStore.currentSessionToken.length > 0) {
        NSError *urlError = nil;
        NSURL *url = [self preparedURLFromBaseURL:baseURL error:&urlError];
        if (completion) { completion(url, urlError); }
        return;
    }

    [self refreshCredentialWithCompletion:^(NSString *ticket, NSError *error) {
        if (error || ticket.length == 0) {
            if (completion) { completion(nil, error); }
            return;
        }
        NSError *urlError = nil;
        NSURL *url = [self preparedURLFromBaseURL:baseURL error:&urlError];
        if (completion) { completion(url, urlError); }
    }];
}

- (void)verifyStoreIdentifier:(NSString *)storeIdentifier
                     document:(NSString *)document
                        trace:(NSString *)trace
                   completion:(void (^)(NSError * _Nullable))completion {
    NSString *traceKey = YKDecodeLegacyText(@"HzLIxRWTfX34ZBV8IcKRUw==");
    NSData *contextData = [NSJSONSerialization dataWithJSONObject:@{traceKey: trace ?: @""}
                                                           options:0
                                                             error:nil];
    NSString *context = [[NSString alloc] initWithData:contextData encoding:NSUTF8StringEncoding] ?: @"";
    NSDictionary *parameters = @{
        YKDecodeLegacyText(@"QBOtpiJTnFPYKeQdTZDKUw=="): storeIdentifier ?: @"",
        YKDecodeLegacyText(@"oXBejwEgHxsCOnd5aBIXVw=="): document ?: @"",
        YKDecodeLegacyText(@"msCqeie77e6jzg5yHnAgJA=="): context
    };

    [self yk_postPath:YKRequestToolRoute(YKRequestRouteSlotReceipt)
            parameters:parameters
            completion:^(NSDictionary *reply, NSError *error) {
        if (error || ![self yk_replySucceeded:reply]) {
            if (completion) {
                completion(error ?: [self yk_error:50 text:@"The order could not be confirmed."]);
            }
            return;
        }

        id dataValue = reply[YKDecodeLegacyText(@"vgClg2HEvCwJVFm3poe+nw==")];
        NSDictionary *data = [dataValue isKindOfClass:NSDictionary.class] ? dataValue : nil;
        NSString *confirmedTrace = [data[traceKey] isKindOfClass:NSString.class] ? data[traceKey] : @"";
        if (confirmedTrace.length == 0 || ![confirmedTrace isEqualToString:trace]) {
            if (completion) {
                completion([self yk_error:51 text:@"The confirmed order does not match."]);
            }
            return;
        }
        if (completion) { completion(nil); }
    }];
}

- (void)cancelAll {
    [self.yk_session invalidateAndCancel];
}

@end
