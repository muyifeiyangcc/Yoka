//
//  YKEulaSheetViewController.m
//  Yoka
//

#import "YKEulaSheetViewController.h"
#import "YKLegalAckVault.h"

@interface YKEulaSheetViewController ()

@property (nonatomic, copy, nullable) void (^yk_completion)(BOOL accepted);
@property (nonatomic, strong) UIView *yk_panelView;
@property (nonatomic, assign) BOOL yk_didFinish;

@end

@implementation YKEulaSheetViewController

+ (void)yk_presentFromViewController:(UIViewController *)presenter
                          completion:(void (^)(BOOL accepted))completion {
    YKEulaSheetViewController *sheet = [[YKEulaSheetViewController alloc] init];
    sheet.yk_completion = completion;
    sheet.modalPresentationStyle = UIModalPresentationOverFullScreen;
    sheet.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    [presenter presentViewController:sheet animated:YES completion:nil];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.clearColor;
    [self yk_buildSheet];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self yk_animatePanelIn];
}

- (NSString *)yk_eulaBodyText {
    return @"This End User License Agreement (EULA) governs your use of the Yoka Application (hereinafter referred to as the \"App\"), A social community built around Y2K aesthetics. By downloading, accessing or using the App, you agree to be bound by this Agreement. If you do not agree to these terms, you may not use this application.\n\n"
    @"1. Qualifications\n"
    @"By using the Yaga App (the \"App\"), you confirm that you are at least 18 years of age. You agree to provide true and accurate age information during registration or use. If you are under the age of 18, you need the express consent of a parent or legal guardian to use the App.\n\n"
    @"2. User Generated Content\n"
    @"This app allows users to post and share yoga-related video content .\n"
    @"By posting content, you agree to the following terms:\n"
    @"Prohibited Content\n"
    @"You may not post any content that is offensive, harmful or illegal, including but not limited to:\n"
    @"- Hate speech, abuse, harassment or personal attacks targeting other users, yoga instructors, bloggers or related personnel;\n"
    @"- Pornographic, explicit or vulgar content;\n"
    @"- Content that promotes violence, discrimination, illegal activities or violations of the rights of others;\n"
    @"- Any content that disrupts the positive and healthy yoga community atmosphere, violates public order and good customs, or is irrelevant to yoga;\n"
    @"- Content that infringes on the intellectual property rights of others.\n"
    @"Content Licensing\n"
    @"You retain ownership of the content posted, but by posting, you grant Yaga a non-exclusive license to use, distribute, display, and provide yoga-related content recommendations within the App. This license shall remain in effect until you delete the posted content or terminate your account.\n\n"
    @"3. Reporting and Response Mechanism\n"
    @"3.1 Your Responsibilities\n"
    @"If you become aware of User content that violates this EULA, you agree to report it immediately through Yaga's built-in reporting mechanism.\n"
    @"3.2 Our Response\n"
    @"We will review the reported content within 24 hours and take appropriate measures based on the severity of the violation, including but not limited to removing the offending content, warning the offending user, restricting the user’s posting rights, or banning the offending user. Users who repeatedly violate the rules or commit serious violations may face permanent suspension of their accounts.\n\n"
    @"4. Privacy Policy\n"
    @"By using the App, you acknowledge that you have read and understood our [Privacy Policy], which details how we collect, use, store and protect your personal information.\n\n"
    @"5. Termination\n"
    @"We may terminate or suspend your access to Yaga at any time for any reason, with or without prior notice. You can also stop using Yaga and delete your account at any time; upon account deletion, your posted content will be removed in a timely manner.\n\n"
    @"6. Modification of the Agreement\n"
    @"We may amend this Agreement at any time to adapt to changes in laws and regulations or adjustments to the App’s functions. Changes will be announced in the App, and your continued use of the App after the announcement of the changes means your acceptance of the revised terms. If you do not agree to the revised terms, you should stop using the App immediately.\n\n"
    @"7. Disclaimer\n"
    @"Yaga is provided \"AS IS\" without warranties of any kind, express or implied. We do not guarantee that the application will always be interruption-free, error-free or completely secure.\n\n"
    @"8. Limitation of Liability\n"
    @"To the fullest extent permitted by law, we are not liable for any direct, indirect, incidental, consequential or special damages caused by your use of Yaga.";
}

- (UIButton *)yk_pixelButtonWithImageName:(NSString *)imageName action:(SEL)action {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.translatesAutoresizingMaskIntoConstraints = NO;
    button.backgroundColor = UIColor.clearColor;
    button.imageView.contentMode = UIViewContentModeScaleAspectFit;
    [button setImage:[[UIImage imageNamed:imageName] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]
            forState:UIControlStateNormal];
    [button addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    return button;
}

- (void)yk_buildSheet {
    UIView *dimView = [[UIView alloc] init];
    dimView.translatesAutoresizingMaskIntoConstraints = NO;
    dimView.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.35];
    [self.view addSubview:dimView];

    UITapGestureRecognizer *dimTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(yk_cancelTapped)];
    [dimView addGestureRecognizer:dimTap];

    UIView *panel = [[UIView alloc] init];
    panel.translatesAutoresizingMaskIntoConstraints = NO;
    panel.backgroundColor = [UIColor colorWithRed:212.0 / 255.0 green:92.0 / 255.0 blue:214.0 / 255.0 alpha:1.0];
    panel.layer.cornerRadius = 28.0;
    panel.layer.maskedCorners = kCALayerMinXMinYCorner | kCALayerMaxXMinYCorner;
    panel.clipsToBounds = YES;
    [self.view addSubview:panel];
    self.yk_panelView = panel;

    UITextView *textView = [[UITextView alloc] init];
    textView.translatesAutoresizingMaskIntoConstraints = NO;
    textView.backgroundColor = UIColor.clearColor;
    textView.editable = NO;
    textView.selectable = YES;
    textView.showsVerticalScrollIndicator = YES;
    textView.textContainerInset = UIEdgeInsetsMake(28.0, 22.0, 16.0, 22.0);
    textView.textContainer.lineFragmentPadding = 0.0;
    textView.textColor = UIColor.whiteColor;
    textView.font = [UIFont systemFontOfSize:15.0 weight:UIFontWeightRegular];
    textView.text = [self yk_eulaBodyText];
    [panel addSubview:textView];

    UIButton *cancelButton = [self yk_pixelButtonWithImageName:@"auth_asset_06" action:@selector(yk_cancelTapped)];
    UIButton *agreeButton = [self yk_pixelButtonWithImageName:@"auth_asset_08" action:@selector(yk_agreeTapped)];
    [panel addSubview:cancelButton];
    [panel addSubview:agreeButton];

    [NSLayoutConstraint activateConstraints:@[
        [dimView.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [dimView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [dimView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [dimView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],

        [panel.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [panel.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [panel.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
        [panel.heightAnchor constraintEqualToAnchor:self.view.heightAnchor multiplier:0.68],

        [cancelButton.leadingAnchor constraintEqualToAnchor:panel.leadingAnchor constant:36.0],
        [cancelButton.bottomAnchor constraintEqualToAnchor:panel.safeAreaLayoutGuide.bottomAnchor constant:-18.0],
        [cancelButton.widthAnchor constraintEqualToConstant:148.0],
        [cancelButton.heightAnchor constraintEqualToConstant:49.0],

        [agreeButton.trailingAnchor constraintEqualToAnchor:panel.trailingAnchor constant:-36.0],
        [agreeButton.bottomAnchor constraintEqualToAnchor:cancelButton.bottomAnchor],
        [agreeButton.widthAnchor constraintEqualToConstant:148.0],
        [agreeButton.heightAnchor constraintEqualToConstant:49.0],

        [textView.topAnchor constraintEqualToAnchor:panel.topAnchor],
        [textView.leadingAnchor constraintEqualToAnchor:panel.leadingAnchor],
        [textView.trailingAnchor constraintEqualToAnchor:panel.trailingAnchor],
        [textView.bottomAnchor constraintEqualToAnchor:cancelButton.topAnchor constant:-18.0]
    ]];

    panel.transform = CGAffineTransformMakeTranslation(0.0, UIScreen.mainScreen.bounds.size.height);
}

- (void)yk_animatePanelIn {
    [UIView animateWithDuration:0.28
                          delay:0.0
         usingSpringWithDamping:0.92
          initialSpringVelocity:0.6
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
        self.yk_panelView.transform = CGAffineTransformIdentity;
    } completion:nil];
}

- (void)yk_finishWithAccepted:(BOOL)accepted {
    if (self.yk_didFinish) {
        return;
    }
    self.yk_didFinish = YES;
    void (^completion)(BOOL) = self.yk_completion;
    self.yk_completion = nil;
    [self dismissViewControllerAnimated:YES completion:^{
        if (completion) {
            completion(accepted);
        }
    }];
}

- (void)yk_cancelTapped {
    [self yk_finishWithAccepted:NO];
}

- (void)yk_agreeTapped {
    [YKLegalAckVault yk_markLicenseAccepted];
    [self yk_finishWithAccepted:YES];
}

@end
