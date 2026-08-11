//
//  YKHostedContentBridge.m
//  Yoka
//

#import "YKHostedContentBridge.h"
#import "YKLegacyTextDecoder.h"

@interface YKHostedContentBridge ()

@property (nonatomic, weak) id<YKHostedContentBridgeDelegate> yk_delegate;

@end

@implementation YKHostedContentBridge

- (instancetype)initWithDelegate:(id<YKHostedContentBridgeDelegate>)delegate {
    self = [super init];
    if (self) {
        _yk_delegate = delegate;
    }
    return self;
}

+ (NSString *)orderChannel {
    return YKDecodeLegacyText(@"3vyMxVzMFAXsw4xLaEKonQ==");
}

+ (NSString *)closeChannel {
    return YKDecodeLegacyText(@"CgGILZIhJ9hvZEG0BlB59w==");
}

+ (NSString *)outsideChannel {
    return YKDecodeLegacyText(@"r2vRp3Ro1QOpWafe1tSYNA==");
}

+ (NSArray<NSString *> *)channels {
    return @[[self orderChannel], [self closeChannel], [self outsideChannel]];
}

- (NSDictionary *)yk_dictionaryFromBody:(id)body {
    if ([body isKindOfClass:NSDictionary.class]) { return body; }
    if (![body isKindOfClass:NSString.class]) { return @{}; }
    NSData *data = [(NSString *)body dataUsingEncoding:NSUTF8StringEncoding];
    if (data.length == 0) { return @{}; }
    id object = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
    return [object isKindOfClass:NSDictionary.class] ? object : @{};
}

- (void)userContentController:(WKUserContentController *)userContentController
      didReceiveScriptMessage:(WKScriptMessage *)message {
    if (!message.frameInfo.isMainFrame) {
#if DEBUG
        NSLog(@"[YKStoreFlow] bridge rejected: message is not from main frame");
#endif
        return;
    }
    if (![[YKHostedContentBridge channels] containsObject:message.name]) {
#if DEBUG
        NSLog(@"[YKStoreFlow] bridge rejected: unknown channel");
#endif
        return;
    }
    [self.yk_delegate hostedContentBridgeDidReceiveChannel:message.name
                                                   payload:[self yk_dictionaryFromBody:message.body]];
}

@end
