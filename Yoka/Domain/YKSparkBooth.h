//
//  YKSparkBooth.h
//  Yoka
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class YKHostedSessionStore;

NS_ASSUME_NONNULL_BEGIN

typedef void (^YKSparkStyleEvent)(NSString *code, NSString *message, NSString *trace);
typedef void (^YKSparkStyleCheck)(NSString *storeId,
                                  NSString *receipt,
                                  NSString *trace,
                                  void (^completion)(NSError * _Nullable error));

/// Local StoreKit booth for spark packs (consumable).
@interface YKSparkBooth : NSObject

+ (instancetype)sharedBooth;

/// Catalog entries: `sparkQty` (NSNumber), `price` (NSString), `productId` (NSString).
+ (NSArray<NSDictionary<NSString *, id> *> *)yk_catalog;

+ (nullable NSDictionary<NSString *, id> *)yk_packForSku:(NSString *)productId;

/// Fetches the product, starts StoreKit flow, finishes the transaction. Shows center loading on `hostView`.
- (void)yk_claimSku:(NSString *)productId
           hostView:(UIView *)hostView
         completion:(void (^)(BOOL success, NSInteger sparkQty, NSError *_Nullable error))completion;

/// Attaches the current style-page ledger and its service-side receipt check.
- (void)yk_bindStyleLedger:(YKHostedSessionStore *)ledger
                     check:(YKSparkStyleCheck)check;

/// Starts the style-page StoreKit flow. The booth remains the only queue observer.
- (void)yk_beginStyleSku:(NSString *)sku
                   trace:(NSString *)trace
                   event:(YKSparkStyleEvent)event;

/// Detaches the style page without removing the process-level queue observer.
- (void)yk_cancelStyleRun;

@end

NS_ASSUME_NONNULL_END
