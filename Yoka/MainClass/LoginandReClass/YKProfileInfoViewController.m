//
//  YKProfileInfoViewController.m
//  Yoka
//

#import "YKProfileInfoViewController.h"

@implementation YKProfileInfoViewController

- (void)yk_configurePage {
    [super yk_configurePage];
    [self yk_setupViews];
}

- (void)yk_setupViews {
    [self yk_addBackButton];

    UIView *avatarView = [[UIView alloc] init];
    avatarView.translatesAutoresizingMaskIntoConstraints = NO;
    avatarView.backgroundColor = UIColor.whiteColor;
    avatarView.layer.cornerRadius = 50.0;
    [self.view addSubview:avatarView];

    UIImageView *avatarImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"headplace"]];
    avatarImageView.translatesAutoresizingMaskIntoConstraints = NO;
    avatarImageView.contentMode = UIViewContentModeScaleAspectFit;
    [avatarView addSubview:avatarImageView];

    UIImageView *nameLabel = [self yk_authFieldTitleImageViewWithName:@"Nameword"];
    UITextField *nameTextField = [self yk_authTextFieldWithPlaceholder:@"Please enter" secure:NO];
    UIImageView *birthdayLabel = [self yk_authFieldTitleImageViewWithName:@"Birthdayword"];
    UIButton *birthdayButton = [self yk_authSelectButtonWithTitle:@"2000-01-01"];
    UIImageView *locationLabel = [self yk_authFieldTitleImageViewWithName:@"Locationword"];
    UIButton *locationButton = [self yk_authSelectButtonWithTitle:@"LA"];
    UIImageView *genderLabel = [self yk_authFieldTitleImageViewWithName:@"Genderword"];
    UIButton *genderButton = [self yk_authSelectButtonWithTitle:@"Male"];
    [self.view addSubview:nameLabel];
    [self.view addSubview:nameTextField];
    [self.view addSubview:birthdayLabel];
    [self.view addSubview:birthdayButton];
    [self.view addSubview:locationLabel];
    [self.view addSubview:locationButton];
    [self.view addSubview:genderLabel];
    [self.view addSubview:genderButton];

    UIButton *saveButton = [self yk_authPixelButtonWithTitle:@"Save" primary:YES];
    [saveButton addTarget:self action:@selector(yk_saveButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:saveButton];

    [NSLayoutConstraint activateConstraints:@[
        [avatarView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:78.0],
        [avatarView.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [avatarView.widthAnchor constraintEqualToConstant:100.0],
        [avatarView.heightAnchor constraintEqualToConstant:100.0],

        [avatarImageView.centerXAnchor constraintEqualToAnchor:avatarView.centerXAnchor],
        [avatarImageView.centerYAnchor constraintEqualToAnchor:avatarView.centerYAnchor],
        [avatarImageView.widthAnchor constraintEqualToConstant:58.0],
        [avatarImageView.heightAnchor constraintEqualToConstant:58.0],

        [nameLabel.topAnchor constraintEqualToAnchor:avatarView.bottomAnchor constant:22.0],
        [nameLabel.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:38.0],
        [nameLabel.widthAnchor constraintEqualToConstant:49.0],
        [nameLabel.heightAnchor constraintEqualToConstant:26.0],
        [nameTextField.topAnchor constraintEqualToAnchor:nameLabel.bottomAnchor constant:10.0],
        [nameTextField.leadingAnchor constraintEqualToAnchor:nameLabel.leadingAnchor],
        [nameTextField.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-38.0],
        [nameTextField.heightAnchor constraintEqualToConstant:52.0],

        [birthdayLabel.topAnchor constraintEqualToAnchor:nameTextField.bottomAnchor constant:20.0],
        [birthdayLabel.leadingAnchor constraintEqualToAnchor:nameLabel.leadingAnchor],
        [birthdayLabel.widthAnchor constraintEqualToConstant:75.0],
        [birthdayLabel.heightAnchor constraintEqualToConstant:26.0],
        [birthdayButton.topAnchor constraintEqualToAnchor:birthdayLabel.bottomAnchor constant:10.0],
        [birthdayButton.leadingAnchor constraintEqualToAnchor:nameTextField.leadingAnchor],
        [birthdayButton.trailingAnchor constraintEqualToAnchor:nameTextField.trailingAnchor],
        [birthdayButton.heightAnchor constraintEqualToConstant:52.0],

        [locationLabel.topAnchor constraintEqualToAnchor:birthdayButton.bottomAnchor constant:20.0],
        [locationLabel.leadingAnchor constraintEqualToAnchor:nameLabel.leadingAnchor],
        [locationLabel.widthAnchor constraintEqualToConstant:76.0],
        [locationLabel.heightAnchor constraintEqualToConstant:26.0],
        [locationButton.topAnchor constraintEqualToAnchor:locationLabel.bottomAnchor constant:10.0],
        [locationButton.leadingAnchor constraintEqualToAnchor:nameTextField.leadingAnchor],
        [locationButton.trailingAnchor constraintEqualToAnchor:nameTextField.trailingAnchor],
        [locationButton.heightAnchor constraintEqualToConstant:52.0],

        [genderLabel.topAnchor constraintEqualToAnchor:locationButton.bottomAnchor constant:20.0],
        [genderLabel.leadingAnchor constraintEqualToAnchor:nameLabel.leadingAnchor],
        [genderLabel.widthAnchor constraintEqualToConstant:61.0],
        [genderLabel.heightAnchor constraintEqualToConstant:26.0],
        [genderButton.topAnchor constraintEqualToAnchor:genderLabel.bottomAnchor constant:10.0],
        [genderButton.leadingAnchor constraintEqualToAnchor:nameTextField.leadingAnchor],
        [genderButton.trailingAnchor constraintEqualToAnchor:nameTextField.trailingAnchor],
        [genderButton.heightAnchor constraintEqualToConstant:52.0],

        [saveButton.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [saveButton.topAnchor constraintEqualToAnchor:genderButton.bottomAnchor constant:58.0],
        [saveButton.widthAnchor constraintEqualToConstant:215.0],
        [saveButton.heightAnchor constraintEqualToConstant:49.0]
    ]];
}

- (void)yk_saveButtonTapped:(UIButton *)sender {
    [self yk_enterMainInterface];
}

@end
