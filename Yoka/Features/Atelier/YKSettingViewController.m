//
//  YKSettingViewController.m
//  Yoka
//

#import "YKSettingViewController.h"
#import "YKShadeListViewController.h"
#import "YKRosterVault.h"
#import "YKLaunchSteward.h"
#import "YKLegalDocViewController.h"
#import "YKCenterToast.h"
#import "YKCipherLoom.h"

typedef NS_ENUM(NSInteger, YKSettingConfirmKind) {
    YKSettingConfirmKindDelete = 0,
    YKSettingConfirmKindLogout
};

@interface YKSettingViewController ()
@property (nonatomic, strong) UIView *yk_confirmOverlay;
@property (nonatomic, strong) UIImageView *yk_confirmDialogView;
@property (nonatomic, strong) UIButton *yk_confirmCancelHit;
@property (nonatomic, strong) UIButton *yk_confirmSureHit;
@property (nonatomic, strong) NSLayoutConstraint *yk_confirmDialogWidth;
@property (nonatomic, strong) NSLayoutConstraint *yk_confirmDialogHeight;
@property (nonatomic, strong) NSLayoutConstraint *yk_cancelLeading;
@property (nonatomic, strong) NSLayoutConstraint *yk_cancelBottom;
@property (nonatomic, strong) NSLayoutConstraint *yk_cancelWidth;
@property (nonatomic, strong) NSLayoutConstraint *yk_cancelHeight;
@property (nonatomic, strong) NSLayoutConstraint *yk_sureTrailing;
@property (nonatomic, strong) NSLayoutConstraint *yk_sureBottom;
@property (nonatomic, strong) NSLayoutConstraint *yk_sureWidth;
@property (nonatomic, strong) NSLayoutConstraint *yk_sureHeight;
@property (nonatomic, assign) YKSettingConfirmKind yk_confirmKind;
@end

@implementation YKSettingViewController

- (void)yk_configurePage {
    [super yk_configurePage];
    [self yk_setupViews];
    [self yk_setupConfirmOverlay];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    [self yk_updateConfirmHitRectsForCurrentBounds];
}

- (void)yk_setupViews {
    UIButton *backButton = [self yk_addBackButton];

    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    titleLabel.text = @"Setting";
    titleLabel.textColor = UIColor.whiteColor;
    titleLabel.font = [UIFont fontWithName:@"Limelight" size:22.0] ?: [UIFont systemFontOfSize:22.0 weight:UIFontWeightBold];
    [self.view addSubview:titleLabel];

    UIButton *blacklistButton = [self yk_rowButtonWithTitle:[YKCipherLoom yk_unfurl:@"97VL1hDna+zNOfXwJ4sORw=="] action:@selector(yk_shadeListTapped:)];
    UIButton *agreementButton = [self yk_rowButtonWithTitle:@"User Agreement" action:@selector(yk_agreementTapped:)];
    UIButton *privacyButton = [self yk_rowButtonWithTitle:@"Privacy Agreement" action:@selector(yk_privacyTapped:)];
    [self.view addSubview:blacklistButton];
    [self.view addSubview:agreementButton];
    [self.view addSubview:privacyButton];

    UIButton *deleteButton = [self yk_assetButtonNamed:@"delete_account_button" action:@selector(yk_deleteTapped:)];
    UIButton *logoutButton = [self yk_assetButtonNamed:@"logout_button" action:@selector(yk_logoutTapped:)];
    [self.view addSubview:deleteButton];
    [self.view addSubview:logoutButton];

    const CGFloat rowH = 48.0;
    const CGFloat btnW = 215.0;
    const CGFloat btnH = 49.0;

    [NSLayoutConstraint activateConstraints:@[
        [titleLabel.centerYAnchor constraintEqualToAnchor:backButton.centerYAnchor],
        [titleLabel.leadingAnchor constraintEqualToAnchor:backButton.trailingAnchor constant:2.0],

        [blacklistButton.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:72.0],
        [blacklistButton.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:24.0],
        [blacklistButton.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-24.0],
        [blacklistButton.heightAnchor constraintEqualToConstant:rowH],

        [agreementButton.topAnchor constraintEqualToAnchor:blacklistButton.bottomAnchor constant:14.0],
        [agreementButton.leadingAnchor constraintEqualToAnchor:blacklistButton.leadingAnchor],
        [agreementButton.trailingAnchor constraintEqualToAnchor:blacklistButton.trailingAnchor],
        [agreementButton.heightAnchor constraintEqualToConstant:rowH],

        [privacyButton.topAnchor constraintEqualToAnchor:agreementButton.bottomAnchor constant:14.0],
        [privacyButton.leadingAnchor constraintEqualToAnchor:blacklistButton.leadingAnchor],
        [privacyButton.trailingAnchor constraintEqualToAnchor:blacklistButton.trailingAnchor],
        [privacyButton.heightAnchor constraintEqualToConstant:rowH],

        [logoutButton.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [logoutButton.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor constant:-24.0],
        [logoutButton.widthAnchor constraintEqualToConstant:btnW],
        [logoutButton.heightAnchor constraintEqualToConstant:btnH],

        [deleteButton.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [deleteButton.bottomAnchor constraintEqualToAnchor:logoutButton.topAnchor constant:-14.0],
        [deleteButton.widthAnchor constraintEqualToConstant:btnW],
        [deleteButton.heightAnchor constraintEqualToConstant:btnH]
    ]];
}

/// Asset-driven confirm sheet. Hit zones measured from @3x art (927×723 → 309×241 pt).
- (void)yk_setupConfirmOverlay {
    UIView *overlay = [[UIView alloc] init];
    overlay.translatesAutoresizingMaskIntoConstraints = NO;
    overlay.hidden = YES;
    overlay.alpha = 0.0;
    overlay.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.55];
    [self.view addSubview:overlay];
    self.yk_confirmOverlay = overlay;

    UIImageView *dialog = [[UIImageView alloc] init];
    dialog.translatesAutoresizingMaskIntoConstraints = NO;
    dialog.contentMode = UIViewContentModeScaleAspectFit;
    dialog.userInteractionEnabled = YES;
    [overlay addSubview:dialog];
    self.yk_confirmDialogView = dialog;

    UIButton *cancelHit = [UIButton buttonWithType:UIButtonTypeCustom];
    cancelHit.translatesAutoresizingMaskIntoConstraints = NO;
    cancelHit.accessibilityLabel = @"Cancel";
    [cancelHit addTarget:self action:@selector(yk_confirmCancelTapped:) forControlEvents:UIControlEventTouchUpInside];
    [dialog addSubview:cancelHit];
    self.yk_confirmCancelHit = cancelHit;

    UIButton *sureHit = [UIButton buttonWithType:UIButtonTypeCustom];
    sureHit.translatesAutoresizingMaskIntoConstraints = NO;
    sureHit.accessibilityLabel = @"Sure";
    [sureHit addTarget:self action:@selector(yk_confirmSureTapped:) forControlEvents:UIControlEventTouchUpInside];
    [dialog addSubview:sureHit];
    self.yk_confirmSureHit = sureHit;

    self.yk_confirmDialogWidth = [dialog.widthAnchor constraintEqualToConstant:309.0];
    self.yk_confirmDialogHeight = [dialog.heightAnchor constraintEqualToConstant:241.0];
    self.yk_cancelLeading = [cancelHit.leadingAnchor constraintEqualToAnchor:dialog.leadingAnchor constant:50.0];
    self.yk_cancelBottom = [cancelHit.bottomAnchor constraintEqualToAnchor:dialog.bottomAnchor constant:-33.0];
    self.yk_cancelWidth = [cancelHit.widthAnchor constraintEqualToConstant:100.0];
    self.yk_cancelHeight = [cancelHit.heightAnchor constraintEqualToConstant:32.0];
    self.yk_sureTrailing = [sureHit.trailingAnchor constraintEqualToAnchor:dialog.trailingAnchor constant:-36.0];
    self.yk_sureBottom = [sureHit.bottomAnchor constraintEqualToAnchor:dialog.bottomAnchor constant:-33.0];
    self.yk_sureWidth = [sureHit.widthAnchor constraintEqualToConstant:100.0];
    self.yk_sureHeight = [sureHit.heightAnchor constraintEqualToConstant:32.0];

    [NSLayoutConstraint activateConstraints:@[
        [overlay.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [overlay.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [overlay.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [overlay.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],

        [dialog.centerXAnchor constraintEqualToAnchor:overlay.centerXAnchor],
        [dialog.centerYAnchor constraintEqualToAnchor:overlay.centerYAnchor constant:-6.0],
        self.yk_confirmDialogWidth,
        self.yk_confirmDialogHeight,

        self.yk_cancelLeading,
        self.yk_cancelBottom,
        self.yk_cancelWidth,
        self.yk_cancelHeight,

        self.yk_sureTrailing,
        self.yk_sureBottom,
        self.yk_sureWidth,
        self.yk_sureHeight
    ]];
}

/// Scales dialog + Cancel/Sure hit rects with screen width (design base 309×241).
- (void)yk_updateConfirmHitRectsForCurrentBounds {
    CGFloat screenW = CGRectGetWidth(self.view.bounds);
    if (screenW <= 1.0) {
        return;
    }
    // 左右各留 24pt；小屏按比例缩小，大屏不超过设计宽 309。
    CGFloat dialogW = MIN(309.0, screenW - 48.0);
    CGFloat scale = dialogW / 309.0;
    CGFloat dialogH = 241.0 * scale;

    self.yk_confirmDialogWidth.constant = dialogW;
    self.yk_confirmDialogHeight.constant = dialogH;

    // 热区来自切图采样（pt）：
    // Cancel ≈ leading 50 / bottom 33 / 100×32
    // Sure   ≈ trailing 36 / bottom 33 / 100×32
    // 乘 scale 后随弹窗等比适配各机型。
    self.yk_cancelLeading.constant = 50.0 * scale;
    self.yk_cancelBottom.constant = -33.0 * scale;
    self.yk_cancelWidth.constant = 100.0 * scale;
    self.yk_cancelHeight.constant = 32.0 * scale;

    self.yk_sureTrailing.constant = -36.0 * scale;
    self.yk_sureBottom.constant = -33.0 * scale;
    self.yk_sureWidth.constant = 100.0 * scale;
    self.yk_sureHeight.constant = 32.0 * scale;
}

- (UIButton *)yk_rowButtonWithTitle:(NSString *)title action:(SEL)action {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.translatesAutoresizingMaskIntoConstraints = NO;
    button.backgroundColor = [UIColor colorWithRed:0.62 green:0.22 blue:0.88 alpha:0.92];
    button.layer.borderColor = UIColor.whiteColor.CGColor;
    button.layer.borderWidth = 1.5;
    button.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    button.contentEdgeInsets = UIEdgeInsetsMake(0.0, 18.0, 0.0, 40.0);
    [button setTitle:title forState:UIControlStateNormal];
    [button setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    button.titleLabel.font = [UIFont systemFontOfSize:16.0 weight:UIFontWeightRegular];
    [button addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];

    UIImageView *chevron = [[UIImageView alloc] initWithImage:[[UIImage systemImageNamed:@"chevron.right"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
    chevron.translatesAutoresizingMaskIntoConstraints = NO;
    chevron.tintColor = UIColor.whiteColor;
    chevron.contentMode = UIViewContentModeScaleAspectFit;
    chevron.userInteractionEnabled = NO;
    [button addSubview:chevron];

    [NSLayoutConstraint activateConstraints:@[
        [chevron.centerYAnchor constraintEqualToAnchor:button.centerYAnchor],
        [chevron.trailingAnchor constraintEqualToAnchor:button.trailingAnchor constant:-16.0],
        [chevron.widthAnchor constraintEqualToConstant:12.0],
        [chevron.heightAnchor constraintEqualToConstant:16.0]
    ]];
    return button;
}

- (UIButton *)yk_assetButtonNamed:(NSString *)imageName action:(SEL)action {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.translatesAutoresizingMaskIntoConstraints = NO;
    button.backgroundColor = UIColor.clearColor;
    button.adjustsImageWhenHighlighted = YES;
    UIImage *image = [[UIImage imageNamed:imageName] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    [button setBackgroundImage:image forState:UIControlStateNormal];
    [button setBackgroundImage:image forState:UIControlStateHighlighted];
    [button addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    return button;
}

- (void)yk_shadeListTapped:(UIButton *)sender {
    [self.navigationController pushViewController:[[YKShadeListViewController alloc] init] animated:YES];
}

- (void)yk_agreementTapped:(UIButton *)sender {
    YKLegalDocViewController *web = [[YKLegalDocViewController alloc] initWithDocumentKind:YKLegalDocumentKindTermsPact];
    web.yk_protocolURL = [YKOfficialSiteBaseURL stringByAppendingString:@"users"];
    [self.navigationController pushViewController:web animated:YES];
}

- (void)yk_privacyTapped:(UIButton *)sender {
    YKLegalDocViewController *web = [[YKLegalDocViewController alloc] initWithDocumentKind:YKLegalDocumentKindPrivacyPolicy];
    web.yk_protocolURL = [YKOfficialSiteBaseURL stringByAppendingString:@"privacy"];
    [self.navigationController pushViewController:web animated:YES];
}

- (void)yk_logoutTapped:(UIButton *)sender {
    [self yk_presentConfirmKind:YKSettingConfirmKindLogout];
}

- (void)yk_deleteTapped:(UIButton *)sender {
    [self yk_presentConfirmKind:YKSettingConfirmKindDelete];
}

- (void)yk_presentConfirmKind:(YKSettingConfirmKind)kind {
    self.yk_confirmKind = kind;
    // Confirm sheet art: delete_account_sheet / logout_sheet.
    NSString *imageName = (kind == YKSettingConfirmKindDelete)
        ? @"delete_account_sheet"
        : @"logout_sheet";
    self.yk_confirmDialogView.image = [[UIImage imageNamed:imageName] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    [self yk_updateConfirmHitRectsForCurrentBounds];
    self.yk_confirmOverlay.hidden = NO;
    [self.view bringSubviewToFront:self.yk_confirmOverlay];
    [UIView animateWithDuration:0.2 animations:^{
        self.yk_confirmOverlay.alpha = 1.0;
    }];
}

- (void)yk_dismissConfirmAnimated:(BOOL)animated completion:(void (^)(void))completion {
    void (^finish)(void) = ^{
        self.yk_confirmOverlay.hidden = YES;
        self.yk_confirmOverlay.alpha = 0.0;
        if (completion) {
            completion();
        }
    };
    if (!animated) {
        finish();
        return;
    }
    [UIView animateWithDuration:0.18 animations:^{
        self.yk_confirmOverlay.alpha = 0.0;
    } completion:^(BOOL finished) {
        finish();
    }];
}

- (void)yk_confirmCancelTapped:(UIButton *)sender {
    [self yk_dismissConfirmAnimated:YES completion:nil];
}

- (void)yk_confirmSureTapped:(UIButton *)sender {
    YKSettingConfirmKind kind = self.yk_confirmKind;
    __weak typeof(self) weakSelf = self;
    [self yk_dismissConfirmAnimated:YES completion:^{
        if (kind == YKSettingConfirmKindLogout) {
            [[YKRosterVault sharedRoster] yk_clearPresence];
            [YKLaunchSteward yk_presentLanding];
            return;
        }
        [YKCenterToast yk_showLoadingInView:weakSelf.view performAfterDelay:0.55 work:^{
            [[YKRosterVault sharedRoster] yk_eraseActiveAccount];
            [YKLaunchSteward yk_presentLanding];
        }];
    }];
}

@end
