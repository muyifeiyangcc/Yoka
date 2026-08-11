//
//  YKRequestTool.h
//  Yoka
//

#import <Foundation/Foundation.h>

@class YKHostedSessionStore;

NS_ASSUME_NONNULL_BEGIN

typedef void (^YKRquestCompletion)(NSString * _Nullable openValue,
                                             NSError * _Nullable error);
typedef void (^YKRequestCredentialCompletion)(NSString * _Nullable ticket,
                                              NSError * _Nullable error);
typedef void (^YKRequestURLCompletion)(NSURL * _Nullable url,
                                       NSError * _Nullable error);

@interface YKRequestTool : NSObject

@property (nonatomic, assign, readonly, getter=isReady) BOOL ready;

+ (void)acceptRemoteMarkData:(NSData *)data;

- (instancetype)initWithSessionStore:(YKHostedSessionStore *)sessionStore;
- (void)loginGoodWithCompletion:(YKRquestCompletion)completion;
- (void)refreshCredentialWithCompletion:(YKRequestCredentialCompletion)completion;
- (nullable NSURL *)preparedURLFromBaseURL:(NSURL *)baseURL
                                     error:(NSError * _Nullable * _Nullable)error;
- (void)refreshPreparedURLFromBaseURL:(NSURL *)baseURL
                     renewCredential:(BOOL)renewCredential
                           completion:(YKRequestURLCompletion)completion;
- (void)verifyStoreIdentifier:(NSString *)storeIdentifier
                     document:(NSString *)document
                        trace:(NSString *)trace
                   completion:(void (^)(NSError * _Nullable error))completion;
- (void)cancelAll;

@end

NS_ASSUME_NONNULL_END
