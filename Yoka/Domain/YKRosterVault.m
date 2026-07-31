//
//  YKRosterVault.m
//  Yoka
//

#import "YKRosterVault.h"
#import "YKPersonaCatalog.h"
#import "YKBondLedger.h"
#import "YKLaneVault.h"
#import "YKPublishLedger.h"
#import "YKPieceUnlockLedger.h"

NSNotificationName const YokaRosterPresenceDidShiftNotification = @"YokaRosterPresenceDidShiftNotification";

static NSString * const kYKBootPresenceActiveKey = @"yoka.gate.presenceActive.r1";
static NSString * const kYKBootDossierReadyKey = @"yoka.gate.dossierReady.r1";
static NSString * const kYKBootActiveMailboxKey = @"yoka.gate.activeMailbox.r1";
static NSString * const kYKBootActiveAppleIdKey = @"yoka.gate.activeAppleId.r1";
static NSString * const kYKMailboxSecretMapKey = @"yoka.roster.secretMap.r1";
static NSString * const kYKTombstoneMailListKey = @"yoka.roster.tombstoneMail.r1";
static NSString * const kYKTombstoneAppleListKey = @"yoka.roster.tombstoneApple.r1";
static NSString * const kYKAppleSnapMapKey = @"yoka.roster.appleSnaps.r1";
static NSString * const kYKDossierBundleMapKey = @"yoka.roster.dossierMap.r1";
static NSString * const kYKPortraitFolderName = @"yoka_roster_portraits";
static NSString * const kYKAppleAccountPrefix = @"apid:";

@implementation YKRosterVault

+ (instancetype)sharedRoster {
    static YKRosterVault *vault = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        vault = [[YKRosterVault alloc] init];
    });
    return vault;
}

+ (NSString *)yk_reviewMailbox {
    return @"yoka369@gmail.com";
}

+ (NSString *)yk_reviewSecret {
    return @"123456";
}

+ (BOOL)yk_isReviewMailbox:(NSString *)email {
    return [[self yk_normalizedMailbox:email] isEqualToString:[self yk_reviewMailbox]];
}

+ (NSString *)yk_normalizedMailbox:(NSString *)email {
    return [[email stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet] lowercaseString] ?: @"";
}

- (NSUserDefaults *)yk_defaults {
    return NSUserDefaults.standardUserDefaults;
}

- (void)yk_postPresenceShift {
    [[NSNotificationCenter defaultCenter] postNotificationName:YokaRosterPresenceDidShiftNotification object:nil];
}

- (NSMutableDictionary *)yk_mutableSecretMap {
    NSDictionary *map = [self.yk_defaults dictionaryForKey:kYKMailboxSecretMapKey] ?: @{};
    return [map mutableCopy];
}

- (NSMutableArray *)yk_mutableTombstones {
    NSArray *list = [self.yk_defaults arrayForKey:kYKTombstoneMailListKey] ?: @[];
    return [list mutableCopy];
}

- (NSMutableDictionary *)yk_mutableDossierMap {
    NSDictionary *map = [self.yk_defaults dictionaryForKey:kYKDossierBundleMapKey] ?: @{};
    return [map mutableCopy];
}

- (void)yk_persistSecretMap:(NSDictionary *)map {
    [self.yk_defaults setObject:map forKey:kYKMailboxSecretMapKey];
    [self.yk_defaults synchronize];
}

- (void)yk_persistTombstones:(NSArray *)list {
    [self.yk_defaults setObject:list forKey:kYKTombstoneMailListKey];
    [self.yk_defaults synchronize];
}

- (void)yk_persistDossierMap:(NSDictionary *)map {
    [self.yk_defaults setObject:map forKey:kYKDossierBundleMapKey];
    [self.yk_defaults synchronize];
}

#pragma mark - Presence

- (BOOL)yk_isPresenceActive {
    return [self.yk_defaults boolForKey:kYKBootPresenceActiveKey];
}

- (BOOL)yk_isDossierReady {
    return [self.yk_defaults boolForKey:kYKBootDossierReadyKey];
}

- (NSString *)yk_activeMailbox {
    return [self.yk_defaults stringForKey:kYKBootActiveMailboxKey];
}

- (void)yk_markDossierReady:(BOOL)ready {
    [self.yk_defaults setBool:ready forKey:kYKBootDossierReadyKey];
    NSString *mailbox = [self yk_activeMailbox];
    if (mailbox.length > 0) {
        NSMutableDictionary *dossiers = [self yk_mutableDossierMap];
        NSMutableDictionary *bundle = [([dossiers[mailbox] isKindOfClass:NSDictionary.class] ? dossiers[mailbox] : @{}) mutableCopy];
        bundle[@"profileReady"] = @(ready);
        dossiers[mailbox] = bundle;
        [self yk_persistDossierMap:dossiers];
    }
    [self.yk_defaults synchronize];
    [self yk_postPresenceShift];
}

/// Restore session profile-done from the per-account dossier (survives logout).
- (BOOL)yk_restoreDossierReadyFromBundle:(NSMutableDictionary *)bundle {
    if (![bundle isKindOfClass:NSMutableDictionary.class] && ![bundle isKindOfClass:NSDictionary.class]) {
        return NO;
    }
    if ([bundle[@"profileReady"] boolValue]) {
        return YES;
    }
    // Legacy accounts saved before profileReady existed: name + location means setup was completed.
    NSString *name = bundle[@"name"];
    NSString *location = bundle[@"location"];
    BOOL legacyDone = [name isKindOfClass:NSString.class] && name.length > 0 &&
        [location isKindOfClass:NSString.class] && location.length > 0;
    if (legacyDone) {
        bundle[@"profileReady"] = @YES;
        return YES;
    }
    return NO;
}

- (void)yk_activateMailbox:(NSString *)email {
    NSString *normalized = [YKRosterVault yk_normalizedMailbox:email];
    [self.yk_defaults setBool:YES forKey:kYKBootPresenceActiveKey];
    [self.yk_defaults setObject:normalized forKey:kYKBootActiveMailboxKey];
    [self.yk_defaults removeObjectForKey:kYKBootActiveAppleIdKey];
    if ([YKRosterVault yk_isReviewMailbox:normalized]) {
        [self.yk_defaults setBool:YES forKey:kYKBootDossierReadyKey];
        // Demo account is the review persona Nexy.
        NSMutableDictionary *dossiers = [self yk_mutableDossierMap];
        NSMutableDictionary *bundle = [([dossiers[normalized] isKindOfClass:NSDictionary.class] ? dossiers[normalized] : @{}) mutableCopy];
        if (![bundle[@"name"] isKindOfClass:NSString.class] || [bundle[@"name"] length] == 0) {
            bundle[@"name"] = [YKPersonaCatalog yk_reviewPersonaDisplayName];
        }
        bundle[@"personaId"] = [YKPersonaCatalog yk_reviewPersonaId];
        bundle[@"avatarAsset"] = [YKPersonaCatalog yk_reviewPersonaAvatarAsset];
        if (![bundle[@"birthday"] isKindOfClass:NSString.class] || [bundle[@"birthday"] length] == 0) {
            bundle[@"birthday"] = @"2000-01-01";
        }
        if (![bundle[@"location"] isKindOfClass:NSString.class] || [bundle[@"location"] length] == 0) {
            bundle[@"location"] = @"LA";
        }
        if (![bundle[@"gender"] isKindOfClass:NSString.class] || [bundle[@"gender"] length] == 0) {
            bundle[@"gender"] = @"Male";
        }
        dossiers[normalized] = bundle;
        [self yk_persistDossierMap:dossiers];
        [[YKBondLedger sharedLedger] yk_primeLinksForOwnerKey:[YKPersonaCatalog yk_reviewPersonaId]];
        [[YKLaneVault sharedVault] yk_seedReviewLinesForOwnerKey:[YKPersonaCatalog yk_reviewPersonaId]];
    } else {
        // Profile-done is per active account — never inherit another account's session flag.
        NSMutableDictionary *dossiers = [self yk_mutableDossierMap];
        NSMutableDictionary *bundle = [([dossiers[normalized] isKindOfClass:NSDictionary.class] ? dossiers[normalized] : @{}) mutableCopy];
        BOOL ready = [self yk_restoreDossierReadyFromBundle:bundle];
        if (ready) {
            dossiers[normalized] = bundle;
            [self yk_persistDossierMap:dossiers];
        }
        [self.yk_defaults setBool:ready forKey:kYKBootDossierReadyKey];
    }
    [self.yk_defaults synchronize];
    [self yk_postPresenceShift];
}

- (NSString *)yk_accountKeyForAppleUserId:(NSString *)appleUserId {
    return [kYKAppleAccountPrefix stringByAppendingString:appleUserId ?: @""];
}

- (NSMutableDictionary *)yk_mutableAppleSnaps {
    NSDictionary *map = [self.yk_defaults dictionaryForKey:kYKAppleSnapMapKey] ?: @{};
    return [map mutableCopy];
}

- (NSMutableArray *)yk_mutableAppleTombstones {
    NSArray *list = [self.yk_defaults arrayForKey:kYKTombstoneAppleListKey] ?: @[];
    return [list mutableCopy];
}

- (void)yk_persistAppleSnaps:(NSDictionary *)map {
    [self.yk_defaults setObject:map forKey:kYKAppleSnapMapKey];
    [self.yk_defaults synchronize];
}

- (void)yk_persistAppleTombstones:(NSArray *)list {
    [self.yk_defaults setObject:list forKey:kYKTombstoneAppleListKey];
    [self.yk_defaults synchronize];
}

#pragma mark - Mailbox auth

- (BOOL)yk_isMailboxTombstoned:(NSString *)email {
    NSString *normalized = [YKRosterVault yk_normalizedMailbox:email];
    return [[self.yk_defaults arrayForKey:kYKTombstoneMailListKey] containsObject:normalized];
}

- (BOOL)yk_mailboxExists:(NSString *)email {
    NSString *normalized = [YKRosterVault yk_normalizedMailbox:email];
    return [self.yk_mutableSecretMap objectForKey:normalized] != nil;
}

- (NSString *)yk_secretForMailbox:(NSString *)email {
    NSString *normalized = [YKRosterVault yk_normalizedMailbox:email];
    return self.yk_mutableSecretMap[normalized];
}

- (BOOL)yk_admitMailboxWithEmail:(NSString *)email secret:(NSString *)secret errorMessage:(NSString **)errorMessage {
    NSString *normalized = [YKRosterVault yk_normalizedMailbox:email];
    NSString *trimmedSecret = [secret stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet] ?: @"";
    if (normalized.length == 0 || trimmedSecret.length == 0) {
        if (errorMessage) { *errorMessage = @"Please enter email and password"; }
        return NO;
    }
    if ([self yk_isMailboxTombstoned:normalized]) {
        if (errorMessage) { *errorMessage = @"This account has been deleted"; }
        return NO;
    }
    if ([YKRosterVault yk_isReviewMailbox:normalized]) {
        if (![trimmedSecret isEqualToString:[YKRosterVault yk_reviewSecret]]) {
            if (errorMessage) { *errorMessage = @"Incorrect email or password"; }
            return NO;
        }
        [self yk_activateMailbox:normalized];
        return YES;
    }
    NSString *stored = [self yk_secretForMailbox:normalized];
    if (stored.length == 0 || ![stored isEqualToString:trimmedSecret]) {
        if (errorMessage) { *errorMessage = @"Incorrect email or password"; }
        return NO;
    }
    [self yk_activateMailbox:normalized];
    return YES;
}

- (BOOL)yk_registerMailboxWithEmail:(NSString *)email secret:(NSString *)secret errorMessage:(NSString **)errorMessage {
    NSString *normalized = [YKRosterVault yk_normalizedMailbox:email];
    NSString *trimmedSecret = [secret stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet] ?: @"";
    if (normalized.length == 0 || trimmedSecret.length == 0) {
        if (errorMessage) { *errorMessage = @"Please enter email and password"; }
        return NO;
    }
    if (![normalized containsString:@"@"]) {
        if (errorMessage) { *errorMessage = @"Please enter a valid email"; }
        return NO;
    }
    if ([YKRosterVault yk_isReviewMailbox:normalized]) {
        if (errorMessage) { *errorMessage = @"This email is reserved"; }
        return NO;
    }
    if ([self yk_mailboxExists:normalized] && ![self yk_isMailboxTombstoned:normalized]) {
        if (errorMessage) { *errorMessage = @"This email is already registered"; }
        return NO;
    }
    NSMutableDictionary *map = [self yk_mutableSecretMap];
    map[normalized] = trimmedSecret;
    [self yk_persistSecretMap:map];

    if ([self yk_isMailboxTombstoned:normalized]) {
        NSMutableArray *tombs = [self yk_mutableTombstones];
        [tombs removeObject:normalized];
        [self yk_persistTombstones:tombs];
        NSMutableDictionary *dossiers = [self yk_mutableDossierMap];
        [dossiers removeObjectForKey:normalized];
        [self yk_persistDossierMap:dossiers];
    }

    [self.yk_defaults setBool:NO forKey:kYKBootDossierReadyKey];
    [self yk_activateMailbox:normalized];
    [self.yk_defaults setBool:NO forKey:kYKBootDossierReadyKey];
    [self.yk_defaults synchronize];
    return YES;
}

- (BOOL)yk_replaceSecretForMailbox:(NSString *)email secret:(NSString *)secret errorMessage:(NSString **)errorMessage {
    NSString *normalized = [YKRosterVault yk_normalizedMailbox:email];
    NSString *trimmedSecret = [secret stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet] ?: @"";
    if (normalized.length == 0 || trimmedSecret.length == 0) {
        if (errorMessage) { *errorMessage = @"Please enter email and password"; }
        return NO;
    }
    if ([self yk_isMailboxTombstoned:normalized]) {
        if (errorMessage) { *errorMessage = @"This account has been deleted"; }
        return NO;
    }
    if ([YKRosterVault yk_isReviewMailbox:normalized]) {
        if (errorMessage) { *errorMessage = @"Demo account password cannot be changed"; }
        return NO;
    }
    if (![self yk_mailboxExists:normalized]) {
        if (errorMessage) { *errorMessage = @"Account not found"; }
        return NO;
    }
    NSMutableDictionary *map = [self yk_mutableSecretMap];
    map[normalized] = trimmedSecret;
    [self yk_persistSecretMap:map];
    return YES;
}

- (void)yk_clearPresence {
    [self.yk_defaults setBool:NO forKey:kYKBootPresenceActiveKey];
    [self.yk_defaults setBool:NO forKey:kYKBootDossierReadyKey];
    [self.yk_defaults removeObjectForKey:kYKBootActiveMailboxKey];
    [self.yk_defaults removeObjectForKey:kYKBootActiveAppleIdKey];
    [self.yk_defaults synchronize];
    [self yk_postPresenceShift];
}

- (void)yk_eraseActiveAccount {
    NSString *appleId = [self yk_activeAppleUserId];
    NSString *accountKey = [self yk_activeMailbox];
    if (accountKey.length == 0 && appleId.length == 0) {
        [self yk_clearPresence];
        return;
    }

    if (appleId.length > 0) {
        NSMutableArray *appleTombs = [self yk_mutableAppleTombstones];
        if (![appleTombs containsObject:appleId]) {
            [appleTombs addObject:appleId];
            [self yk_persistAppleTombstones:appleTombs];
        }
        NSMutableDictionary *snaps = [self yk_mutableAppleSnaps];
        [snaps removeObjectForKey:appleId];
        [self yk_persistAppleSnaps:snaps];
        accountKey = [self yk_accountKeyForAppleUserId:appleId];
    } else if (accountKey.length > 0) {
        if (![YKRosterVault yk_isReviewMailbox:accountKey]) {
            NSMutableDictionary *map = [self yk_mutableSecretMap];
            [map removeObjectForKey:accountKey];
            [self yk_persistSecretMap:map];
        }
        NSMutableArray *tombs = [self yk_mutableTombstones];
        if (![tombs containsObject:accountKey]) {
            [tombs addObject:accountKey];
            [self yk_persistTombstones:tombs];
        }
    }

    if (accountKey.length > 0) {
        NSMutableDictionary *dossiers = [self yk_mutableDossierMap];
        NSDictionary *old = dossiers[accountKey];
        NSString *portrait = old[@"portrait"];
        if ([portrait isKindOfClass:NSString.class] && portrait.length > 0) {
            NSString *path = [[self yk_portraitDirectoryPath] stringByAppendingPathComponent:portrait];
            [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
        }
        [dossiers removeObjectForKey:accountKey];
        [self yk_persistDossierMap:dossiers];

        NSString *publishOwner = [YKRosterVault yk_isReviewMailbox:accountKey] ? [YKPersonaCatalog yk_reviewPersonaId] : accountKey;
        [[YKPublishLedger sharedLedger] yk_eraseEntriesForOwnerKey:publishOwner];
        [[YKPieceUnlockLedger sharedLedger] yk_eraseUnlocksForOwnerKey:publishOwner];
        [[YKPieceUnlockLedger sharedLedger] yk_eraseUnlocksForOwnerKey:accountKey];
    }

    [self.yk_defaults setBool:NO forKey:kYKBootDossierReadyKey];
    [self yk_clearPresence];
}

#pragma mark - Apple

- (BOOL)yk_isAppleTombstoned:(NSString *)appleUserId {
    if (appleUserId.length == 0) {
        return NO;
    }
    return [[self.yk_defaults arrayForKey:kYKTombstoneAppleListKey] containsObject:appleUserId];
}

- (NSString *)yk_activeAppleUserId {
    return [self.yk_defaults stringForKey:kYKBootActiveAppleIdKey];
}

- (BOOL)yk_admitAppleWithUserId:(NSString *)appleUserId
                                email:(NSString *)email
                             fullName:(NSString *)fullName
                         errorMessage:(NSString **)errorMessage {
    if (appleUserId.length == 0) {
        if (errorMessage) { *errorMessage = @"Apple Sign In failed"; }
        return NO;
    }
    if ([self yk_isAppleTombstoned:appleUserId]) {
        if (errorMessage) { *errorMessage = @"This account has been deleted"; }
        return NO;
    }

    NSString *accountKey = [self yk_accountKeyForAppleUserId:appleUserId];
    NSMutableDictionary *snaps = [self yk_mutableAppleSnaps];
    NSDictionary *existing = snaps[appleUserId];
    BOOL isReturning = [existing isKindOfClass:NSDictionary.class];

    NSMutableDictionary *snap = [([existing isKindOfClass:NSDictionary.class] ? existing : @{}) mutableCopy];
    snap[@"userId"] = appleUserId;
    if (email.length > 0) {
        snap[@"email"] = [YKRosterVault yk_normalizedMailbox:email];
    }
    NSString *resolvedName = [fullName stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    if (resolvedName.length == 0) {
        NSString *stored = snap[@"fullName"];
        if ([stored isKindOfClass:NSString.class]) {
            resolvedName = [stored stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
        }
    }
    // Never invent a placeholder name — only keep a real Apple-provided name.
    if (resolvedName.length > 0 && ![resolvedName isEqualToString:@"Apple User"]) {
        snap[@"fullName"] = resolvedName;
    } else {
        resolvedName = @"";
        if ([snap[@"fullName"] isEqualToString:@"Apple User"]) {
            [snap removeObjectForKey:@"fullName"];
        }
    }
    snaps[appleUserId] = snap;
    [self yk_persistAppleSnaps:snaps];

    [self.yk_defaults setBool:YES forKey:kYKBootPresenceActiveKey];
    [self.yk_defaults setObject:accountKey forKey:kYKBootActiveMailboxKey];
    [self.yk_defaults setObject:appleUserId forKey:kYKBootActiveAppleIdKey];

    // Prefill dossier Name from Apple (first auth or restored snap) so profile setup need not retype it.
    NSMutableDictionary *dossiers = [self yk_mutableDossierMap];
    NSMutableDictionary *bundle = [([dossiers[accountKey] isKindOfClass:NSDictionary.class] ? dossiers[accountKey] : @{}) mutableCopy];
    NSString *dossierName = bundle[@"name"];
    BOOL hasDossierName = [dossierName isKindOfClass:NSString.class] && dossierName.length > 0;
    if (!hasDossierName && resolvedName.length > 0) {
        bundle[@"name"] = resolvedName;
        hasDossierName = YES;
    }

    // Logout clears the session ready flag; restore from this account's dossier.
    BOOL dossierReady = [self yk_restoreDossierReadyFromBundle:bundle];
    if (!isReturning) {
        dossierReady = NO;
        bundle[@"profileReady"] = @NO;
    }
    if (bundle.count > 0) {
        dossiers[accountKey] = bundle;
        [self yk_persistDossierMap:dossiers];
    }
    [self.yk_defaults setBool:dossierReady forKey:kYKBootDossierReadyKey];
    [self.yk_defaults synchronize];
    [self yk_postPresenceShift];
    return YES;
}

#pragma mark - Dossier / portrait

- (NSURL *)yk_portraitDirectoryURL {
    NSURL *docs = [[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask].firstObject;
    NSURL *dir = [docs URLByAppendingPathComponent:kYKPortraitFolderName isDirectory:YES];
    [[NSFileManager defaultManager] createDirectoryAtURL:dir withIntermediateDirectories:YES attributes:nil error:nil];
    return dir;
}

- (NSString *)yk_portraitDirectoryPath {
    return [self yk_portraitDirectoryURL].path;
}

- (NSDictionary *)yk_dossierForActiveMailbox {
    NSString *mailbox = [self yk_activeMailbox];
    if (mailbox.length == 0) {
        return nil;
    }
    return self.yk_mutableDossierMap[mailbox];
}

- (NSString *)yk_displayNameForActiveMailbox {
    NSDictionary *dossier = [self yk_dossierForActiveMailbox];
    NSString *name = dossier[@"name"];
    if ([name isKindOfClass:NSString.class] && name.length > 0) {
        return name;
    }
    NSString *appleId = [self yk_activeAppleUserId];
    if (appleId.length > 0) {
        NSDictionary *snap = self.yk_mutableAppleSnaps[appleId];
        NSString *fullName = snap[@"fullName"];
        if ([fullName isKindOfClass:NSString.class] &&
            fullName.length > 0 &&
            ![fullName isEqualToString:@"Apple User"]) {
            return fullName;
        }
    }
    if ([YKRosterVault yk_isReviewMailbox:[self yk_activeMailbox] ?: @""]) {
        return [YKPersonaCatalog yk_reviewPersonaDisplayName];
    }
    return @"Yoka User";
}

- (UIImage *)yk_portraitImageForActiveMailbox {
    NSDictionary *dossier = [self yk_dossierForActiveMailbox];
    NSString *file = dossier[@"portrait"];
    if ([file isKindOfClass:NSString.class] && file.length > 0) {
        NSString *path = [[self yk_portraitDirectoryPath] stringByAppendingPathComponent:file];
        UIImage *diskImage = [UIImage imageWithContentsOfFile:path];
        if (diskImage) {
            return diskImage;
        }
    }
    NSString *asset = dossier[@"avatarAsset"];
    if ([asset isKindOfClass:NSString.class] && asset.length > 0) {
        UIImage *bundled = [UIImage imageNamed:asset];
        if (bundled) {
            return bundled;
        }
    }
    if ([YKRosterVault yk_isReviewMailbox:[self yk_activeMailbox] ?: @""]) {
        return [YKPersonaCatalog yk_avatarImageForPersonaId:[YKPersonaCatalog yk_reviewPersonaId]];
    }
    return nil;
}

- (void)yk_saveDossierName:(NSString *)name
                  birthday:(NSString *)birthday
                  location:(NSString *)location
                    gender:(NSString *)gender
             portraitImage:(UIImage *)portraitImage {
    NSString *mailbox = [self yk_activeMailbox];
    if (mailbox.length == 0) {
        return;
    }
    NSMutableDictionary *dossiers = [self yk_mutableDossierMap];
    NSMutableDictionary *bundle = [([dossiers[mailbox] isKindOfClass:NSDictionary.class] ? dossiers[mailbox] : @{}) mutableCopy];
    bundle[@"name"] = name ?: @"";
    bundle[@"birthday"] = birthday ?: @"";
    bundle[@"location"] = location ?: @"";
    bundle[@"gender"] = gender ?: @"";

    if (portraitImage) {
        NSString *fileName = [NSString stringWithFormat:@"face_%@.jpg", [[NSUUID UUID] UUIDString]];
        NSString *old = bundle[@"portrait"];
        if ([old isKindOfClass:NSString.class] && old.length > 0) {
            NSString *oldPath = [[self yk_portraitDirectoryPath] stringByAppendingPathComponent:old];
            [[NSFileManager defaultManager] removeItemAtPath:oldPath error:nil];
        }
        NSData *data = UIImageJPEGRepresentation(portraitImage, 0.88);
        NSString *path = [[self yk_portraitDirectoryPath] stringByAppendingPathComponent:fileName];
        [data writeToFile:path atomically:YES];
        bundle[@"portrait"] = fileName;
    }

    dossiers[mailbox] = bundle;
    [self yk_persistDossierMap:dossiers];
    [self yk_markDossierReady:YES];
}

@end
