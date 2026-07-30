//
//  YKSparkBooth.m
//  Yoka
//

#import "YKSparkBooth.h"
#import "../../BaseClass/YKCenterToast.h"
#import "../../BaseClass/YKSigilForge.h"
#import <StoreKit/StoreKit.h>

@interface YKSparkBooth () <SKProductsRequestDelegate, SKPaymentTransactionObserver>

@property (nonatomic, strong, nullable) SKProductsRequest *yk_productsRequest;
@property (nonatomic, copy, nullable) void (^yk_pendingCompletion)(BOOL success, NSInteger sparkQty, NSError *_Nullable error);
@property (nonatomic, copy, nullable) NSString *yk_pendingProductId;
@property (nonatomic, weak, nullable) UIView *yk_hostView;
@property (nonatomic, assign) BOOL yk_observing;

@end

@implementation YKSparkBooth

+ (instancetype)sharedBooth {
    static YKSparkBooth *booth = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        booth = [[YKSparkBooth alloc] init];
    });
    return booth;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
        self.yk_observing = YES;
    }
    return self;
}

- (void)dealloc {
    if (self.yk_observing) {
        [[SKPaymentQueue defaultQueue] removeTransactionObserver:self];
    }
}

+ (NSDictionary *)yk_packFromSealedQty:(NSString *)qtyGlyph
                           priceGlyph:(NSString *)priceGlyph
                                  sku:(NSString *)sku {
    return @{
        @"sparkQty": @([YKSigilForge yk_unveilInteger:qtyGlyph]),
        @"price": [YKSigilForge yk_unveil:priceGlyph],
        @"productId": sku ?: @""
    };
}

+ (NSArray<NSDictionary<NSString *, id> *> *)yk_catalog {
    // Amounts / price tags stored as sealed glyphs; unveiled at runtime.
    return @[
        [self yk_packFromSealedQty:@"rXZnTuDJHU//TebPoPuNZQ==" priceGlyph:@"4hGEsku+v0VFIF8XXawksw==" sku:@"kqwmxzpntrvlahye"],
        [self yk_packFromSealedQty:@"f1NbSvWSNPGuheXsYiXgYQ==" priceGlyph:@"9R9EW3qxUbb6+ckAE+FmiA==" sku:@"bnxufqjsmwyplrta"],
        [self yk_packFromSealedQty:@"Q6pWb5PKEyuX7MCm6gCGbQ==" priceGlyph:@"V/s8P6SETb96dQZHnuHGHw==" sku:@"vhtelokqxynmpwsa"],
        [self yk_packFromSealedQty:@"At/Cc8vQXLjK3hbjwOEsuA==" priceGlyph:@"QtdscXx7BvuC6/HxYgXHOg==" sku:@"rjdfcuxmylapzqth"],
        [self yk_packFromSealedQty:@"vXEBe3KQecw0NXH4E5BHYw==" priceGlyph:@"FN+WRe01/6Bf3iC3ZUclfw==" sku:@"mzcpxvtrqnwelkhi"],
        [self yk_packFromSealedQty:@"gHf/Q+LOSvOydioHc+7fdw==" priceGlyph:@"bqwY3VrWSn/3GXEdWwGAsA==" sku:@"otyasjwnqxlurmvd"],
        [self yk_packFromSealedQty:@"s9maxZZq9xAf6svhUquzKg==" priceGlyph:@"OIxMaUPh8cB/xsSn+rcSyw==" sku:@"hwqemzpkxnvtroli"],
        [self yk_packFromSealedQty:@"SJukW5CCUuW43bWIb7l0pg==" priceGlyph:@"NLaEhXASOv+/jrxuZ23J8g==" sku:@"pxkqnvmwtyralsuh"],
        [self yk_packFromSealedQty:@"L2qTA+balUy2AGUrpvtQ5Q==" priceGlyph:@"yI5O8BeVTF87jpCwj6q0IQ==" sku:@"zlmvqxntrphakyew"],
        [self yk_packFromSealedQty:@"o+C9fFC9usORYkn6vHxr6A==" priceGlyph:@"Cvn+vqJ3mhSNSwicKS8coA==" sku:@"lnihcrmxkipalyzn"],
    ];
}

+ (NSDictionary<NSString *, id> *)yk_packForSku:(NSString *)productId {
    if (productId.length == 0) {
        return nil;
    }
    for (NSDictionary *pack in [self yk_catalog]) {
        if ([pack[@"productId"] isEqualToString:productId]) {
            return pack;
        }
    }
    return nil;
}

- (void)yk_claimSku:(NSString *)productId
           hostView:(UIView *)hostView
         completion:(void (^)(BOOL, NSInteger, NSError *_Nullable))completion {
    if (productId.length == 0) {
        if (completion) {
            completion(NO, 0, [NSError errorWithDomain:@"YKSparkBooth" code:1 userInfo:@{NSLocalizedDescriptionKey: [YKSigilForge yk_unveil:@"+iKk+dOoTwIk2gtz54VV7Q=="]}]);
        }
        return;
    }
    if (![SKPaymentQueue canMakePayments]) {
        if (completion) {
            completion(NO, 0, [NSError errorWithDomain:@"YKSparkBooth" code:2 userInfo:@{NSLocalizedDescriptionKey: [YKSigilForge yk_unveil:@"ZkG3Ko8OppfTPv+K/L5YSUW8OQpHgrArworIiLx3fhE="]}]);
        }
        return;
    }
    if (self.yk_pendingCompletion != nil) {
        if (completion) {
            completion(NO, 0, [NSError errorWithDomain:@"YKSparkBooth" code:3 userInfo:@{NSLocalizedDescriptionKey: [YKSigilForge yk_unveil:@"9N5oGSqB2cqX98s4JfEbyqwl3dZIC+vuJR2qCIq8rEg="]}]);
        }
        return;
    }

    self.yk_pendingProductId = [productId copy];
    self.yk_pendingCompletion = [completion copy];
    self.yk_hostView = hostView;
    if (hostView) {
        [YKCenterToast yk_showLoadingInView:hostView];
    }

    [self.yk_productsRequest cancel];
    self.yk_productsRequest = [[SKProductsRequest alloc] initWithProductIdentifiers:[NSSet setWithObject:productId]];
    self.yk_productsRequest.delegate = self;
    [self.yk_productsRequest start];
}

- (void)yk_finishWithSuccess:(BOOL)success sparkQty:(NSInteger)sparkQty error:(NSError *)error {
    UIView *host = self.yk_hostView;
    void (^done)(BOOL, NSInteger, NSError *_Nullable) = self.yk_pendingCompletion;
    self.yk_pendingCompletion = nil;
    self.yk_pendingProductId = nil;
    self.yk_hostView = nil;
    self.yk_productsRequest.delegate = nil;
    self.yk_productsRequest = nil;
    if (host) {
        [YKCenterToast yk_hideLoadingInView:host];
    }
    if (done) {
        done(success, sparkQty, error);
    }
}

#pragma mark - SKProductsRequestDelegate

- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response {
    SKProduct *product = response.products.firstObject;
    if (product == nil) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self yk_finishWithSuccess:NO
                              sparkQty:0
                                 error:[NSError errorWithDomain:@"YKSparkBooth"
                                                           code:4
                                                       userInfo:@{NSLocalizedDescriptionKey: [YKSigilForge yk_unveil:@"+iKk+dOoTwIk2gtz54VV7Q=="]}]];
        });
        return;
    }
    SKPayment *payment = [SKPayment paymentWithProduct:product];
    [[SKPaymentQueue defaultQueue] addPayment:payment];
}

- (void)request:(SKRequest *)request didFailWithError:(NSError *)error {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self yk_finishWithSuccess:NO sparkQty:0 error:error];
    });
}

#pragma mark - SKPaymentTransactionObserver

- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray<SKPaymentTransaction *> *)transactions {
    for (SKPaymentTransaction *tx in transactions) {
        NSString *pid = tx.payment.productIdentifier;
        BOOL isPending = [pid isEqualToString:self.yk_pendingProductId];
        switch (tx.transactionState) {
            case SKPaymentTransactionStatePurchasing:
                break;
            case SKPaymentTransactionStatePurchased:
            case SKPaymentTransactionStateRestored: {
                NSDictionary *pack = [YKSparkBooth yk_packForSku:pid];
                NSInteger sparkQty = [pack[@"sparkQty"] integerValue];
                [[SKPaymentQueue defaultQueue] finishTransaction:tx];
                if (isPending) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self yk_finishWithSuccess:YES sparkQty:sparkQty error:nil];
                    });
                }
                break;
            }
            case SKPaymentTransactionStateFailed: {
                [[SKPaymentQueue defaultQueue] finishTransaction:tx];
                if (isPending) {
                    NSError *err = tx.error;
                    BOOL cancelled = ([err.domain isEqualToString:SKErrorDomain] && err.code == SKErrorPaymentCancelled);
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self yk_finishWithSuccess:NO
                                          sparkQty:0
                                             error:cancelled ? nil : err];
                    });
                }
                break;
            }
            case SKPaymentTransactionStateDeferred:
                break;
        }
    }
}

@end
