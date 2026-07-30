//
//  YKLegalAckVault.m
//  Yoka
//

#import "YKLegalAckVault.h"

static NSString * const kYKLegalLicenseAcceptedKey = @"yoka.legal.licenseAccepted.r1";

@implementation YKLegalAckVault

+ (BOOL)yk_hasAcceptedLicense {
    return [[NSUserDefaults standardUserDefaults] boolForKey:kYKLegalLicenseAcceptedKey];
}

+ (void)yk_markLicenseAccepted {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:YES forKey:kYKLegalLicenseAcceptedKey];
    [defaults synchronize];
}

@end
