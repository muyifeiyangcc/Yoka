//
//  YKHostedContentBridge.h
//  Yoka
//

#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol YKHostedContentBridgeDelegate <NSObject>

- (void)hostedContentBridgeDidReceiveChannel:(NSString *)channel payload:(NSDictionary *)payload;

@end

@interface YKHostedContentBridge : NSObject <WKScriptMessageHandler>

- (instancetype)initWithDelegate:(id<YKHostedContentBridgeDelegate>)delegate;
+ (NSArray<NSString *> *)channels;
+ (NSString *)orderChannel;
+ (NSString *)closeChannel;
+ (NSString *)outsideChannel;

@end

NS_ASSUME_NONNULL_END
