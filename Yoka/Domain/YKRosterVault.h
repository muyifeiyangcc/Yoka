//
//  YKRosterVault.h
//  Yoka
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSNotificationName const YokaRosterPresenceDidShiftNotification;

@interface YKRosterVault : NSObject

+ (instancetype)sharedRoster;

#pragma mark - Review mailbox

+ (NSString *)yk_reviewMailbox;
+ (NSString *)yk_reviewSecret;
+ (BOOL)yk_isReviewMailbox:(NSString *)email;

#pragma mark - Presence

- (BOOL)yk_isPresenceActive;
- (BOOL)yk_isDossierReady;
- (nullable NSString *)yk_activeMailbox;
- (void)yk_markDossierReady:(BOOL)ready;

#pragma mark - Mailbox auth

- (BOOL)yk_isMailboxTombstoned:(NSString *)email;
- (BOOL)yk_mailboxExists:(NSString *)email;
- (nullable NSString *)yk_secretForMailbox:(NSString *)email;
- (BOOL)yk_admitMailboxWithEmail:(NSString *)email secret:(NSString *)secret errorMessage:(NSString * _Nullable * _Nullable)errorMessage;
- (BOOL)yk_registerMailboxWithEmail:(NSString *)email secret:(NSString *)secret errorMessage:(NSString * _Nullable * _Nullable)errorMessage;
- (BOOL)yk_replaceSecretForMailbox:(NSString *)email secret:(NSString *)secret errorMessage:(NSString * _Nullable * _Nullable)errorMessage;
- (void)yk_clearPresence;
- (void)yk_eraseActiveAccount;

#pragma mark - Apple

- (BOOL)yk_isAppleTombstoned:(NSString *)appleUserId;
- (BOOL)yk_admitAppleWithUserId:(NSString *)appleUserId
                                email:(nullable NSString *)email
                             fullName:(nullable NSString *)fullName
                         errorMessage:(NSString * _Nullable * _Nullable)errorMessage;
- (nullable NSString *)yk_activeAppleUserId;

#pragma mark - Dossier

- (nullable NSDictionary *)yk_dossierForActiveMailbox;
- (void)yk_saveDossierName:(NSString *)name
                  birthday:(NSString *)birthday
                  location:(NSString *)location
                    gender:(NSString *)gender
             portraitImage:(nullable UIImage *)portraitImage;
- (nullable UIImage *)yk_portraitImageForActiveMailbox;
- (nullable NSString *)yk_displayNameForActiveMailbox;

@end

NS_ASSUME_NONNULL_END
