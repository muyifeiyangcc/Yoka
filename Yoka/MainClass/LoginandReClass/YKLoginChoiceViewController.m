//
//  YKLoginChoiceViewController.m
//  Yoka
//

#import "YKLoginChoiceViewController.h"
#import "YKSignInViewController.h"
#import "YKSignUpViewController.h"

@interface YKLoginChoiceViewController () <UITextViewDelegate>

@end

@implementation YKLoginChoiceViewController

- (void)yk_configurePage {
    [super yk_configurePage];
    [self yk_setupViews];
}

- (void)yk_setupViews {
    UIImageView *logoImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"auth_asset_01"]];
    logoImageView.translatesAutoresizingMaskIntoConstraints = NO;
    logoImageView.contentMode = UIViewContentModeScaleAspectFit;
    [self.view addSubview:logoImageView];

    UIImageView *loginButtonImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"auth_asset_10"]];
    loginButtonImageView.translatesAutoresizingMaskIntoConstraints = NO;
    loginButtonImageView.contentMode = UIViewContentModeScaleAspectFit;
    loginButtonImageView.userInteractionEnabled = YES;
    [self.view addSubview:loginButtonImageView];

    UIButton *loginButton = [UIButton buttonWithType:UIButtonTypeCustom];
    loginButton.translatesAutoresizingMaskIntoConstraints = NO;
    [loginButton addTarget:self action:@selector(yk_loginButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [loginButtonImageView addSubview:loginButton];

    UIImageView *newButtonImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"auth_asset_09"]];
    newButtonImageView.translatesAutoresizingMaskIntoConstraints = NO;
    newButtonImageView.contentMode = UIViewContentModeScaleAspectFit;
    newButtonImageView.userInteractionEnabled = YES;
    [self.view addSubview:newButtonImageView];

    UIButton *newButton = [UIButton buttonWithType:UIButtonTypeCustom];
    newButton.translatesAutoresizingMaskIntoConstraints = NO;
    [newButton addTarget:self action:@selector(yk_signUpButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [newButtonImageView addSubview:newButton];

    UITextView *signUpTextView = [self yk_linkTextViewWithText:@"Don't have an account? Sign up"
                                                    linkRanges:@[[NSValue valueWithRange:NSMakeRange(23, 7)]]
                                                       actions:@[@"yoka://sign-up"]];
    [self.view addSubview:signUpTextView];

    UITextView *agreementTextView = [self yk_linkTextViewWithText:@"Agree with  User Agreement and Privacy Policy"
                                                       linkRanges:@[
        [NSValue valueWithRange:NSMakeRange(12, 14)],
        [NSValue valueWithRange:NSMakeRange(31, 14)]
    ]
                                                          actions:@[@"yoka://user-agreement", @"yoka://privacy-policy"]];
    [self.view addSubview:agreementTextView];

    [NSLayoutConstraint activateConstraints:@[
        [logoImageView.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [logoImageView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:148.0],
        [logoImageView.widthAnchor constraintEqualToConstant:100.0],
        [logoImageView.heightAnchor constraintEqualToConstant:154.0],

        [loginButtonImageView.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [loginButtonImageView.bottomAnchor constraintEqualToAnchor:newButtonImageView.topAnchor constant:-22.0],
        [loginButtonImageView.widthAnchor constraintEqualToConstant:215.0],
        [loginButtonImageView.heightAnchor constraintEqualToConstant:49.0],

        [loginButton.topAnchor constraintEqualToAnchor:loginButtonImageView.topAnchor],
        [loginButton.leadingAnchor constraintEqualToAnchor:loginButtonImageView.leadingAnchor],
        [loginButton.trailingAnchor constraintEqualToAnchor:loginButtonImageView.trailingAnchor],
        [loginButton.bottomAnchor constraintEqualToAnchor:loginButtonImageView.bottomAnchor],

        [newButtonImageView.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [newButtonImageView.bottomAnchor constraintEqualToAnchor:signUpTextView.topAnchor constant:-34.0],
        [newButtonImageView.widthAnchor constraintEqualToConstant:215.0],
        [newButtonImageView.heightAnchor constraintEqualToConstant:49.0],

        [newButton.topAnchor constraintEqualToAnchor:newButtonImageView.topAnchor],
        [newButton.leadingAnchor constraintEqualToAnchor:newButtonImageView.leadingAnchor],
        [newButton.trailingAnchor constraintEqualToAnchor:newButtonImageView.trailingAnchor],
        [newButton.bottomAnchor constraintEqualToAnchor:newButtonImageView.bottomAnchor],

        [signUpTextView.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [signUpTextView.bottomAnchor constraintEqualToAnchor:agreementTextView.topAnchor constant:-48.0],
        [signUpTextView.widthAnchor constraintEqualToConstant:260.0],
        [signUpTextView.heightAnchor constraintEqualToConstant:28.0],

        [agreementTextView.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor constant:-28.0],
        [agreementTextView.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [agreementTextView.widthAnchor constraintEqualToConstant:330.0],
        [agreementTextView.heightAnchor constraintEqualToConstant:28.0]
    ]];
}

- (UITextView *)yk_linkTextViewWithText:(NSString *)text
                             linkRanges:(NSArray<NSValue *> *)linkRanges
                                actions:(NSArray<NSString *> *)actions {
    UITextView *textView = [[UITextView alloc] init];
    textView.translatesAutoresizingMaskIntoConstraints = NO;
    textView.backgroundColor = UIColor.clearColor;
    textView.textAlignment = NSTextAlignmentCenter;
    textView.scrollEnabled = NO;
    textView.editable = NO;
    textView.delegate = self;
    textView.textContainerInset = UIEdgeInsetsZero;
    textView.textContainer.lineFragmentPadding = 0.0;
    textView.linkTextAttributes = @{
        NSForegroundColorAttributeName: UIColor.whiteColor,
        NSUnderlineStyleAttributeName: @(NSUnderlineStyleSingle)
    };

    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.alignment = NSTextAlignmentCenter;
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
    if ([URL.absoluteString isEqualToString:@"yoka://sign-up"]) {
        [self yk_signUpButtonTapped:nil];
    }
    return NO;
}

- (void)yk_loginButtonTapped:(UIButton *)sender {
    [self.navigationController pushViewController:[[YKSignInViewController alloc] init] animated:YES];
}

- (void)yk_signUpButtonTapped:(UIButton *)sender {
    [self.navigationController pushViewController:[[YKSignUpViewController alloc] init] animated:YES];
}

@end
