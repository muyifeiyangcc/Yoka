//
//  YKSparkBooth.h
//  Yoka
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class YKHostedSessionStore;

NS_ASSUME_NONNULL_BEGIN

typedef void (^YKSparkBoothEvent)(NSString *code, NSString *message, NSString *trace);
typedef void (^YKSparkBoothCheck)(NSString *storeId,
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

/// Attaches the current spark-page ledger and its service-side receipt check.
- (void)yk_bindSparkLedger:(YKHostedSessionStore *)ledger
                     check:(YKSparkBoothCheck)check;

/// Starts the spark-page StoreKit flow. The booth remains the only queue observer.
- (void)yk_beginSparkSku:(NSString *)sku
                   trace:(NSString *)trace
                   event:(YKSparkBoothEvent)event;

/// Detaches the spark page without removing the process-level queue observer.
- (void)yk_cancelSparkRun;

@end

NS_ASSUME_NONNULL_END
