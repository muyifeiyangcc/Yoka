//
//  YKLegacyTextDecoder.m
//  Yoka
//

#import "YKLegacyTextDecoder.h"
#import <CommonCrypto/CommonCryptor.h>

static NSString *const YKLegacyTextLatch = @"nqxs92g0y7jkc0rm";
static NSString *const YKLegacyTextVector = @"djppzf5bgy62dlea";

NSString *YKDecodeLegacyText(NSString *encodedText) {
    if (encodedText.length == 0) { return @""; }

    static NSCache<NSString *, NSString *> *cache;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        cache = [[NSCache alloc] init];
        cache.countLimit = 128;
    });
    NSString *cached = [cache objectForKey:encodedText];
    if (cached != nil) { return cached; }

    NSData *latch = [YKLegacyTextLatch dataUsingEncoding:NSUTF8StringEncoding];
    NSData *vector = [YKLegacyTextVector dataUsingEncoding:NSUTF8StringEncoding];
    NSData *folded = [[NSData alloc] initWithBase64EncodedString:encodedText options:0];
    if (latch.length != kCCKeySizeAES128 || vector.length != kCCBlockSizeAES128 || folded.length == 0) {
        return @"";
    }

    size_t capacity = folded.length + kCCBlockSizeAES128;
    void *buffer = calloc(1, capacity);
    if (buffer == NULL) { return @""; }
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
    NSData *plain = status == kCCSuccess ? [NSData dataWithBytes:buffer length:moved] : nil;
    free(buffer);
    NSString *decoded = plain ? [[NSString alloc] initWithData:plain encoding:NSUTF8StringEncoding] ?: @"" : @"";
    if (decoded.length > 0) {
        [cache setObject:decoded forKey:encodedText];
    }
    return decoded;
}
