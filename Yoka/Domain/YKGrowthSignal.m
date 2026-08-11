//
//  YKGrowthSignal.m
//  Yoka
//

#import "YKGrowthSignal.h"
#import <AdjustSdk/AdjustSdk.h>
#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <CommonCrypto/CommonDigest.h>

static NSString *const YKSignalApplicationKey = @"gz4nbzwgk1z4";
static NSString *const YKFirstArrivalRoute = @"gkifuh";
static NSString *const YKCompletedStoreRoute = @"s2wh69";
static NSString *const YKFacebookApplicationNumber = @"1751779865951605";
static NSString *const YKFacebookClientMark = @"2917afd96e342371e823574a892cbf75";
static NSString *const YKFacebookDisplayTitle = @"Yoka";
static NSString *const YKFirstArrivalMark = @"YKFirstArrivalSignalV1";
static NSString *const YKStoreRelayLedger = @"YKStoreRelayLedgerV1";
static NSUInteger const YKStoreRelayLedgerLimit = 100;

@implementation YKGrowthSignal

+ (BOOL)yk_hasFacebookConfiguration {
    return FBSDKSettings.sharedSettings.appID.length > 0 &&
        FBSDKSettings.sharedSettings.clientToken.length > 0;
}

+ (NSString *)yk_storeRelayMark:(NSString *)reference {
    NSData *source = [reference dataUsingEncoding:NSUTF8StringEncoding];
    if (source.length == 0) { return @""; }
    unsigned char digest[CC_SHA256_DIGEST_LENGTH] = {0};
    CC_SHA256(source.bytes, (CC_LONG)source.length, digest);
    NSMutableString *mark = [NSMutableString stringWithCapacity:CC_SHA256_DIGEST_LENGTH * 2];
    for (NSUInteger index = 0; index < CC_SHA256_DIGEST_LENGTH; index++) {
        [mark appendFormat:@"%02x", digest[index]];
    }
    return mark;
}

+ (BOOL)yk_storeRelayAlreadyRecorded:(NSString *)reference {
    NSString *mark = [self yk_storeRelayMark:reference];
    if (mark.length == 0) { return NO; }
    NSArray *stored = [NSUserDefaults.standardUserDefaults arrayForKey:YKStoreRelayLedger];
    return [stored containsObject:mark];
}

+ (void)yk_rememberStoreRelay:(NSString *)reference {
    NSString *mark = [self yk_storeRelayMark:reference];
    if (mark.length == 0) { return; }
    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    NSMutableArray<NSString *> *ledger = [[defaults arrayForKey:YKStoreRelayLedger] mutableCopy]
        ?: [NSMutableArray array];
    [ledger removeObject:mark];
    [ledger addObject:mark];
    while (ledger.count > YKStoreRelayLedgerLimit) {
        [ledger removeObjectAtIndex:0];
    }
    [defaults setObject:ledger forKey:YKStoreRelayLedger];
}

+ (void)yk_activateForApplication:(UIApplication *)application
                    launchOptions:(NSDictionary *)launchOptions {
#if DEBUG
    NSString *environment = ADJEnvironmentSandbox;
#else
    NSString *environment = ADJEnvironmentProduction;
#endif

    ADJConfig *configuration = [[ADJConfig alloc] initWithAppToken:YKSignalApplicationKey
                                                       environment:environment];
    if (configuration != nil && configuration.isValid) {
        configuration.eventDeduplicationIdsMaxSize = 100;
        [Adjust initSdk:configuration];

        NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
        if (![defaults boolForKey:YKFirstArrivalMark]) {
            ADJEvent *firstArrival = [[ADJEvent alloc] initWithEventToken:YKFirstArrivalRoute];
            if (firstArrival != nil && firstArrival.isValid) {
                [Adjust trackEvent:firstArrival];
                [defaults setBool:YES forKey:YKFirstArrivalMark];
            }
        }
    }

    if (YKFacebookApplicationNumber.length == 0 || YKFacebookClientMark.length == 0) {
        return;
    }

    FBSDKSettings *settings = FBSDKSettings.sharedSettings;
    settings.appID = YKFacebookApplicationNumber;
    settings.clientToken = YKFacebookClientMark;
    settings.displayName = YKFacebookDisplayTitle;
    settings.isAutoLogAppEventsEnabled = NO;
    settings.isAdvertiserIDCollectionEnabled = NO;
    [FBSDKApplicationDelegate.sharedInstance application:application
                         didFinishLaunchingWithOptions:launchOptions];
}

+ (void)yk_recordActiveSession {
    if (![self yk_hasFacebookConfiguration]) { return; }
    [FBSDKAppEvents.shared activateApp];
}

+ (void)yk_forwardRemoteDeviceToken:(NSData *)deviceToken {
    if (![self yk_hasFacebookConfiguration] || deviceToken.length == 0) { return; }
    [FBSDKAppEvents.shared setPushNotificationsDeviceToken:deviceToken];
}

+ (void)yk_recordFacebookStoreEntry:(NSString *)reference
                               item:(NSString *)item
                             amount:(NSDecimalNumber *)amount
                           currency:(NSString *)currency {
    if (![self yk_hasFacebookConfiguration] || reference.length == 0 ||
        [self yk_storeRelayAlreadyRecorded:reference]) {
        return;
    }
    NSMutableDictionary<FBSDKAppEventParameterName, id> *parameters = [NSMutableDictionary dictionary];
    parameters[FBSDKAppEventParameterNameTransactionID] = reference;
    if (item.length > 0) {
        parameters[FBSDKAppEventParameterNameContentID] = item;
    }
    [FBSDKAppEvents.shared logPurchase:amount.doubleValue
                              currency:currency
                            parameters:parameters];
    [self yk_rememberStoreRelay:reference];
}

+ (void)yk_recordStoreEntry:(NSString *)reference
                       item:(NSString *)item
                     amount:(NSDecimalNumber *)amount
                   currency:(NSString *)currency {
    NSString *currencyCode = currency.uppercaseString;
    if (amount == nil || currencyCode.length != 3) {
        return;
    }
    ADJEvent *event = [[ADJEvent alloc] initWithEventToken:YKCompletedStoreRoute];
    if (event != nil && event.isValid) {
        [event setRevenue:amount.doubleValue currency:currencyCode];
        if (reference.length > 0) {
            [event setTransactionId:reference];
            [event setDeduplicationId:reference];
        }
        if (item.length > 0) {
            [event setProductId:item];
        }
        [Adjust trackEvent:event];
    }
    [self yk_recordFacebookStoreEntry:reference
                                 item:item
                               amount:amount
                             currency:currencyCode];
}

@end
