//
//  YKThreadViewController.m
//  Yoka
//

#import "YKThreadViewController.h"
#import "YKWhisperVault.h"
#import "YKShadeRoster.h"
#import "YKReportShadeSheet.h"
#import "YKReportViewController.h"
#import "YKInboxViewController.h"
#import "../FindClass/YKFindPersonaBoardViewController.h"
#import "../LoginandReClass/YKAccountVault.h"
#import "../LoginandReClass/YKBondLedger.h"
#import "../LoginandReClass/YKPersonaCatalog.h"
#import "../../BaseClass/YKCenterToast.h"
#import <AVFoundation/AVFoundation.h>
#import <objc/runtime.h>
#import "../../BaseClass/YKSigilForge.h"

static const void *kYKVoiceFileKey = &kYKVoiceFileKey;
static const void *kYKVoiceWaveKey = &kYKVoiceWaveKey;

#pragma mark - Wave bars

@interface YKVoiceWaveBarsView : UIView
@property (nonatomic, strong) NSArray<NSLayoutConstraint *> *yk_heightPins;
@property (nonatomic, assign, getter=yk_isWaving) BOOL yk_waving;
- (instancetype)initWithBarColor:(UIColor *)color;
- (void)yk_startWaving;
- (void)yk_stopWaving;
@end

@implementation YKVoiceWaveBarsView

- (instancetype)initWithBarColor:(UIColor *)color {
    self = [super initWithFrame:CGRectZero];
    if (self) {
        self.translatesAutoresizingMaskIntoConstraints = NO;
        NSMutableArray *pins = [NSMutableArray array];
        CGFloat bases[] = {10.0, 18.0, 14.0, 20.0};
        UIView *prev = nil;
        for (NSInteger i = 0; i < 4; i++) {
            UIView *bar = [[UIView alloc] init];
            bar.translatesAutoresizingMaskIntoConstraints = NO;
            bar.backgroundColor = color;
            bar.layer.cornerRadius = 1.5;
            [self addSubview:bar];
            NSLayoutConstraint *h = [bar.heightAnchor constraintEqualToConstant:bases[i]];
            [pins addObject:h];
            [NSLayoutConstraint activateConstraints:@[
                [bar.widthAnchor constraintEqualToConstant:3.0],
                [bar.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],
                h,
                prev ? [bar.leadingAnchor constraintEqualToAnchor:prev.trailingAnchor constant:3.0]
                     : [bar.leadingAnchor constraintEqualToAnchor:self.leadingAnchor]
            ]];
            prev = bar;
        }
        [prev.trailingAnchor constraintEqualToAnchor:self.trailingAnchor].active = YES;
        [self.heightAnchor constraintEqualToConstant:22.0].active = YES;
        self.yk_heightPins = pins;
    }
    return self;
}

- (void)yk_startWaving {
    if (self.yk_waving) {
        return;
    }
    self.yk_waving = YES;
    [self yk_pulseBarsFromIndex:0];
}

- (void)yk_stopWaving {
    self.yk_waving = NO;
    [self.layer removeAllAnimations];
    NSArray<NSNumber *> *bases = @[@10, @18, @14, @20];
    for (NSUInteger idx = 0; idx < self.yk_heightPins.count; idx++) {
        self.yk_heightPins[idx].constant = bases[idx % 4].doubleValue;
    }
    [self layoutIfNeeded];
}

- (void)yk_pulseBarsFromIndex:(NSInteger)start {
    if (!self.yk_waving) {
        return;
    }
    NSArray<NSNumber *> *lows = @[@8, @10, @9, @11];
    NSArray<NSNumber *> *highs = @[@16, @22, @18, @22];
    [UIView animateWithDuration:0.22
                          delay:0
                        options:UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
        for (NSUInteger idx = 0; idx < self.yk_heightPins.count; idx++) {
            BOOL up = ((start + (NSInteger)idx) % 2) == 0;
            self.yk_heightPins[idx].constant = (up ? highs : lows)[idx % 4].doubleValue;
        }
        [self layoutIfNeeded];
    } completion:^(BOOL finished) {
        if (!self.yk_waving) {
            return;
        }
        [self yk_pulseBarsFromIndex:start + 1];
    }];
}

@end

#pragma mark - Chat

@interface YKThreadViewController () <UITextFieldDelegate, AVAudioPlayerDelegate, AVAudioRecorderDelegate>

@property (nonatomic, copy) NSString *personaId;
@property (nonatomic, copy) NSString *displayAlias;
@property (nonatomic, strong) UIColor *tintColor;
@property (nonatomic, strong) UIView *inputContainerView;
@property (nonatomic, strong) UIView *inputFieldView;
@property (nonatomic, strong) UIView *voicePanelView;
@property (nonatomic, strong) UIButton *recordButton;
@property (nonatomic, strong) UIView *recordPulseView;
@property (nonatomic, strong) UITextField *composerTextField;
@property (nonatomic, strong) UIScrollView *threadScrollView;
@property (nonatomic, strong) UIView *messagesContentView;
@property (nonatomic, strong) UIView *yk_lastBubbleView;
@property (nonatomic, strong) NSLayoutConstraint *messagesBottomPinConstraint;
@property (nonatomic, strong) NSLayoutConstraint *inputContainerHeightConstraint;
@property (nonatomic, strong) NSLayoutConstraint *inputContainerBottomConstraint;
@property (nonatomic, assign) CGFloat yk_keyboardOverlap;

@property (nonatomic, strong) AVAudioRecorder *yk_recorder;
@property (nonatomic, copy) NSString *yk_recordTempPath;
@property (nonatomic, assign) NSTimeInterval yk_recordStartedAt;
@property (nonatomic, strong) AVAudioPlayer *yk_player;
@property (nonatomic, weak) YKVoiceWaveBarsView *yk_playingWave;

@end

@implementation YKThreadViewController

- (instancetype)initWithPersonaId:(NSString *)personaId {
    NSDictionary *persona = [YKPersonaCatalog yk_personaWithId:personaId];
    self = [self initWithDisplayAlias:persona[@"name"] ?: @"Yoka"
                        tintColor:[UIColor colorWithRed:0.56 green:0.33 blue:0.32 alpha:1.0]];
    if (self) {
        _personaId = [personaId copy] ?: @"";
    }
    return self;
}

- (instancetype)initWithDisplayAlias:(NSString *)userName tintColor:(UIColor *)tintColor {
    self = [super init];
    if (self) {
        _displayAlias = userName.length > 0 ? [userName copy] : @"Yoka";
        _tintColor = tintColor ?: [UIColor colorWithRed:0.56 green:0.33 blue:0.32 alpha:1.0];
        _personaId = @"";
    }
    return self;
}

- (NSString *)yk_ownerKey {
    YKAccountVault *vault = [YKAccountVault sharedVault];
    if ([YKAccountVault yk_isReviewMailbox:vault.yk_activeMailbox ?: @""]) {
        return [YKPersonaCatalog yk_reviewPersonaId];
    }
    return vault.yk_activeMailbox ?: @"guest";
}

- (NSArray<NSDictionary *> *)yk_threadLines {
    if (self.personaId.length == 0) {
        return @[];
    }
    return [[YKWhisperVault sharedVault] yk_linesForOwnerKey:[self yk_ownerKey] peerId:self.personaId];
}

- (UIImage *)yk_peerAvatar {
    UIImage *avatar = [YKPersonaCatalog yk_avatarImageForPersonaId:self.personaId];
    return avatar ?: [UIImage imageNamed:@"headplace"];
}

- (UIImage *)yk_selfAvatar {
    return [[YKAccountVault sharedVault] yk_portraitImageForActiveMailbox] ?: [UIImage imageNamed:@"headplace"];
}

- (void)yk_configurePage {
    [super yk_configurePage];
    [self yk_setupViews];
    [self yk_installKeyboardObservers];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self yk_stopPlayback];
    [self.yk_recorder stop];
}

- (void)yk_installKeyboardObservers {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(yk_keyboardWillChange:)
                                                 name:UIKeyboardWillChangeFrameNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(yk_keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
}

- (void)yk_setupViews {
    UIButton *backButton = [self yk_addBackButton];

    UIImageView *avatarImageView = [self yk_avatarImageViewWithSize:44.0 image:[self yk_peerAvatar]];
    avatarImageView.userInteractionEnabled = YES;
    [avatarImageView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(yk_peerAvatarTapped:)]];
    [self.view addSubview:avatarImageView];

    UILabel *nameLabel = [[UILabel alloc] init];
    nameLabel.translatesAutoresizingMaskIntoConstraints = NO;
    nameLabel.text = self.displayAlias;
    nameLabel.textColor = UIColor.whiteColor;
    nameLabel.font = [UIFont systemFontOfSize:20.0 weight:UIFontWeightBold];
    [self.view addSubview:nameLabel];

    UIButton *moreButton = [UIButton buttonWithType:UIButtonTypeCustom];
    moreButton.translatesAutoresizingMaskIntoConstraints = NO;
    [moreButton setImage:[[UIImage imageNamed:@"detail_more_button"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] forState:UIControlStateNormal];
    [moreButton addTarget:self action:@selector(yk_moreButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:moreButton];

    UIScrollView *threadScrollView = [[UIScrollView alloc] init];
    threadScrollView.translatesAutoresizingMaskIntoConstraints = NO;
    threadScrollView.showsVerticalScrollIndicator = NO;
    threadScrollView.alwaysBounceVertical = YES;
    threadScrollView.keyboardDismissMode = UIScrollViewKeyboardDismissModeInteractive;
    threadScrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    [self.view addSubview:threadScrollView];
    self.threadScrollView = threadScrollView;

    UIView *messagesContent = [[UIView alloc] init];
    messagesContent.translatesAutoresizingMaskIntoConstraints = NO;
    [threadScrollView addSubview:messagesContent];
    self.messagesContentView = messagesContent;

    UIView *inputContainer = [[UIView alloc] init];
    inputContainer.translatesAutoresizingMaskIntoConstraints = NO;
    inputContainer.backgroundColor = [UIColor colorWithRed:0.91 green:0.30 blue:0.94 alpha:0.92];
    inputContainer.layer.cornerRadius = 28.0;
    inputContainer.layer.maskedCorners = kCALayerMinXMinYCorner | kCALayerMaxXMinYCorner;
    inputContainer.layer.borderColor = UIColor.whiteColor.CGColor;
    inputContainer.layer.borderWidth = 1.5;
    inputContainer.clipsToBounds = YES;
    [self.view addSubview:inputContainer];
    self.inputContainerView = inputContainer;

    UIView *inputFieldView = [[UIView alloc] init];
    inputFieldView.translatesAutoresizingMaskIntoConstraints = NO;
    inputFieldView.backgroundColor = UIColor.whiteColor;
    inputFieldView.layer.cornerRadius = 23.0;
    [inputContainer addSubview:inputFieldView];
    self.inputFieldView = inputFieldView;

    UITextField *textField = [[UITextField alloc] init];
    textField.translatesAutoresizingMaskIntoConstraints = NO;
    textField.placeholder = @"Say something";
    textField.textColor = UIColor.blackColor;
    textField.tintColor = [UIColor colorWithRed:0.46 green:0.15 blue:0.90 alpha:1.0];
    textField.font = [UIFont systemFontOfSize:16.0];
    textField.returnKeyType = UIReturnKeySend;
    textField.delegate = self;
    textField.enablesReturnKeyAutomatically = YES;
    [inputFieldView addSubview:textField];
    self.composerTextField = textField;

    UIView *voiceHit = [self yk_composerActionButtonWithImageName:@"talkimage"
                                                           action:@selector(yk_voiceButtonTapped:)
                                                           target:self];
    [inputFieldView addSubview:voiceHit];

    UIView *sendHit = [self yk_composerActionButtonWithImageName:@"thread_dispatch"
                                                          action:@selector(yk_dispatchButtonTapped:)
                                                          target:self];
    [inputFieldView addSubview:sendHit];

    UIView *voicePanelView = [[UIView alloc] init];
    voicePanelView.translatesAutoresizingMaskIntoConstraints = NO;
    voicePanelView.hidden = YES;
    voicePanelView.clipsToBounds = NO;
    [inputContainer addSubview:voicePanelView];
    self.voicePanelView = voicePanelView;

    UIView *pulse = [[UIView alloc] init];
    pulse.translatesAutoresizingMaskIntoConstraints = NO;
    pulse.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.35];
    pulse.layer.cornerRadius = 38.0;
    pulse.hidden = YES;
    pulse.userInteractionEnabled = NO;
    [voicePanelView addSubview:pulse];
    self.recordPulseView = pulse;

    UIButton *recordButton = [self yk_composerActionButtonWithImageName:@"talkimage" action:nil target:nil];
    recordButton.translatesAutoresizingMaskIntoConstraints = NO;
    recordButton.layer.cornerRadius = 38.0;
    UIImage *recordIcon = [self yk_normalizedCircleIconNamed:@"talkimage" side:76.0];
    [recordButton setBackgroundImage:recordIcon forState:UIControlStateNormal];
    [recordButton setBackgroundImage:recordIcon forState:UIControlStateHighlighted];
    [recordButton addTarget:self action:@selector(yk_recordTouchDown:) forControlEvents:UIControlEventTouchDown];
    [recordButton addTarget:self action:@selector(yk_recordTouchUp:) forControlEvents:UIControlEventTouchUpInside];
    [recordButton addTarget:self action:@selector(yk_recordTouchUp:) forControlEvents:UIControlEventTouchUpOutside];
    [recordButton addTarget:self action:@selector(yk_recordTouchUp:) forControlEvents:UIControlEventTouchCancel];
    [voicePanelView addSubview:recordButton];
    self.recordButton = recordButton;
    [voicePanelView bringSubviewToFront:recordButton];

    UIButton *keyboardButton = [self yk_keyboardToggleButton];
    [voicePanelView addSubview:keyboardButton];

    UILayoutGuide *safeGuide = self.view.safeAreaLayoutGuide;
    self.inputContainerHeightConstraint = [inputContainer.heightAnchor constraintEqualToConstant:108.0];
    self.inputContainerBottomConstraint = [inputContainer.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor];

    [NSLayoutConstraint activateConstraints:@[
        [avatarImageView.centerYAnchor constraintEqualToAnchor:backButton.centerYAnchor],
        [avatarImageView.leadingAnchor constraintEqualToAnchor:backButton.trailingAnchor constant:16.0],
        [avatarImageView.widthAnchor constraintEqualToConstant:44.0],
        [avatarImageView.heightAnchor constraintEqualToConstant:44.0],

        [nameLabel.centerYAnchor constraintEqualToAnchor:avatarImageView.centerYAnchor],
        [nameLabel.leadingAnchor constraintEqualToAnchor:avatarImageView.trailingAnchor constant:10.0],

        [moreButton.centerYAnchor constraintEqualToAnchor:avatarImageView.centerYAnchor],
        [moreButton.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-24.0],
        [moreButton.widthAnchor constraintEqualToConstant:36.0],
        [moreButton.heightAnchor constraintEqualToConstant:36.0],

        [threadScrollView.topAnchor constraintEqualToAnchor:safeGuide.topAnchor constant:60.0],
        [threadScrollView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [threadScrollView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [threadScrollView.bottomAnchor constraintEqualToAnchor:inputContainer.topAnchor],

        [messagesContent.topAnchor constraintEqualToAnchor:threadScrollView.contentLayoutGuide.topAnchor],
        [messagesContent.leadingAnchor constraintEqualToAnchor:threadScrollView.contentLayoutGuide.leadingAnchor],
        [messagesContent.trailingAnchor constraintEqualToAnchor:threadScrollView.contentLayoutGuide.trailingAnchor],
        [messagesContent.bottomAnchor constraintEqualToAnchor:threadScrollView.contentLayoutGuide.bottomAnchor],
        [messagesContent.widthAnchor constraintEqualToAnchor:threadScrollView.frameLayoutGuide.widthAnchor],

        [inputContainer.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [inputContainer.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        self.inputContainerBottomConstraint,
        self.inputContainerHeightConstraint,

        [inputFieldView.leadingAnchor constraintEqualToAnchor:inputContainer.leadingAnchor constant:26.0],
        [inputFieldView.trailingAnchor constraintEqualToAnchor:inputContainer.trailingAnchor constant:-26.0],
        [inputFieldView.topAnchor constraintEqualToAnchor:inputContainer.topAnchor constant:18.0],
        [inputFieldView.heightAnchor constraintEqualToConstant:52.0],

        [textField.centerYAnchor constraintEqualToAnchor:inputFieldView.centerYAnchor],
        [textField.leadingAnchor constraintEqualToAnchor:inputFieldView.leadingAnchor constant:18.0],
        [textField.trailingAnchor constraintEqualToAnchor:voiceHit.leadingAnchor constant:-10.0],

        [sendHit.centerYAnchor constraintEqualToAnchor:inputFieldView.centerYAnchor],
        [sendHit.trailingAnchor constraintEqualToAnchor:inputFieldView.trailingAnchor constant:-8.0],
        [sendHit.widthAnchor constraintEqualToConstant:40.0],
        [sendHit.heightAnchor constraintEqualToConstant:40.0],

        [voiceHit.centerYAnchor constraintEqualToAnchor:inputFieldView.centerYAnchor],
        [voiceHit.trailingAnchor constraintEqualToAnchor:sendHit.leadingAnchor constant:-8.0],
        [voiceHit.widthAnchor constraintEqualToConstant:40.0],
        [voiceHit.heightAnchor constraintEqualToConstant:40.0],

        [voicePanelView.topAnchor constraintEqualToAnchor:inputContainer.topAnchor],
        [voicePanelView.leadingAnchor constraintEqualToAnchor:inputContainer.leadingAnchor],
        [voicePanelView.trailingAnchor constraintEqualToAnchor:inputContainer.trailingAnchor],
        [voicePanelView.bottomAnchor constraintEqualToAnchor:inputContainer.bottomAnchor],

        [recordButton.centerXAnchor constraintEqualToAnchor:voicePanelView.centerXAnchor],
        [recordButton.topAnchor constraintEqualToAnchor:voicePanelView.topAnchor constant:18.0],
        [recordButton.widthAnchor constraintEqualToConstant:76.0],
        [recordButton.heightAnchor constraintEqualToConstant:76.0],

        [pulse.centerXAnchor constraintEqualToAnchor:recordButton.centerXAnchor],
        [pulse.centerYAnchor constraintEqualToAnchor:recordButton.centerYAnchor],
        [pulse.widthAnchor constraintEqualToConstant:76.0],
        [pulse.heightAnchor constraintEqualToConstant:76.0],

        [keyboardButton.topAnchor constraintEqualToAnchor:voicePanelView.topAnchor constant:14.0],
        [keyboardButton.trailingAnchor constraintEqualToAnchor:voicePanelView.trailingAnchor constant:-18.0],
        [keyboardButton.widthAnchor constraintEqualToConstant:40.0],
        [keyboardButton.heightAnchor constraintEqualToConstant:40.0]
    ]];

    [self yk_reloadThreadUI];

    [self.view bringSubviewToFront:inputContainer];
    [self.view bringSubviewToFront:backButton];
    [self.view bringSubviewToFront:avatarImageView];
    [self.view bringSubviewToFront:nameLabel];
    [self.view bringSubviewToFront:moreButton];

    [self yk_updateInputContainerHeightForSafeArea];
    [self yk_updateInputChromeForKeyboard:NO];
}

#pragma mark - Report / Block

- (void)yk_peerAvatarTapped:(UITapGestureRecognizer *)gesture {
    [self yk_openPeerProfile];
}

- (void)yk_openPeerProfile {
    [self.view endEditing:YES];
    YKFindPersonaBoardViewController *profile = nil;
    if (self.personaId.length > 0) {
        profile = [[YKFindPersonaBoardViewController alloc] initWithPersonaId:self.personaId];
    } else {
        NSString *name = self.displayAlias.length > 0 ? self.displayAlias : @"Yoka";
        profile = [[YKFindPersonaBoardViewController alloc] initWithDisplayAlias:name];
    }
    [self.navigationController pushViewController:profile animated:YES];
}

- (void)yk_moreButtonTapped:(UIButton *)sender {
    [self.view endEditing:YES];
    __weak typeof(self) weakSelf = self;
    [YKReportShadeSheet yk_presentInView:self.view
                                  report:^{
        YKReportViewController *report = [[YKReportViewController alloc] initWithPersonaId:weakSelf.personaId];
        [weakSelf.navigationController pushViewController:report animated:YES];
    }
                                   block:^{
        [weakSelf yk_blockCurrentPeer];
    }];
}

- (void)yk_blockCurrentPeer {
    NSString *peerId = self.personaId;
    NSString *owner = [self yk_ownerKey];
    if (peerId.length == 0 || [peerId isEqualToString:owner]) {
        return;
    }
    [[YKShadeRoster sharedRoster] yk_ownerKey:owner shadeId:peerId];
    [[YKBondLedger sharedLedger] yk_ownerKey:owner setLink:peerId on:NO];
    [YKCenterToast yk_showNotice:[YKSigilForge yk_unveil:@"gXSk12fDfGwMlYIIaZYBKg=="] inView:self.view];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.55 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        UINavigationController *nav = self.navigationController;
        UIViewController *inbox = nil;
        for (UIViewController *vc in nav.viewControllers) {
            if ([vc isKindOfClass:YKInboxViewController.class]) {
                inbox = vc;
                break;
            }
        }
        if (inbox) {
            [nav popToViewController:inbox animated:YES];
        } else {
            [nav popViewControllerAnimated:YES];
        }
    });
}

#pragma mark - Thread UI

- (void)yk_reloadThreadUI {
    for (UIView *sub in [self.messagesContentView.subviews copy]) {
        [sub removeFromSuperview];
    }
    self.yk_lastBubbleView = nil;
    self.messagesBottomPinConstraint.active = NO;
    self.messagesBottomPinConstraint = nil;

    NSArray *lines = [self yk_threadLines];
    if (lines.count == 0) {
        [self yk_renderIdleThread];
    } else {
        for (NSDictionary *line in lines) {
            [self yk_appendLineView:line];
        }
    }
    [self.view layoutIfNeeded];
    [self yk_scrollThreadToBottomAnimated:NO];
}

- (void)yk_renderIdleThread {
    // Empty thread visual (matches design when no persisted lines yet).
    NSArray *placeholders = @[
        @{@"heading": @"inbound", @"kind": @"text", @"body": @"Hey! Thanks for connecting."},
        @{@"heading": @"outbound", @"kind": @"text", @"body": @"How's your day going?"},
        @{@"heading": @"inbound", @"kind": @"voice", @"dur": @21, @"file": @""},
        @{@"heading": @"outbound", @"kind": @"voice", @"dur": @21, @"file": @""}
    ];
    for (NSDictionary *line in placeholders) {
        [self yk_appendLineView:line];
    }
}

- (void)yk_appendLineView:(NSDictionary *)line {
    UIView *content = self.messagesContentView;
    if (!content || ![line isKindOfClass:NSDictionary.class]) {
        return;
    }

    BOOL incoming = [line[@"heading"] isEqualToString:@"inbound"];
    NSString *kind = line[@"kind"] ?: @"text";
    UIView *anchor = self.yk_lastBubbleView;
    CGFloat topGap = anchor ? 30.0 : 16.0;

    UIImage *avatarImage = incoming ? [self yk_peerAvatar] : [self yk_selfAvatar];
    UIImageView *avatar = [self yk_avatarImageViewWithSize:40.0 image:avatarImage];
    if (incoming) {
        avatar.userInteractionEnabled = YES;
        [avatar addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(yk_peerAvatarTapped:)]];
    }
    [content addSubview:avatar];

    UIView *bubble = nil;
    if ([kind isEqualToString:@"voice"]) {
        CGFloat dur = [line[@"dur"] doubleValue];
        if (dur < 1.0) {
            dur = 1.0;
        }
        NSString *file = [line[@"file"] isKindOfClass:NSString.class] ? line[@"file"] : @"";
        bubble = [self yk_voiceBubbleIncoming:incoming duration:dur fileName:file];
    } else {
        NSString *body = [line[@"body"] isKindOfClass:NSString.class] ? line[@"body"] : @"";
        bubble = [self yk_textBubbleWithText:body incoming:incoming];
    }
    [content addSubview:bubble];

    if (self.messagesBottomPinConstraint) {
        self.messagesBottomPinConstraint.active = NO;
    }

    NSMutableArray *constraints = [NSMutableArray array];
    if (incoming) {
        [constraints addObjectsFromArray:@[
            anchor ? [avatar.topAnchor constraintEqualToAnchor:anchor.bottomAnchor constant:topGap + 2.0]
                   : [avatar.topAnchor constraintEqualToAnchor:content.topAnchor constant:topGap],
            [avatar.leadingAnchor constraintEqualToAnchor:content.leadingAnchor constant:28.0],
            [avatar.widthAnchor constraintEqualToConstant:40.0],
            [avatar.heightAnchor constraintEqualToConstant:40.0],
            [bubble.topAnchor constraintEqualToAnchor:avatar.topAnchor],
            [bubble.leadingAnchor constraintEqualToAnchor:avatar.trailingAnchor constant:12.0]
        ]];
    } else {
        [constraints addObjectsFromArray:@[
            anchor ? [avatar.topAnchor constraintEqualToAnchor:anchor.bottomAnchor constant:topGap + 2.0]
                   : [avatar.topAnchor constraintEqualToAnchor:content.topAnchor constant:topGap],
            [avatar.trailingAnchor constraintEqualToAnchor:content.trailingAnchor constant:-24.0],
            [avatar.widthAnchor constraintEqualToConstant:40.0],
            [avatar.heightAnchor constraintEqualToConstant:40.0],
            [bubble.topAnchor constraintEqualToAnchor:avatar.topAnchor],
            [bubble.trailingAnchor constraintEqualToAnchor:avatar.leadingAnchor constant:-12.0]
        ]];
    }

    if ([kind isEqualToString:@"voice"]) {
        [constraints addObject:[bubble.widthAnchor constraintEqualToConstant:100.0]];
        [constraints addObject:[bubble.heightAnchor constraintEqualToConstant:42.0]];
    } else {
        [constraints addObject:[bubble.widthAnchor constraintEqualToConstant:248.0]];
        [constraints addObject:[bubble.heightAnchor constraintGreaterThanOrEqualToConstant:58.0]];
    }

    [NSLayoutConstraint activateConstraints:constraints];

    self.yk_lastBubbleView = bubble;
    self.messagesBottomPinConstraint = [bubble.bottomAnchor constraintEqualToAnchor:content.bottomAnchor constant:-24.0];
    self.messagesBottomPinConstraint.active = YES;
}

#pragma mark - Keyboard

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    [self yk_updateInputContainerHeightForSafeArea];
}

- (void)yk_updateInputContainerHeightForSafeArea {
    CGFloat target;
    if (self.yk_keyboardOverlap > 0.5) {
        target = 86.0 + self.yk_keyboardOverlap;
    } else {
        CGFloat bottomInset = self.view.safeAreaInsets.bottom;
        target = 96.0 + MAX(bottomInset, 8.0);
    }
    if (fabs(self.inputContainerHeightConstraint.constant - target) > 0.5) {
        self.inputContainerHeightConstraint.constant = target;
    }
}

- (void)yk_updateInputChromeForKeyboard:(BOOL)keyboardUp {
    if (keyboardUp) {
        self.inputContainerView.layer.cornerRadius = 0.0;
        self.inputContainerView.layer.borderWidth = 0.0;
    } else {
        self.inputContainerView.layer.cornerRadius = 28.0;
        self.inputContainerView.layer.maskedCorners = kCALayerMinXMinYCorner | kCALayerMaxXMinYCorner;
        self.inputContainerView.layer.borderWidth = 1.5;
    }
}

- (void)yk_keyboardWillChange:(NSNotification *)note {
    NSDictionary *info = note.userInfo;
    CGRect endFrame = [info[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGRect endInView = [self.view convertRect:endFrame fromView:nil];
    CGFloat overlap = MAX(0.0, CGRectGetMaxY(self.view.bounds) - CGRectGetMinY(endInView));
    if (overlap < 1.0) {
        overlap = 0.0;
    }
    [self yk_applyKeyboardOverlap:overlap userInfo:info];
}

- (void)yk_keyboardWillHide:(NSNotification *)note {
    [self yk_applyKeyboardOverlap:0.0 userInfo:note.userInfo];
}

- (void)yk_applyKeyboardOverlap:(CGFloat)overlap userInfo:(NSDictionary *)info {
    self.yk_keyboardOverlap = overlap;
    self.inputContainerBottomConstraint.constant = 0.0;
    [self yk_updateInputContainerHeightForSafeArea];
    [self yk_updateInputChromeForKeyboard:overlap > 0.5];

    NSTimeInterval duration = [info[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    UIViewAnimationOptions curve = ([info[UIKeyboardAnimationCurveUserInfoKey] integerValue] << 16);
    if (duration <= 0) {
        duration = 0.25;
    }

    [UIView animateWithDuration:duration
                          delay:0
                        options:curve | UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
        [self.view layoutIfNeeded];
    } completion:^(BOOL finished) {
        [self yk_scrollThreadToBottomAnimated:YES];
    }];
}

- (void)yk_scrollThreadToBottomAnimated:(BOOL)animated {
    UIScrollView *scroll = self.threadScrollView;
    if (!scroll) {
        return;
    }
    [scroll layoutIfNeeded];
    CGFloat contentH = scroll.contentSize.height;
    CGFloat boundsH = CGRectGetHeight(scroll.bounds);
    CGFloat insetBottom = scroll.adjustedContentInset.bottom;
    CGFloat insetTop = scroll.adjustedContentInset.top;
    CGFloat maxOffset = MAX(-insetTop, contentH - boundsH + insetBottom);
    CGPoint target = CGPointMake(0.0, maxOffset);
    if (fabs(scroll.contentOffset.y - target.y) < 0.5) {
        return;
    }
    [scroll setContentOffset:target animated:animated];
}

#pragma mark - Composer chrome

- (UIButton *)yk_keyboardToggleButton {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.translatesAutoresizingMaskIntoConstraints = NO;
    button.adjustsImageWhenHighlighted = NO;
    button.clipsToBounds = YES;
    button.layer.cornerRadius = 20.0;
    [button setBackgroundImage:[self yk_keyboardCircleIconSide:40.0] forState:UIControlStateNormal];
    [button addTarget:self action:@selector(yk_keyboardButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    return button;
}

- (UIImage *)yk_keyboardCircleIconSide:(CGFloat)side {
    CGFloat scale = UIScreen.mainScreen.scale;
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(side, side), NO, scale);
    CGContextRef ctx = UIGraphicsGetCurrentContext();

    UIBezierPath *circle = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(0.0, 0.0, side, side)];
    [circle addClip];

    CGColorSpaceRef space = CGColorSpaceCreateDeviceRGB();
    CGFloat locations[] = {0.0, 1.0};
    NSArray *colors = @[
        (__bridge id)[UIColor colorWithRed:0.55 green:0.20 blue:0.95 alpha:1.0].CGColor,
        (__bridge id)[UIColor colorWithRed:0.95 green:0.20 blue:0.78 alpha:1.0].CGColor
    ];
    CGGradientRef gradient = CGGradientCreateWithColors(space, (__bridge CFArrayRef)colors, locations);
    CGContextDrawLinearGradient(ctx, gradient, CGPointMake(side * 0.5, 0.0), CGPointMake(side * 0.5, side), 0);
    CGGradientRelease(gradient);
    CGColorSpaceRelease(space);

    [[UIColor whiteColor] setFill];
    CGFloat kx = side * 0.22;
    CGFloat ky = side * 0.30;
    CGFloat kw = side * 0.56;
    CGFloat kh = side * 0.40;
    UIBezierPath *board = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(kx, ky, kw, kh) cornerRadius:2.0];
    [board fill];

    [[UIColor colorWithRed:0.70 green:0.18 blue:0.88 alpha:1.0] setFill];
    CGFloat key = side * 0.08;
    CGFloat gap = side * 0.035;
    CGFloat startY = ky + gap + 1.0;
    for (NSInteger row = 0; row < 3; row++) {
        NSInteger cols = (row == 2) ? 3 : 4;
        CGFloat rowWidth = cols * key + (cols - 1) * gap;
        CGFloat rowStart = kx + (kw - rowWidth) * 0.5;
        for (NSInteger col = 0; col < cols; col++) {
            CGRect keyRect = CGRectMake(rowStart + col * (key + gap), startY + row * (key + gap), key, key);
            [[UIBezierPath bezierPathWithRect:keyRect] fill];
        }
    }

    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return [image imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
}

- (UIButton *)yk_composerActionButtonWithImageName:(NSString *)imageName action:(SEL)action target:(id)target {
    const CGFloat side = 40.0;
    UIImage *icon = [self yk_normalizedCircleIconNamed:imageName side:side];

    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.translatesAutoresizingMaskIntoConstraints = NO;
    button.adjustsImageWhenHighlighted = NO;
    button.clipsToBounds = YES;
    button.layer.cornerRadius = side * 0.5;
    [button setBackgroundImage:icon forState:UIControlStateNormal];
    [button setBackgroundImage:icon forState:UIControlStateHighlighted];
    if (action && target) {
        [button addTarget:target action:action forControlEvents:UIControlEventTouchUpInside];
    }
    return button;
}

- (UIImage *)yk_normalizedCircleIconNamed:(NSString *)imageName side:(CGFloat)side {
    UIImage *source = [UIImage imageNamed:imageName];
    if (!source) {
        return nil;
    }

    CGFloat scale = UIScreen.mainScreen.scale;
    CGSize size = CGSizeMake(side, side);
    UIGraphicsBeginImageContextWithOptions(size, NO, scale);
    CGContextRef ctx = UIGraphicsGetCurrentContext();

    UIBezierPath *circle = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(0.0, 0.0, side, side)];
    [circle addClip];

    CGFloat bleed = [imageName isEqualToString:@"talkimage"] ? (side * 0.18) : 0.0;
    CGRect drawRect = CGRectMake(-bleed, -bleed, side + bleed * 2.0, side + bleed * 2.0);
    [source drawInRect:drawRect];

    CGContextSetBlendMode(ctx, kCGBlendModeDestinationIn);
    [[UIColor blackColor] setFill];
    [circle fill];

    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return [image imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
}

#pragma mark - Text send

- (void)yk_voiceButtonTapped:(UIButton *)sender {
    [self.view endEditing:YES];
    self.inputFieldView.hidden = YES;
    self.voicePanelView.hidden = NO;
}

- (void)yk_dispatchButtonTapped:(UIButton *)sender {
    [self yk_dispatchComposerText];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self yk_dispatchComposerText];
    return NO;
}

- (void)yk_dispatchComposerText {
    NSString *raw = self.composerTextField.text ?: @"";
    NSString *text = [raw stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    if (text.length == 0) {
        return;
    }

    NSDictionary *line = @{
        @"heading": @"outbound",
        @"kind": @"text",
        @"stamp": @([[NSDate date] timeIntervalSince1970]),
        @"body": text
    };
    if (self.personaId.length > 0) {
        // Drop placeholders once real persistence starts.
        if ([self yk_threadLines].count == 0) {
            [self yk_clearIdleRows];
        }
        [[YKWhisperVault sharedVault] yk_ownerKey:[self yk_ownerKey]
                                           peerId:self.personaId
                                       appendLine:line];
    } else {
        [self yk_clearIdleRows];
    }

    [self yk_appendLineView:line];
    self.composerTextField.text = @"";
    [self.view layoutIfNeeded];
    [self yk_scrollThreadToBottomAnimated:YES];
}

- (void)yk_clearIdleRows {
    // If current last bubbles are placeholders (no vault yet), wipe before first real send.
    if ([self yk_threadLines].count > 0) {
        return;
    }
    for (UIView *sub in [self.messagesContentView.subviews copy]) {
        [sub removeFromSuperview];
    }
    self.yk_lastBubbleView = nil;
    self.messagesBottomPinConstraint.active = NO;
    self.messagesBottomPinConstraint = nil;
}

- (void)yk_keyboardButtonTapped:(UIButton *)sender {
    [self yk_stopRecordingDiscard:YES];
    self.voicePanelView.hidden = YES;
    self.inputFieldView.hidden = NO;
    [self.composerTextField becomeFirstResponder];
}

#pragma mark - Voice record

- (void)yk_recordTouchDown:(UIButton *)sender {
    [self yk_beginRecording];
}

- (void)yk_recordTouchUp:(UIButton *)sender {
    [self yk_finishRecordingAndSend];
}

- (void)yk_prepareAudioSessionForRecord:(BOOL)record {
    AVAudioSession *session = AVAudioSession.sharedInstance;
    NSError *error = nil;
    AVAudioSessionCategory category = record ? AVAudioSessionCategoryPlayAndRecord : AVAudioSessionCategoryPlayback;
    [session setCategory:category
             withOptions:AVAudioSessionCategoryOptionDefaultToSpeaker | AVAudioSessionCategoryOptionAllowBluetooth
                   error:&error];
    [session setActive:YES error:&error];
}

- (void)yk_beginRecording {
    if (self.yk_recorder.isRecording) {
        return;
    }
    [self yk_stopPlayback];

    AVAudioSession *session = AVAudioSession.sharedInstance;
    switch (session.recordPermission) {
        case AVAudioSessionRecordPermissionDenied:
            return;
        case AVAudioSessionRecordPermissionUndetermined: {
            [session requestRecordPermission:^(BOOL granted) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (granted) {
                        [self yk_beginRecording];
                    }
                });
            }];
            return;
        }
        case AVAudioSessionRecordPermissionGranted:
            break;
    }

    [self yk_prepareAudioSessionForRecord:YES];

    NSString *temp = [NSTemporaryDirectory() stringByAppendingPathComponent:
                      [NSString stringWithFormat:@"yoka_rec_%.0f.m4a", [[NSDate date] timeIntervalSince1970] * 1000.0]];
    self.yk_recordTempPath = temp;
    NSURL *url = [NSURL fileURLWithPath:temp];
    NSDictionary *settings = @{
        AVFormatIDKey: @(kAudioFormatMPEG4AAC),
        AVSampleRateKey: @44100,
        AVNumberOfChannelsKey: @1,
        AVEncoderAudioQualityKey: @(AVAudioQualityMedium)
    };
    NSError *error = nil;
    AVAudioRecorder *recorder = [[AVAudioRecorder alloc] initWithURL:url settings:settings error:&error];
    if (!recorder || error) {
        return;
    }
    recorder.delegate = self;
    recorder.meteringEnabled = YES;
    [recorder prepareToRecord];
    if (![recorder record]) {
        return;
    }
    self.yk_recorder = recorder;
    self.yk_recordStartedAt = [[NSDate date] timeIntervalSince1970];
    [self yk_startRecordPulse];
}

- (void)yk_finishRecordingAndSend {
    if (!self.yk_recorder.isRecording) {
        [self yk_stopRecordPulse];
        return;
    }
    NSTimeInterval dur = MAX(0.0, [[NSDate date] timeIntervalSince1970] - self.yk_recordStartedAt);
    [self.yk_recorder stop];
    self.yk_recorder = nil;
    [self yk_stopRecordPulse];

    NSString *temp = self.yk_recordTempPath;
    self.yk_recordTempPath = nil;
    if (dur < 0.4 || temp.length == 0) {
        [[NSFileManager defaultManager] removeItemAtPath:temp error:nil];
        return;
    }

    NSString *relative = [[YKWhisperVault sharedVault] yk_storeVoiceFileFromPath:temp];
    [[NSFileManager defaultManager] removeItemAtPath:temp error:nil];
    if (relative.length == 0) {
        return;
    }

    NSDictionary *line = @{
        @"heading": @"outbound",
        @"kind": @"voice",
        @"stamp": @([[NSDate date] timeIntervalSince1970]),
        @"file": relative,
        @"dur": @(round(dur))
    };

    if (self.personaId.length > 0) {
        if ([self yk_threadLines].count == 0) {
            [self yk_clearIdleRows];
        }
        [[YKWhisperVault sharedVault] yk_ownerKey:[self yk_ownerKey]
                                           peerId:self.personaId
                                       appendLine:line];
    } else {
        [self yk_clearIdleRows];
    }

    [self yk_appendLineView:line];
    [self.view layoutIfNeeded];
    [self yk_scrollThreadToBottomAnimated:YES];
}

- (void)yk_stopRecordingDiscard:(BOOL)discard {
    if (self.yk_recorder.isRecording) {
        [self.yk_recorder stop];
    }
    self.yk_recorder = nil;
    [self yk_stopRecordPulse];
    if (discard && self.yk_recordTempPath.length > 0) {
        [[NSFileManager defaultManager] removeItemAtPath:self.yk_recordTempPath error:nil];
    }
    self.yk_recordTempPath = nil;
}

- (void)yk_startRecordPulse {
    // Keep pulse inside the composer so clipsToBounds doesn't kill the collecting cue.
    UIView *pulse = self.recordPulseView;
    pulse.hidden = NO;
    pulse.alpha = 0.5;
    pulse.transform = CGAffineTransformIdentity;
    [pulse.layer removeAllAnimations];
    [self.recordButton.layer removeAllAnimations];

    CABasicAnimation *scale = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
    scale.fromValue = @1.0;
    scale.toValue = @1.18;
    scale.duration = 0.55;
    scale.autoreverses = YES;
    scale.repeatCount = HUGE_VALF;
    [pulse.layer addAnimation:scale forKey:@"yk_pulse_scale"];

    CABasicAnimation *fade = [CABasicAnimation animationWithKeyPath:@"opacity"];
    fade.fromValue = @0.5;
    fade.toValue = @0.12;
    fade.duration = 0.55;
    fade.autoreverses = YES;
    fade.repeatCount = HUGE_VALF;
    [pulse.layer addAnimation:fade forKey:@"yk_pulse_fade"];

    CABasicAnimation *btn = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
    btn.fromValue = @1.0;
    btn.toValue = @1.06;
    btn.duration = 0.4;
    btn.autoreverses = YES;
    btn.repeatCount = HUGE_VALF;
    [self.recordButton.layer addAnimation:btn forKey:@"yk_rec_scale"];
}

- (void)yk_stopRecordPulse {
    [self.recordPulseView.layer removeAllAnimations];
    self.recordPulseView.hidden = YES;
    self.recordPulseView.transform = CGAffineTransformIdentity;
    [self.recordButton.layer removeAllAnimations];
    self.recordButton.transform = CGAffineTransformIdentity;
}

#pragma mark - Voice playback

- (void)yk_voiceBubbleTapped:(UITapGestureRecognizer *)gesture {
    UIView *bubble = gesture.view;
    NSString *file = objc_getAssociatedObject(bubble, kYKVoiceFileKey);
    if (![file isKindOfClass:NSString.class] || file.length == 0) {
        return;
    }
    YKVoiceWaveBarsView *wave = objc_getAssociatedObject(bubble, kYKVoiceWaveKey);

    if (self.yk_player.isPlaying && self.yk_playingWave == wave) {
        [self yk_stopPlayback];
        return;
    }

    NSString *path = [[YKWhisperVault sharedVault] yk_absolutePathForVoiceFile:file];
    if (path.length == 0 || ![NSFileManager.defaultManager fileExistsAtPath:path]) {
        return;
    }

    [self yk_stopPlayback];
    [self yk_prepareAudioSessionForRecord:NO];

    NSError *error = nil;
    AVAudioPlayer *player = [[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL fileURLWithPath:path] error:&error];
    if (!player || error) {
        return;
    }
    player.delegate = self;
    [player prepareToPlay];
    if (![player play]) {
        return;
    }
    self.yk_player = player;
    self.yk_playingWave = wave;
    [wave yk_startWaving];
}

- (void)yk_stopPlayback {
    if (self.yk_player.isPlaying) {
        [self.yk_player stop];
    }
    self.yk_player = nil;
    [self.yk_playingWave yk_stopWaving];
    self.yk_playingWave = nil;
}

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag {
    [self yk_stopPlayback];
}

#pragma mark - Bubbles

- (UIImageView *)yk_avatarImageViewWithSize:(CGFloat)size {
    return [self yk_avatarImageViewWithSize:size image:nil];
}

- (UIImageView *)yk_avatarImageViewWithSize:(CGFloat)size image:(UIImage *)image {
    UIImage *resolved = image ?: [UIImage imageNamed:@"headplace"];
    UIImageView *imageView = [[UIImageView alloc] initWithImage:[resolved imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]];
    imageView.translatesAutoresizingMaskIntoConstraints = NO;
    imageView.backgroundColor = self.tintColor;
    imageView.contentMode = UIViewContentModeScaleAspectFill;
    imageView.layer.cornerRadius = size * 0.5;
    imageView.layer.masksToBounds = YES;
    return imageView;
}

- (UIView *)yk_textBubbleWithText:(NSString *)text incoming:(BOOL)incoming {
    UILabel *label = [[UILabel alloc] init];
    label.translatesAutoresizingMaskIntoConstraints = NO;
    label.numberOfLines = 0;
    label.text = text;
    label.font = [UIFont systemFontOfSize:15.0];
    label.textColor = incoming ? UIColor.blackColor : UIColor.whiteColor;

    UIView *bubbleView = [[UIView alloc] init];
    bubbleView.translatesAutoresizingMaskIntoConstraints = NO;
    bubbleView.backgroundColor = incoming ? UIColor.whiteColor : [UIColor colorWithWhite:1.0 alpha:0.12];
    bubbleView.layer.borderColor = (incoming ? UIColor.blackColor : UIColor.whiteColor).CGColor;
    bubbleView.layer.borderWidth = 2.0;
    [bubbleView addSubview:label];

    [NSLayoutConstraint activateConstraints:@[
        [label.topAnchor constraintEqualToAnchor:bubbleView.topAnchor constant:8.0],
        [label.leadingAnchor constraintEqualToAnchor:bubbleView.leadingAnchor constant:12.0],
        [label.trailingAnchor constraintEqualToAnchor:bubbleView.trailingAnchor constant:-12.0],
        [label.bottomAnchor constraintEqualToAnchor:bubbleView.bottomAnchor constant:-8.0]
    ]];

    return bubbleView;
}

- (UIView *)yk_voiceBubbleIncoming:(BOOL)incoming duration:(CGFloat)duration fileName:(NSString *)fileName {
    UIView *bubbleView = [[UIView alloc] init];
    bubbleView.translatesAutoresizingMaskIntoConstraints = NO;
    bubbleView.backgroundColor = incoming ? UIColor.whiteColor : [UIColor colorWithWhite:1.0 alpha:0.12];
    bubbleView.layer.borderColor = (incoming ? UIColor.blackColor : UIColor.whiteColor).CGColor;
    bubbleView.layer.borderWidth = 2.0;
    bubbleView.userInteractionEnabled = YES;

    UIColor *barColor = incoming ? UIColor.blackColor : UIColor.whiteColor;
    YKVoiceWaveBarsView *wave = [[YKVoiceWaveBarsView alloc] initWithBarColor:barColor];
    [bubbleView addSubview:wave];

    UILabel *durationLabel = [[UILabel alloc] init];
    durationLabel.translatesAutoresizingMaskIntoConstraints = NO;
    NSInteger secs = (NSInteger)MAX(1.0, round(duration));
    durationLabel.text = [NSString stringWithFormat:@"%ld'", (long)secs];
    durationLabel.textColor = barColor;
    durationLabel.font = [UIFont systemFontOfSize:15.0 weight:UIFontWeightMedium];
    [bubbleView addSubview:durationLabel];

    [NSLayoutConstraint activateConstraints:@[
        [wave.leadingAnchor constraintEqualToAnchor:bubbleView.leadingAnchor constant:14.0],
        [wave.centerYAnchor constraintEqualToAnchor:bubbleView.centerYAnchor],

        [durationLabel.centerYAnchor constraintEqualToAnchor:bubbleView.centerYAnchor],
        [durationLabel.leadingAnchor constraintEqualToAnchor:wave.trailingAnchor constant:10.0],
        [durationLabel.trailingAnchor constraintLessThanOrEqualToAnchor:bubbleView.trailingAnchor constant:-10.0]
    ]];

    objc_setAssociatedObject(bubbleView, kYKVoiceFileKey, fileName ?: @"", OBJC_ASSOCIATION_COPY_NONATOMIC);
    objc_setAssociatedObject(bubbleView, kYKVoiceWaveKey, wave, OBJC_ASSOCIATION_RETAIN_NONATOMIC);

    if (fileName.length > 0) {
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(yk_voiceBubbleTapped:)];
        [bubbleView addGestureRecognizer:tap];
    }

    return bubbleView;
}

@end
