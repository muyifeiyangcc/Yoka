//
//  YKSparkBooth.h
//  Yoka
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

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

@end

NS_ASSUME_NONNULL_END
