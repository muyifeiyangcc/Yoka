//
//  YKSignUpViewController.m
//  Yoka
//

#import "YKSignUpViewController.h"
#import "YKProfileInfoViewController.h"

@implementation YKSignUpViewController

- (void)yk_configurePage {
    [super yk_configurePage];
    [self yk_setupViews];
}

- (void)yk_setupViews {
    UIButton *backButton = [self yk_addBackButton];

    UIImageView *titleImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Sign_up_back"]];
    titleImageView.translatesAutoresizingMaskIntoConstraints = NO;
    titleImageView.contentMode = UIViewContentModeScaleAspectFit;
    [self.view addSubview:titleImageView];

    UIImageView *emailLabel = [self yk_authFieldTitleImageViewWithName:@"Emailword"];
    UITextField *emailTextField = [self yk_authTextFieldWithPlaceholder:@"Email" secure:NO];
    UIImageView *passwordLabel = [self yk_authFieldTitleImageViewWithName:@"Passwordword"];
    UITextField *passwordTextField = [self yk_authTextFieldWithPlaceholder:@"Password" secure:YES];
    UIImageView *confirmLabel = [self yk_authFieldTitleImageViewWithName:@"Passwordword"];
    UITextField *confirmTextField = [self yk_authTextFieldWithPlaceholder:@"Enter the password again" secure:YES];
    [self.view addSubview:emailLabel];
    [self.view addSubview:emailTextField];
    [self.view addSubview:passwordLabel];
    [self.view addSubview:passwordTextField];
    [self.view addSubview:confirmLabel];
    [self.view addSubview:confirmTextField];

    UIButton *signUpButton = [self yk_authPixelButtonWithTitle:@"Sign up" primary:YES];
    [signUpButton addTarget:self action:@selector(yk_signUpButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:signUpButton];

    [NSLayoutConstraint activateConstraints:@[
        [titleImageView.centerYAnchor constraintEqualToAnchor:backButton.centerYAnchor],
        [titleImageView.leadingAnchor constraintEqualToAnchor:backButton.trailingAnchor constant:-2.0],
        [titleImageView.widthAnchor constraintEqualToConstant:96.0],
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

        [confirmLabel.topAnchor constraintEqualToAnchor:passwordTextField.bottomAnchor constant:22.0],
        [confirmLabel.leadingAnchor constraintEqualToAnchor:emailLabel.leadingAnchor],
        [confirmLabel.widthAnchor constraintEqualToConstant:87.0],
        [confirmLabel.heightAnchor constraintEqualToConstant:26.0],
        [confirmTextField.topAnchor constraintEqualToAnchor:confirmLabel.bottomAnchor constant:10.0],
        [confirmTextField.leadingAnchor constraintEqualToAnchor:emailTextField.leadingAnchor],
        [confirmTextField.trailingAnchor constraintEqualToAnchor:emailTextField.trailingAnchor],
        [confirmTextField.heightAnchor constraintEqualToConstant:52.0],

        [signUpButton.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [signUpButton.topAnchor constraintEqualToAnchor:confirmTextField.bottomAnchor constant:86.0],
        [signUpButton.widthAnchor constraintEqualToConstant:215.0],
        [signUpButton.heightAnchor constraintEqualToConstant:49.0]
    ]];
}

- (void)yk_signUpButtonTapped:(UIButton *)sender {
    [self.navigationController pushViewController:[[YKProfileInfoViewController alloc] init] animated:YES];
}

@end
