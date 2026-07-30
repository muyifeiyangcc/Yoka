//
//  YKSigilForge.m
//  Yoka
//

#import "YKSigilForge.h"
#import <CommonCrypto/CommonCryptor.h>

@implementation YKSigilForge

+ (NSData *)yk_latchBytes {
    static uint8_t bytes[16] = {
        89, 107, 83, 103, 33, 55, 110, 81, 112, 50, 35, 109, 76, 120, 57, 82
    };
    return [NSData dataWithBytes:bytes length:16];
}

+ (NSData *)yk_vectorBytes {
    static uint8_t bytes[16] = {
        86, 114, 51, 36, 116, 72, 56, 110, 75, 112, 49, 33, 81, 119, 53, 90
    };
    return [NSData dataWithBytes:bytes length:16];
}

+ (NSString *)yk_unveil:(NSString *)sealed {
    if (sealed.length == 0) {
        return @"";
    }
    NSData *blob = [[NSData alloc] initWithBase64EncodedString:sealed options:0];
    if (blob.length == 0) {
        return @"";
    }
    NSData *key = [self yk_latchBytes];
    NSData *iv = [self yk_vectorBytes];
    size_t outLength = blob.length + kCCBlockSizeAES128;
    void *outBuf = malloc(outLength);
    if (!outBuf) {
        return @"";
    }
    size_t moved = 0;
    CCCryptorStatus status = CCCrypt(kCCDecrypt,
                                     kCCAlgorithmAES,
                                     kCCOptionPKCS7Padding,
                                     key.bytes,
                                     key.length,
                                     iv.bytes,
                                     blob.bytes,
                                     blob.length,
                                     outBuf,
                                     outLength,
                                     &moved);
    NSString *plain = @"";
    if (status == kCCSuccess && moved > 0) {
        plain = [[NSString alloc] initWithBytes:outBuf length:moved encoding:NSUTF8StringEncoding] ?: @"";
    }
    free(outBuf);
    return plain;
}

+ (NSInteger)yk_unveilInteger:(NSString *)sealed {
    return [[self yk_unveil:sealed] integerValue];
}

@end
