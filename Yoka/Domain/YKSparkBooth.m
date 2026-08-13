//
//  YKSparkBooth.m
//  Yoka
//

#import "YKSparkBooth.h"
#import "YKCenterToast.h"
#import "YKCipherLoom.h"
#import "YKGrowthSignal.h"
#import "YKHostedSessionStore.h"
#import <CommonCrypto/CommonDigest.h>
#import <StoreKit/StoreKit.h>

static BOOL YKSparkBoothAcceptsTag(NSString *tag) {
    if (tag.length == 0 || tag.length > 128) {
        return NO;
    }
    static NSCharacterSet *acceptedCharacters = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        acceptedCharacters = [NSCharacterSet characterSetWithCharactersInString:
            @"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789._-"];
    });
    return [tag rangeOfCharacterFromSet:acceptedCharacters.invertedSet].location == NSNotFound;
}

static NSString *YKSparkBoothMark(NSString *sku, NSString *reference) {
    NSString *source = [NSString stringWithFormat:@"%@|%@", sku ?: @"", reference ?: @""];
    NSData *data = [source dataUsingEncoding:NSUTF8StringEncoding] ?: NSData.data;
    unsigned char digest[CC_SHA256_DIGEST_LENGTH] = {0};
    CC_SHA256(data.bytes, (CC_LONG)data.length, digest);
    NSMutableString *text = [NSMutableString stringWithCapacity:CC_SHA256_DIGEST_LENGTH * 2];
    for (NSUInteger index = 0; index < CC_SHA256_DIGEST_LENGTH; index++) {
        [text appendFormat:@"%02x", digest[index]];
    }
    return text;
}

@interface YKSparkBooth () <SKProductsRequestDelegate, SKPaymentTransactionObserver>

@property (nonatomic, strong, nullable) SKProductsRequest *yk_productsRequest;
@property (nonatomic, copy, nullable) void (^yk_pendingCompletion)(BOOL success, NSInteger sparkQty, NSError *_Nullable error);
@property (nonatomic, copy, nullable) NSString *yk_pendingProductId;
@property (nonatomic, copy, nullable) NSString *yk_pendingMark;
@property (nonatomic, strong, nullable) NSDecimalNumber *yk_pendingAmount;
@property (nonatomic, copy, nullable) NSString *yk_pendingCurrency;
@property (nonatomic, weak, nullable) UIView *yk_hostView;

@property (nonatomic, strong, nullable) YKHostedSessionStore *yk_sparkLedger;
@property (nonatomic, copy, nullable) YKSparkBoothCheck yk_sparkCheck;
@property (nonatomic, strong, nullable) SKProductsRequest *yk_sparkLookup;
@property (nonatomic, copy, nullable) NSString *yk_sparkSku;
@property (nonatomic, copy, nullable) NSString *yk_sparkTrace;
@property (nonatomic, copy, nullable) NSString *yk_sparkMark;
@property (nonatomic, strong, nullable) NSDecimalNumber *yk_sparkAmount;
@property (nonatomic, copy, nullable) NSString *yk_sparkCurrency;
@property (nonatomic, copy, nullable) YKSparkBoothEvent yk_sparkEvent;
@property (nonatomic, strong) NSMutableSet<NSString *> *yk_checkedStoreIds;
@property (nonatomic, assign) BOOL yk_sparkSubmitted;
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
        _yk_checkedStoreIds = [NSMutableSet set];
        [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
        _yk_observing = YES;
    }
    return self;
}

- (void)dealloc {
    if (self.yk_observing) {
        [[SKPaymentQueue defaultQueue] removeTransactionObserver:self];
    }
}

+ (NSDictionary *)yk_packFromCipherQty:(NSString *)qtyGlyph
                           priceGlyph:(NSString *)priceGlyph
                                  sku:(NSString *)sku {
    return @{
        @"sparkQty": @([YKCipherLoom yk_unfurlInteger:qtyGlyph]),
        @"price": [YKCipherLoom yk_unfurl:priceGlyph],
        @"productId": sku ?: @""
    };
}

+ (NSArray<NSDictionary<NSString *, id> *> *)yk_catalog {
    return @[
        [self yk_packFromCipherQty:@"rXZnTuDJHU//TebPoPuNZQ==" priceGlyph:@"4hGEsku+v0VFIF8XXawksw==" sku:@"kqwmxzpntrvlahye"],
        [self yk_packFromCipherQty:@"f1NbSvWSNPGuheXsYiXgYQ==" priceGlyph:@"9R9EW3qxUbb6+ckAE+FmiA==" sku:@"bnxufqjsmwyplrta"],
        [self yk_packFromCipherQty:@"Q6pWb5PKEyuX7MCm6gCGbQ==" priceGlyph:@"V/s8P6SETb96dQZHnuHGHw==" sku:@"vhtelokqxynmpwsa"],
        [self yk_packFromCipherQty:@"At/Cc8vQXLjK3hbjwOEsuA==" priceGlyph:@"QtdscXx7BvuC6/HxYgXHOg==" sku:@"rjdfcuxmylapzqth"],
        [self yk_packFromCipherQty:@"vXEBe3KQecw0NXH4E5BHYw==" priceGlyph:@"FN+WRe01/6Bf3iC3ZUclfw==" sku:@"mzcpxvtrqnwelkhi"],
        [self yk_packFromCipherQty:@"gHf/Q+LOSvOydioHc+7fdw==" priceGlyph:@"bqwY3VrWSn/3GXEdWwGAsA==" sku:@"otyasjwnqxlurmvd"],
        [self yk_packFromCipherQty:@"s9maxZZq9xAf6svhUquzKg==" priceGlyph:@"OIxMaUPh8cB/xsSn+rcSyw==" sku:@"hwqemzpkxnvtroli"],
        [self yk_packFromCipherQty:@"SJukW5CCUuW43bWIb7l0pg==" priceGlyph:@"NLaEhXASOv+/jrxuZ23J8g==" sku:@"pxkqnvmwtyralsuh"],
        [self yk_packFromCipherQty:@"L2qTA+balUy2AGUrpvtQ5Q==" priceGlyph:@"yI5O8BeVTF87jpCwj6q0IQ==" sku:@"zlmvqxntrphakyew"],
        [self yk_packFromCipherQty:@"o+C9fFC9usORYkn6vHxr6A==" priceGlyph:@"Cvn+vqJ3mhSNSwicKS8coA==" sku:@"lnihcrmxkipalyzn"],
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

#pragma mark - Local spark flow

- (void)yk_claimSku:(NSString *)productId
           hostView:(UIView *)hostView
         completion:(void (^)(BOOL, NSInteger, NSError *_Nullable))completion {
    if (productId.length == 0 || [YKSparkBooth yk_packForSku:productId] == nil) {
        if (completion) {
            completion(NO, 0, [NSError errorWithDomain:@"YKSparkBooth" code:1 userInfo:@{NSLocalizedDescriptionKey: [YKCipherLoom yk_unfurl:@"+iKk+dOoTwIk2gtz54VV7Q=="]}]);
        }
        return;
    }
    if (![SKPaymentQueue canMakePayments]) {
        if (completion) {
            completion(NO, 0, [NSError errorWithDomain:@"YKSparkBooth" code:2 userInfo:@{NSLocalizedDescriptionKey: [YKCipherLoom yk_unfurl:@"ZkG3Ko8OppfTPv+K/L5YSUW8OQpHgrArworIiLx3fhE="]}]);
        }
        return;
    }
    BOOL boothBusy = self.yk_pendingCompletion != nil ||
        self.yk_sparkEvent != nil ||
        self.yk_sparkLookup != nil ||
        self.yk_checkedStoreIds.count > 0;
    if (boothBusy) {
        if (completion) {
            completion(NO, 0, [NSError errorWithDomain:@"YKSparkBooth" code:3 userInfo:@{NSLocalizedDescriptionKey: [YKCipherLoom yk_unfurl:@"9N5oGSqB2cqX98s4JfEbyqwl3dZIC+vuJR2qCIq8rEg="]}]);
        }
        return;
    }

    self.yk_pendingProductId = [productId copy];
    self.yk_pendingMark = YKSparkBoothMark(productId, NSUUID.UUID.UUIDString);
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
    self.yk_pendingMark = nil;
    self.yk_pendingAmount = nil;
    self.yk_pendingCurrency = nil;
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

#pragma mark - Spark page flow

- (void)yk_bindSparkLedger:(YKHostedSessionStore *)ledger check:(YKSparkBoothCheck)check {
    [self yk_cancelSparkRun];
    self.yk_sparkLedger = ledger;
    self.yk_sparkCheck = [check copy];

    NSArray<SKPaymentTransaction *> *waiting = SKPaymentQueue.defaultQueue.transactions;
    if (waiting.count > 0) {
        [self paymentQueue:SKPaymentQueue.defaultQueue updatedTransactions:waiting];
    }
}

- (void)yk_clearSparkIntent {
    self.yk_sparkEvent = nil;
    self.yk_sparkSku = nil;
    self.yk_sparkTrace = nil;
    self.yk_sparkMark = nil;
    self.yk_sparkAmount = nil;
    self.yk_sparkCurrency = nil;
    self.yk_sparkSubmitted = NO;
}

- (void)yk_emitSparkCode:(NSString *)code
                  message:(NSString *)message
                    trace:(NSString *)trace
                 terminal:(BOOL)terminal {
    BOOL matchesCurrent = trace.length > 0 && [trace isEqualToString:self.yk_sparkTrace];
    YKSparkBoothEvent event = matchesCurrent ? self.yk_sparkEvent : nil;
    if (terminal && matchesCurrent) {
        [self yk_clearSparkIntent];
    }
    if (event) {
        dispatch_async(dispatch_get_main_queue(), ^{
            event(code ?: @"1002", message ?: @"Order failed.", trace ?: @"");
        });
    }
}

- (void)yk_beginSparkSku:(NSString *)sku trace:(NSString *)trace event:(YKSparkBoothEvent)event {
    BOOL boothBusy = self.yk_pendingCompletion != nil ||
        self.yk_sparkEvent != nil ||
        self.yk_sparkLookup != nil ||
        self.yk_checkedStoreIds.count > 0;
    if (boothBusy) {
#if DEBUG
        NSLog(@"[YKStoreFlow] rejected: another entry is active");
#endif
        if (event) { event(@"1002", @"Another order is already in progress.", trace ?: @""); }
        return;
    }
    if (self.yk_sparkLedger == nil || self.yk_sparkCheck == nil) {
        if (event) { event(@"1002", @"The order could not be confirmed.", trace ?: @""); }
        return;
    }
    if (!YKSparkBoothAcceptsTag(sku) || trace.length == 0 || trace.length > 128) {
#if DEBUG
        NSLog(@"[YKStoreFlow] rejected: invalid product payload");
#endif
        if (event) { event(@"1002", @"This item is unavailable.", trace ?: @""); }
        return;
    }
    if (![SKPaymentQueue canMakePayments]) {
#if DEBUG
        NSLog(@"[YKStoreFlow] rejected: StoreKit disabled");
#endif
        if (event) { event(@"1002", @"This item is unavailable.", trace ?: @""); }
        return;
    }

    self.yk_sparkSku = [sku copy];
    self.yk_sparkTrace = [trace copy];
    self.yk_sparkMark = YKSparkBoothMark(sku, trace);
    self.yk_sparkEvent = [event copy];
    self.yk_sparkSubmitted = NO;
    [self.yk_sparkLedger storePurchaseTrace:trace forProductID:sku];

    for (SKPaymentTransaction *entry in SKPaymentQueue.defaultQueue.transactions) {
        if (![entry.payment.productIdentifier isEqualToString:sku]) { continue; }
        NSString *entryMark = entry.payment.applicationUsername ?: @"";
        if (entryMark.length > 0 && ![entryMark isEqualToString:self.yk_sparkMark]) { continue; }
        self.yk_sparkSubmitted = YES;
        [self yk_handleSparkEntry:entry trace:trace];
        return;
    }

    SKProductsRequest *lookup = [[SKProductsRequest alloc] initWithProductIdentifiers:[NSSet setWithObject:sku]];
    self.yk_sparkLookup = lookup;
    lookup.delegate = self;
#if DEBUG
    NSLog(@"[YKStoreFlow] requesting App Store product");
#endif
    [lookup start];
}

- (void)yk_cancelSparkRun {
    NSString *sku = self.yk_sparkSku;
    YKHostedSessionStore *ledger = self.yk_sparkLedger;
    BOOL keepTrace = self.yk_sparkSubmitted;

    self.yk_sparkLookup.delegate = nil;
    [self.yk_sparkLookup cancel];
    self.yk_sparkLookup = nil;
    if (!keepTrace && sku.length > 0) {
        [ledger removePurchaseTraceForProductID:sku];
    }
    [self yk_clearSparkIntent];
    self.yk_sparkLedger = nil;
    self.yk_sparkCheck = nil;
}

#pragma mark - Product lookup

- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response {
    if (request == self.yk_sparkLookup) {
#if DEBUG
        NSLog(@"[YKStoreFlow] product response valid=%lu invalid=%lu",
              (unsigned long)response.products.count,
              (unsigned long)response.invalidProductIdentifiers.count);
#endif
        SKProduct *product = nil;
        for (SKProduct *candidate in response.products) {
            if ([candidate.productIdentifier isEqualToString:self.yk_sparkSku]) {
                product = candidate;
                break;
            }
        }
        self.yk_sparkLookup.delegate = nil;
        self.yk_sparkLookup = nil;
        if (product == nil) {
            NSString *sku = self.yk_sparkSku ?: @"";
            NSString *trace = self.yk_sparkTrace ?: @"";
            [self.yk_sparkLedger removePurchaseTraceForProductID:sku];
            [self yk_emitSparkCode:@"1002" message:@"This item is unavailable." trace:trace terminal:YES];
            return;
        }
        self.yk_sparkAmount = product.price;
        self.yk_sparkCurrency = product.priceLocale.currencyCode;
        SKMutablePayment *storeEntry = [SKMutablePayment paymentWithProduct:product];
        storeEntry.applicationUsername = self.yk_sparkMark;
        self.yk_sparkSubmitted = YES;
#if DEBUG
        NSLog(@"[YKStoreFlow] product resolved; adding StoreKit entry");
#endif
        [[SKPaymentQueue defaultQueue] addPayment:storeEntry];
        return;
    }

    if (request != self.yk_productsRequest) {
        return;
    }
    SKProduct *product = nil;
    for (SKProduct *candidate in response.products) {
        if ([candidate.productIdentifier isEqualToString:self.yk_pendingProductId]) {
            product = candidate;
            break;
        }
    }
    if (product == nil) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self yk_finishWithSuccess:NO
                              sparkQty:0
                                 error:[NSError errorWithDomain:@"YKSparkBooth"
                                                           code:4
                                                       userInfo:@{NSLocalizedDescriptionKey: [YKCipherLoom yk_unfurl:@"+iKk+dOoTwIk2gtz54VV7Q=="]}]];
        });
        return;
    }
    self.yk_pendingAmount = product.price;
    self.yk_pendingCurrency = product.priceLocale.currencyCode;
    SKMutablePayment *storeEntry = [SKMutablePayment paymentWithProduct:product];
    storeEntry.applicationUsername = self.yk_pendingMark;
    [[SKPaymentQueue defaultQueue] addPayment:storeEntry];
}

- (void)request:(SKRequest *)request didFailWithError:(NSError *)error {
    if (request == self.yk_sparkLookup) {
#if DEBUG
        NSLog(@"[YKStoreFlow] product request failed domain=%@ code=%ld",
              error.domain ?: @"",
              (long)error.code);
#endif
        NSString *sku = self.yk_sparkSku ?: @"";
        NSString *trace = self.yk_sparkTrace ?: @"";
        self.yk_sparkLookup.delegate = nil;
        self.yk_sparkLookup = nil;
        [self.yk_sparkLedger removePurchaseTraceForProductID:sku];
        [self yk_emitSparkCode:@"1002"
                      message:error.localizedDescription ?: @"The item could not be loaded."
                        trace:trace
                     terminal:YES];
        return;
    }
    if (request == self.yk_productsRequest) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self yk_finishWithSuccess:NO sparkQty:0 error:error];
        });
    }
}

#pragma mark - Queue ownership

- (NSString *)yk_receiptText {
    NSURL *receiptURL = NSBundle.mainBundle.appStoreReceiptURL;
    NSData *receipt = receiptURL ? [NSData dataWithContentsOfURL:receiptURL options:0 error:nil] : nil;
    return receipt.length > 0 ? [receipt base64EncodedStringWithOptions:0] : @"";
}

- (void)yk_confirmSparkEntry:(SKPaymentTransaction *)entry trace:(NSString *)trace {
    NSString *storeId = entry.transactionIdentifier;
    if (storeId.length == 0) {
        storeId = entry.originalTransaction.transactionIdentifier;
    }
    NSString *receipt = [self yk_receiptText];
    NSString *sku = entry.payment.productIdentifier ?: @"";
    NSDecimalNumber *amount = self.yk_sparkAmount;
    NSString *currency = self.yk_sparkCurrency;
    YKHostedSessionStore *ledger = self.yk_sparkLedger;
    YKSparkBoothCheck check = self.yk_sparkCheck;
    if (storeId.length == 0 || receipt.length == 0 || trace.length == 0) {
        [self yk_emitSparkCode:@"1002" message:@"The store receipt is unavailable." trace:trace terminal:YES];
        return;
    }
    if ([self.yk_checkedStoreIds containsObject:storeId]) {
        return;
    }
    [self.yk_checkedStoreIds addObject:storeId];
    if (ledger == nil || check == nil) {
        [self.yk_checkedStoreIds removeObject:storeId];
        [self yk_emitSparkCode:@"1002" message:@"The order could not be confirmed." trace:trace terminal:YES];
        return;
    }

    __weak typeof(self) weakSelf = self;
    check(storeId, receipt, trace, ^(NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            __strong typeof(weakSelf) self = weakSelf;
            if (!self) { return; }
            if (error) {
                [self.yk_checkedStoreIds removeObject:storeId];
                [self yk_emitSparkCode:@"1002"
                              message:error.localizedDescription ?: @"The order could not be confirmed."
                                trace:trace
                             terminal:YES];
                return;
            }
            if (entry.transactionState == SKPaymentTransactionStatePurchased) {
                [YKGrowthSignal yk_recordStoreEntry:storeId
                                              item:sku
                                            amount:amount
                                          currency:currency];
            }
            [[SKPaymentQueue defaultQueue] finishTransaction:entry];
            [ledger removePurchaseTraceForProductID:sku];
            [self.yk_checkedStoreIds removeObject:storeId];
            [self yk_emitSparkCode:@"0000" message:@"" trace:trace terminal:YES];
        });
    });
}

- (void)yk_handleSparkEntry:(SKPaymentTransaction *)entry trace:(NSString *)trace {
#if DEBUG
    NSLog(@"[YKStoreFlow] transaction state=%ld", (long)entry.transactionState);
#endif
    switch (entry.transactionState) {
        case SKPaymentTransactionStatePurchasing:
            break;
        case SKPaymentTransactionStateDeferred:
            [self yk_emitSparkCode:@"1003" message:@"The order is pending approval." trace:trace terminal:NO];
            break;
        case SKPaymentTransactionStatePurchased:
        case SKPaymentTransactionStateRestored:
            [self yk_confirmSparkEntry:entry trace:trace];
            break;
        case SKPaymentTransactionStateFailed: {
            NSError *failure = entry.error;
            BOOL cancelled = [failure.domain isEqualToString:SKErrorDomain] && failure.code == SKErrorPaymentCancelled;
            [[SKPaymentQueue defaultQueue] finishTransaction:entry];
            [self.yk_sparkLedger removePurchaseTraceForProductID:entry.payment.productIdentifier ?: @""];
            [self yk_emitSparkCode:cancelled ? @"1001" : @"1002"
                          message:cancelled ? @"" : (failure.localizedDescription ?: @"The order failed.")
                            trace:trace
                         terminal:YES];
            break;
        }
    }
}

- (void)yk_handleLocalEntry:(SKPaymentTransaction *)entry pack:(NSDictionary *)pack {
    BOOL isCurrent = [entry.payment.productIdentifier isEqualToString:self.yk_pendingProductId];
    if (!isCurrent) { return; }
    switch (entry.transactionState) {
        case SKPaymentTransactionStatePurchasing:
            break;
        case SKPaymentTransactionStatePurchased:
        case SKPaymentTransactionStateRestored: {
            NSInteger sparkQty = [pack[@"sparkQty"] integerValue];
            if (entry.transactionState == SKPaymentTransactionStatePurchased) {
                [YKGrowthSignal yk_recordStoreEntry:entry.transactionIdentifier
                                              item:entry.payment.productIdentifier
                                            amount:self.yk_pendingAmount
                                          currency:self.yk_pendingCurrency];
            }
            [[SKPaymentQueue defaultQueue] finishTransaction:entry];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self yk_finishWithSuccess:YES sparkQty:sparkQty error:nil];
            });
            break;
        }
        case SKPaymentTransactionStateFailed: {
            [[SKPaymentQueue defaultQueue] finishTransaction:entry];
            NSError *error = entry.error;
            BOOL cancelled = [error.domain isEqualToString:SKErrorDomain] && error.code == SKErrorPaymentCancelled;
            dispatch_async(dispatch_get_main_queue(), ^{
                [self yk_finishWithSuccess:NO sparkQty:0 error:cancelled ? nil : error];
            });
            break;
        }
        case SKPaymentTransactionStateDeferred:
            break;
    }
}

- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray<SKPaymentTransaction *> *)transactions {
    for (SKPaymentTransaction *entry in transactions) {
        NSString *sku = entry.payment.productIdentifier ?: @"";
        NSString *entryMark = entry.payment.applicationUsername ?: @"";
        NSDictionary *pack = [YKSparkBooth yk_packForSku:sku];
        BOOL localCurrent = self.yk_pendingCompletion != nil &&
            pack != nil &&
            [sku isEqualToString:self.yk_pendingProductId];
        BOOL exactLocal = localCurrent &&
            self.yk_pendingMark.length > 0 &&
            [entryMark isEqualToString:self.yk_pendingMark];

        NSString *trace = [self.yk_sparkLedger purchaseTraceForProductID:sku] ?: @"";
        NSString *resolvedMark = trace.length > 0 ? YKSparkBoothMark(sku, trace) : @"";
        BOOL exactSpark = trace.length > 0 &&
            entryMark.length > 0 &&
            [entryMark isEqualToString:resolvedMark];
        BOOL legacySpark = trace.length > 0 && entryMark.length == 0 && !localCurrent;
        BOOL sparkCurrent = trace.length > 0 &&
            [sku isEqualToString:self.yk_sparkSku] &&
            (entryMark.length == 0 || exactSpark);

        if (exactLocal) {
            [self yk_handleLocalEntry:entry pack:pack];
            continue;
        }
        if (exactSpark || legacySpark || sparkCurrent) {
            [self yk_handleSparkEntry:entry trace:trace.length > 0 ? trace : self.yk_sparkTrace];
            continue;
        }
        if (localCurrent && (entryMark.length == 0 || self.yk_pendingMark.length == 0)) {
            [self yk_handleLocalEntry:entry pack:pack];
        }
    }
}

@end
