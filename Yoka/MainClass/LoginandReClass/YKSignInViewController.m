//
//  YKSignInViewController.m
//  Yoka
//

#import "YKSignInViewController.h"
#import "YKForgetPasswordViewController.h"

@implementation YKSignInViewController

- (void)yk_configurePage {
    [super yk_configurePage];
    [self yk_setupViews];
}

- (void)yk_setupViews {
    UIButton *backButton = [self yk_addBackButton];

    UIImageView *titleImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Sign_in_back"]];
    titleImageView.translatesAutoresizingMaskIntoConstraints = NO;
    titleImageView.contentMode = UIViewContentModeScaleAspectFit;
    [self.view addSubview:titleImageView];

    UIImageView *emailLabel = [self yk_authFieldTitleImageViewWithName:@"Emailword"];
    UITextField *emailTextField = [self yk_authTextFieldWithPlaceholder:@"Email" secure:NO];
    UIImageView *passwordLabel = [self yk_authFieldTitleImageViewWithName:@"Passwordword"];
    UITextField *passwordTextField = [self yk_authTextFieldWithPlaceholder:@"Password" secure:YES];
    [self.view addSubview:emailLabel];
    [self.view addSubview:emailTextField];
    [self.view addSubview:passwordLabel];
    [self.view addSubview:passwordTextField];

    UIButton *forgotButton = [UIButton buttonWithType:UIButtonTypeCustom];
    forgotButton.translatesAutoresizingMaskIntoConstraints = NO;
    [forgotButton setTitle:@"Forget password?" forState:UIControlStateNormal];
    [forgotButton setTitleColor:[UIColor colorWithWhite:1.0 alpha:0.72] forState:UIControlStateNormal];
    forgotButton.titleLabel.font = [UIFont systemFontOfSize:12.0 weight:UIFontWeightRegular];
    [forgotButton addTarget:self action:@selector(yk_forgetButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:forgotButton];

    UIButton *loginButton = [self yk_authPixelButtonWithTitle:@"Log in" primary:YES];
    [loginButton addTarget:self action:@selector(yk_loginButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:loginButton];

    [NSLayoutConstraint activateConstraints:@[
        [titleImageView.centerYAnchor constraintEqualToAnchor:backButton.centerYAnchor],
        [titleImageView.leadingAnchor constraintEqualToAnchor:backButton.trailingAnchor constant:-2.0],
        [titleImageView.widthAnchor constraintEqualToConstant:87.0],
        [titleImageView.heightAnchor constraintEqualToConstant:30.0],

        [emailLabel.topAnchor constraintEqualToAnchor:backButton.bottomAnchor constant:42.0],
        [emailLabel.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:38.0],
        [emailLabel.widthAnchor constraintEqualToConstant:48.0],
        [emailLabel.heightAnchor constraintEqualToConstant:26.0],
        [emailTextField.topAnchor constraintEqualToAnchor:emailLabel.bottomAnchor constant:10.0],
        [emailTextField.leadingAnchor constraintEqualToAnchor:emailLabel.leadingAnchor],
        [emailTextField.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-38.0],
        [emailTextField.heightAnchor constraintEqualToConstant:52.0],

        [passwordLabel.topAnchor constraintEqualToAnchor:emailTextField.bottomAnchor constant:22.0],
        [passwordLabel.leadingAnchor constraintEqualToAnchor:emailLabel.leadingAnchor],
        [passwordLabel.widthAnchor constraintEqualToConstant:87.0],
        [passwordLabel.heightAnchor constraintEqualToConstant:26.0],
        [passwordTextField.topAnchor constraintEqualToAnchor:passwordLabel.bottomAnchor constant:10.0],
        [passwordTextField.leadingAnchor constraintEqualToAnchor:emailTextField.leadingAnchor],
        [passwordTextField.trailingAnchor constraintEqualToAnchor:emailTextField.trailingAnchor],
        [passwordTextField.heightAnchor constraintEqualToConstant:52.0],

        [forgotButton.topAnchor constraintEqualToAnchor:passwordTextField.bottomAnchor constant:10.0],
        [forgotButton.trailingAnchor constraintEqualToAnchor:passwordTextField.trailingAnchor],
        [forgotButton.heightAnchor constraintEqualToConstant:28.0],

        [loginButton.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [loginButton.topAnchor constraintEqualToAnchor:passwordTextField.bottomAnchor constant:78.0],
        [loginButton.widthAnchor constraintEqualToConstant:215.0],
        [loginButton.heightAnchor constraintEqualToConstant:49.0]
    ]];
}

- (void)yk_forgetButtonTapped:(UIButton *)sender {
    [self.navigationController pushViewController:[[YKForgetPasswordViewController alloc] init] animated:YES];
}

- (void)yk_loginButtonTapped:(UIButton *)sender {
    [self yk_enterMainInterface];
}

@end
