//
//  YKForgetPasswordViewController.m
//  Yoka
//

#import "YKForgetPasswordViewController.h"
#import "YKRosterVault.h"
#import "YKCenterToast.h"

@interface YKForgetPasswordViewController ()

@property (nonatomic, strong) UITextField *yk_emailField;
@property (nonatomic, strong) UITextField *yk_passwordField;
@property (nonatomic, strong) UITextField *yk_confirmField;

@end

@implementation YKForgetPasswordViewController

- (void)yk_configurePage {
    [super yk_configurePage];
    [self yk_setupViews];
}

- (void)yk_setupViews {
    UIButton *backButton = [self yk_addBackButton];

    UIImageView *titleImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Forget_password_back"]];
    titleImageView.translatesAutoresizingMaskIntoConstraints = NO;
    titleImageView.contentMode = UIViewContentModeScaleAspectFit;
    [self.view addSubview:titleImageView];

    UIImageView *emailLabel = [self yk_authFieldTitleImageViewWithName:@"Emailword"];
    UITextField *emailTextField = [self yk_authTextFieldWithPlaceholder:@"Email" secure:NO];
    emailTextField.keyboardType = UIKeyboardTypeEmailAddress;
    emailTextField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    emailTextField.autocorrectionType = UITextAutocorrectionTypeNo;
    self.yk_emailField = emailTextField;

    UIImageView *passwordLabel = [self yk_authFieldTitleImageViewWithName:@"Passwordword"];
    UITextField *passwordTextField = [self yk_authTextFieldWithPlaceholder:@"Password" secure:YES];
    self.yk_passwordField = passwordTextField;

    UIImageView *confirmLabel = [self yk_authFieldTitleImageViewWithName:@"Passwordword"];
    UITextField *confirmTextField = [self yk_authTextFieldWithPlaceholder:@"Enter the password again" secure:YES];
    self.yk_confirmField = confirmTextField;

    [self.view addSubview:emailLabel];
    [self.view addSubview:emailTextField];
    [self.view addSubview:passwordLabel];
    [self.view addSubview:passwordTextField];
    [self.view addSubview:confirmLabel];
    [self.view addSubview:confirmTextField];

    UIButton *saveButton = [self yk_authPixelButtonWithTitle:@"Save" primary:YES];
    [saveButton addTarget:self action:@selector(yk_saveButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:saveButton];

    [NSLayoutConstraint activateConstraints:@[
        [titleImageView.centerYAnchor constraintEqualToAnchor:backButton.centerYAnchor],
        [titleImageView.leadingAnchor constraintEqualToAnchor:backButton.trailingAnchor constant:-2.0],
        [titleImageView.widthAnchor constraintEqualToConstant:209.0],
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

        [saveButton.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [saveButton.topAnchor constraintEqualToAnchor:confirmTextField.bottomAnchor constant:86.0],
        [saveButton.widthAnchor constraintEqualToConstant:215.0],
        [saveButton.heightAnchor constraintEqualToConstant:49.0]
    ]];
}

- (void)yk_saveButtonTapped:(UIButton *)sender {
    [self.view endEditing:YES];
    NSString *password = self.yk_passwordField.text ?: @"";
    NSString *confirm = self.yk_confirmField.text ?: @"";
    if (![password isEqualToString:confirm]) {
        [YKCenterToast yk_showNotice:@"Passwords do not match" inView:self.view];
        return;
    }
    __weak typeof(self) weakSelf = self;
    [YKCenterToast yk_showLoadingInView:self.view performAfterDelay:0.55 work:^{
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) { return; }
        NSString *error = nil;
        BOOL ok = [[YKRosterVault sharedRoster] yk_replaceSecretForMailbox:self.yk_emailField.text
                                                                   secret:password
                                                             errorMessage:&error];
        if (!ok) {
            [YKCenterToast yk_showNotice:error ?: @"Save failed" inView:self.view];
            return;
        }
        [YKCenterToast yk_showNotice:@"Password updated" inView:self.view];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.8 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self.navigationController popViewControllerAnimated:YES];
        });
    }];
}

@end
