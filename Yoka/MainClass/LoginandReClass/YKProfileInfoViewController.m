//
//  YKProfileInfoViewController.m
//  Yoka
//

#import "YKProfileInfoViewController.h"
#import "YKAccountVault.h"
#import "YKBootNavigator.h"
#import "../../BaseClass/YKCenterToast.h"

@interface YKProfilePickSheetView : UIView

@property (nonatomic, strong) UIView *panelView;
@property (nonatomic, copy, nullable) void (^onDismiss)(void);

- (instancetype)initWithTitle:(NSString *)title;
- (void)yk_showInView:(UIView *)hostView;
- (void)yk_dismissAnimated:(BOOL)animated completion:(void (^ _Nullable)(void))completion;

@end

@implementation YKProfilePickSheetView

- (instancetype)initWithTitle:(NSString *)title {
    self = [super initWithFrame:CGRectZero];
    if (self) {
        self.translatesAutoresizingMaskIntoConstraints = NO;
        self.alpha = 0.0;

        UIView *dimView = [[UIView alloc] init];
        dimView.translatesAutoresizingMaskIntoConstraints = NO;
        dimView.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.52];
        [self addSubview:dimView];

        UITapGestureRecognizer *dimTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(yk_dimTapped)];
        [dimView addGestureRecognizer:dimTap];

        UIView *panel = [[UIView alloc] init];
        panel.translatesAutoresizingMaskIntoConstraints = NO;
        panel.backgroundColor = [UIColor colorWithRed:212.0 / 255.0 green:92.0 / 255.0 blue:214.0 / 255.0 alpha:0.98];
        panel.layer.cornerRadius = 24.0;
        panel.layer.borderWidth = 1.6;
        panel.layer.borderColor = UIColor.whiteColor.CGColor;
        panel.layer.maskedCorners = kCALayerMinXMinYCorner | kCALayerMaxXMinYCorner;
        panel.clipsToBounds = YES;
        panel.transform = CGAffineTransformMakeTranslation(0.0, 36.0);
        [self addSubview:panel];
        self.panelView = panel;

        UILabel *titleLabel = [[UILabel alloc] init];
        titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
        titleLabel.text = title;
        titleLabel.textAlignment = NSTextAlignmentCenter;
        titleLabel.textColor = UIColor.whiteColor;
        titleLabel.font = [UIFont fontWithName:@"SquadaOne-Regular" size:28.0] ?: [UIFont systemFontOfSize:26.0 weight:UIFontWeightBold];
        [panel addSubview:titleLabel];
        titleLabel.tag = 9001;

        [NSLayoutConstraint activateConstraints:@[
            [dimView.topAnchor constraintEqualToAnchor:self.topAnchor],
            [dimView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
            [dimView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
            [dimView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],

            [panel.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
            [panel.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
            [panel.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],

            [titleLabel.topAnchor constraintEqualToAnchor:panel.topAnchor constant:22.0],
            [titleLabel.leadingAnchor constraintEqualToAnchor:panel.leadingAnchor constant:24.0],
            [titleLabel.trailingAnchor constraintEqualToAnchor:panel.trailingAnchor constant:-24.0]
        ]];
    }
    return self;
}

- (UILabel *)yk_titleLabel {
    return (UILabel *)[self.panelView viewWithTag:9001];
}

- (void)yk_showInView:(UIView *)hostView {
    [hostView addSubview:self];
    [NSLayoutConstraint activateConstraints:@[
        [self.topAnchor constraintEqualToAnchor:hostView.topAnchor],
        [self.leadingAnchor constraintEqualToAnchor:hostView.leadingAnchor],
        [self.trailingAnchor constraintEqualToAnchor:hostView.trailingAnchor],
        [self.bottomAnchor constraintEqualToAnchor:hostView.bottomAnchor]
    ]];
    [hostView layoutIfNeeded];
    [UIView animateWithDuration:0.24
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
        self.alpha = 1.0;
        self.panelView.transform = CGAffineTransformIdentity;
    } completion:nil];
}

- (void)yk_dismissAnimated:(BOOL)animated completion:(void (^)(void))completion {
    void (^finish)(void) = ^{
        [self removeFromSuperview];
        if (self.onDismiss) {
            self.onDismiss();
        }
        if (completion) {
            completion();
        }
    };
    if (!animated) {
        finish();
        return;
    }
    [UIView animateWithDuration:0.18
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^{
        self.alpha = 0.0;
        self.panelView.transform = CGAffineTransformMakeTranslation(0.0, 36.0);
    } completion:^(BOOL finished) {
        finish();
    }];
}

- (void)yk_dimTapped {
    [self yk_dismissAnimated:YES completion:nil];
}

- (UIButton *)yk_pixelActionButtonWithImageName:(NSString *)imageName action:(SEL)action target:(id)target {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.translatesAutoresizingMaskIntoConstraints = NO;
    button.backgroundColor = UIColor.clearColor;
    button.adjustsImageWhenHighlighted = YES;
    // Background fills the equal-width frame; setImage keeps intrinsic aspect and looks unequal.
    UIImage *image = [[UIImage imageNamed:imageName] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    [button setBackgroundImage:image forState:UIControlStateNormal];
    [button addTarget:target action:action forControlEvents:UIControlEventTouchUpInside];
    return button;
}

@end

@interface YKProfileInfoViewController () <UIImagePickerControllerDelegate, UINavigationControllerDelegate>

@property (nonatomic, strong) UIImageView *yk_avatarImageView;
@property (nonatomic, strong) UIScrollView *yk_formScrollView;
@property (nonatomic, strong) UITextField *yk_nameField;
@property (nonatomic, strong) UIButton *yk_birthdayButton;
@property (nonatomic, strong) UITextField *yk_locationField;
@property (nonatomic, strong) UIButton *yk_genderButton;
@property (nonatomic, strong, nullable) UIImage *yk_pendingPortrait;
@property (nonatomic, strong, nullable) YKProfilePickSheetView *yk_activeSheet;
@property (nonatomic, strong, nullable) UIDatePicker *yk_sheetDatePicker;
@property (nonatomic, copy, nullable) NSString *yk_sheetSelectedGender;

@end

@implementation YKProfileInfoViewController

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)yk_configurePage {
    [super yk_configurePage];
    [self yk_setupViews];
    [self yk_hydrateFromVault];
    [self yk_registerKeyboardObservers];
}

- (void)yk_registerKeyboardObservers {
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

    UIScrollView *scrollView = [[UIScrollView alloc] init];
    scrollView.translatesAutoresizingMaskIntoConstraints = NO;
    scrollView.alwaysBounceVertical = YES;
    scrollView.keyboardDismissMode = UIScrollViewKeyboardDismissModeInteractive;
    scrollView.showsVerticalScrollIndicator = NO;
    scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    [self.view addSubview:scrollView];
    self.yk_formScrollView = scrollView;

    UIView *contentView = [[UIView alloc] init];
    contentView.translatesAutoresizingMaskIntoConstraints = NO;
    [scrollView addSubview:contentView];

    UIView *avatarView = [[UIView alloc] init];
    avatarView.translatesAutoresizingMaskIntoConstraints = NO;
    avatarView.backgroundColor = UIColor.whiteColor;
    avatarView.layer.cornerRadius = 50.0;
    avatarView.clipsToBounds = YES;
    avatarView.userInteractionEnabled = YES;
    [contentView addSubview:avatarView];

    UITapGestureRecognizer *avatarTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(yk_avatarTapped)];
    [avatarView addGestureRecognizer:avatarTap];

    UIImageView *avatarImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"headplace"]];
    avatarImageView.translatesAutoresizingMaskIntoConstraints = NO;
    avatarImageView.contentMode = UIViewContentModeScaleAspectFill;
    avatarImageView.clipsToBounds = YES;
    avatarImageView.userInteractionEnabled = NO;
    [avatarView addSubview:avatarImageView];
    self.yk_avatarImageView = avatarImageView;

    UIImageView *nameLabel = [self yk_authFieldTitleImageViewWithName:@"Nameword"];
    UITextField *nameTextField = [self yk_authTextFieldWithPlaceholder:@"Please enter" secure:NO];
    self.yk_nameField = nameTextField;

    UIImageView *birthdayLabel = [self yk_authFieldTitleImageViewWithName:@"Birthdayword"];
    UIButton *birthdayButton = [self yk_authSelectButtonWithTitle:@"2000-01-01"];
    [birthdayButton addTarget:self action:@selector(yk_birthdayTapped:) forControlEvents:UIControlEventTouchUpInside];
    self.yk_birthdayButton = birthdayButton;

    UIImageView *locationLabel = [self yk_authFieldTitleImageViewWithName:@"Locationword"];
    UITextField *locationTextField = [self yk_authTextFieldWithPlaceholder:@"Please enter" secure:NO];
    self.yk_locationField = locationTextField;

    UIImageView *genderLabel = [self yk_authFieldTitleImageViewWithName:@"Genderword"];
    UIButton *genderButton = [self yk_authSelectButtonWithTitle:@"Male"];
    [genderButton addTarget:self action:@selector(yk_genderTapped:) forControlEvents:UIControlEventTouchUpInside];
    self.yk_genderButton = genderButton;

    [contentView addSubview:nameLabel];
    [contentView addSubview:nameTextField];
    [contentView addSubview:birthdayLabel];
    [contentView addSubview:birthdayButton];
    [contentView addSubview:locationLabel];
    [contentView addSubview:locationTextField];
    [contentView addSubview:genderLabel];
    [contentView addSubview:genderButton];

    UIButton *saveButton = [self yk_authPixelButtonWithTitle:@"Save" primary:YES];
    [saveButton addTarget:self action:@selector(yk_saveButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [contentView addSubview:saveButton];

    [NSLayoutConstraint activateConstraints:@[
        [scrollView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor],
        [scrollView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [scrollView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [scrollView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],

        [contentView.topAnchor constraintEqualToAnchor:scrollView.contentLayoutGuide.topAnchor],
        [contentView.leadingAnchor constraintEqualToAnchor:scrollView.contentLayoutGuide.leadingAnchor],
        [contentView.trailingAnchor constraintEqualToAnchor:scrollView.contentLayoutGuide.trailingAnchor],
        [contentView.bottomAnchor constraintEqualToAnchor:scrollView.contentLayoutGuide.bottomAnchor],
        [contentView.widthAnchor constraintEqualToAnchor:scrollView.frameLayoutGuide.widthAnchor],

        [avatarView.topAnchor constraintEqualToAnchor:contentView.topAnchor constant:78.0],
        [avatarView.centerXAnchor constraintEqualToAnchor:contentView.centerXAnchor],
        [avatarView.widthAnchor constraintEqualToConstant:100.0],
        [avatarView.heightAnchor constraintEqualToConstant:100.0],

        [avatarImageView.topAnchor constraintEqualToAnchor:avatarView.topAnchor],
        [avatarImageView.leadingAnchor constraintEqualToAnchor:avatarView.leadingAnchor],
        [avatarImageView.trailingAnchor constraintEqualToAnchor:avatarView.trailingAnchor],
        [avatarImageView.bottomAnchor constraintEqualToAnchor:avatarView.bottomAnchor],

        [nameLabel.topAnchor constraintEqualToAnchor:avatarView.bottomAnchor constant:22.0],
        [nameLabel.leadingAnchor constraintEqualToAnchor:contentView.leadingAnchor constant:38.0],
        [nameLabel.widthAnchor constraintEqualToConstant:49.0],
        [nameLabel.heightAnchor constraintEqualToConstant:26.0],
        [nameTextField.topAnchor constraintEqualToAnchor:nameLabel.bottomAnchor constant:10.0],
        [nameTextField.leadingAnchor constraintEqualToAnchor:nameLabel.leadingAnchor],
        [nameTextField.trailingAnchor constraintEqualToAnchor:contentView.trailingAnchor constant:-38.0],
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
        [locationTextField.topAnchor constraintEqualToAnchor:locationLabel.bottomAnchor constant:10.0],
        [locationTextField.leadingAnchor constraintEqualToAnchor:nameTextField.leadingAnchor],
        [locationTextField.trailingAnchor constraintEqualToAnchor:nameTextField.trailingAnchor],
        [locationTextField.heightAnchor constraintEqualToConstant:52.0],

        [genderLabel.topAnchor constraintEqualToAnchor:locationTextField.bottomAnchor constant:20.0],
        [genderLabel.leadingAnchor constraintEqualToAnchor:nameLabel.leadingAnchor],
        [genderLabel.widthAnchor constraintEqualToConstant:61.0],
        [genderLabel.heightAnchor constraintEqualToConstant:26.0],
        [genderButton.topAnchor constraintEqualToAnchor:genderLabel.bottomAnchor constant:10.0],
        [genderButton.leadingAnchor constraintEqualToAnchor:nameTextField.leadingAnchor],
        [genderButton.trailingAnchor constraintEqualToAnchor:nameTextField.trailingAnchor],
        [genderButton.heightAnchor constraintEqualToConstant:52.0],

        [saveButton.centerXAnchor constraintEqualToAnchor:contentView.centerXAnchor],
        [saveButton.topAnchor constraintEqualToAnchor:genderButton.bottomAnchor constant:58.0],
        [saveButton.widthAnchor constraintEqualToConstant:215.0],
        [saveButton.heightAnchor constraintEqualToConstant:49.0],
        [saveButton.bottomAnchor constraintEqualToAnchor:contentView.bottomAnchor constant:-40.0]
    ]];

    [self.view bringSubviewToFront:backButton];
}

- (void)yk_keyboardWillChange:(NSNotification *)notification {
    NSDictionary *info = notification.userInfo;
    CGRect keyboardFrame = [info[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGRect keyboardInView = [self.view convertRect:keyboardFrame fromView:nil];
    CGFloat overlap = MAX(0.0, CGRectGetMaxY(self.view.bounds) - CGRectGetMinY(keyboardInView));
    NSTimeInterval duration = [info[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    UIViewAnimationOptions options = ([info[UIKeyboardAnimationCurveUserInfoKey] integerValue] << 16);

    UIEdgeInsets inset = self.yk_formScrollView.contentInset;
    inset.bottom = overlap + 16.0;
    [UIView animateWithDuration:duration delay:0.0 options:options animations:^{
        self.yk_formScrollView.contentInset = inset;
        self.yk_formScrollView.scrollIndicatorInsets = inset;
    } completion:nil];

    UIView *focused = nil;
    if (self.yk_nameField.isFirstResponder) {
        focused = self.yk_nameField;
    } else if (self.yk_locationField.isFirstResponder) {
        focused = self.yk_locationField;
    }
    if (!focused) {
        return;
    }
    CGRect fieldFrame = [focused convertRect:focused.bounds toView:self.yk_formScrollView];
    fieldFrame = CGRectInset(fieldFrame, 0.0, -24.0);
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.yk_formScrollView scrollRectToVisible:fieldFrame animated:YES];
    });
}

- (void)yk_keyboardWillHide:(NSNotification *)notification {
    NSDictionary *info = notification.userInfo;
    NSTimeInterval duration = [info[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    UIViewAnimationOptions options = ([info[UIKeyboardAnimationCurveUserInfoKey] integerValue] << 16);
    [UIView animateWithDuration:duration delay:0.0 options:options animations:^{
        self.yk_formScrollView.contentInset = UIEdgeInsetsZero;
        self.yk_formScrollView.scrollIndicatorInsets = UIEdgeInsetsZero;
    } completion:nil];
}

- (NSString *)yk_selectButtonTitle:(UIButton *)button {
    NSString *title = [button titleForState:UIControlStateNormal] ?: @"";
    return [title stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceCharacterSet];
}

- (void)yk_setSelectButton:(UIButton *)button title:(NSString *)title {
    [button setTitle:[NSString stringWithFormat:@"  %@", title] forState:UIControlStateNormal];
}

- (NSString *)yk_normalizedGender:(NSString *)gender {
    if ([gender.lowercaseString isEqualToString:@"female"]) {
        return @"Female";
    }
    return @"Male";
}

- (void)yk_hydrateFromVault {
    YKAccountVault *vault = [YKAccountVault sharedVault];
    NSDictionary *dossier = [vault yk_dossierForActiveMailbox];
    NSString *name = dossier[@"name"];
    if (![name isKindOfClass:NSString.class] || name.length == 0) {
        name = [vault yk_displayNameForActiveMailbox];
    }
    // Don't show generic fallbacks in the Name field on first-pass setup.
    if ([name isKindOfClass:NSString.class] &&
        name.length > 0 &&
        ![name isEqualToString:@"Yoka User"] &&
        ![name isEqualToString:@"Apple User"] &&
        ![name isEqualToString:@"Me"]) {
        self.yk_nameField.text = name;
    }
    if (![dossier isKindOfClass:NSDictionary.class]) {
        return;
    }
    NSString *birthday = dossier[@"birthday"];
    if ([birthday isKindOfClass:NSString.class] && birthday.length > 0) {
        [self yk_setSelectButton:self.yk_birthdayButton title:birthday];
    }
    NSString *location = dossier[@"location"];
    if ([location isKindOfClass:NSString.class] && location.length > 0) {
        self.yk_locationField.text = location;
    }
    NSString *gender = dossier[@"gender"];
    if ([gender isKindOfClass:NSString.class] && gender.length > 0) {
        [self yk_setSelectButton:self.yk_genderButton title:[self yk_normalizedGender:gender]];
    }
    UIImage *portrait = [vault yk_portraitImageForActiveMailbox];
    if (portrait) {
        self.yk_avatarImageView.image = portrait;
        self.yk_avatarImageView.contentMode = UIViewContentModeScaleAspectFill;
    }
}

- (void)yk_avatarTapped {
    [self.view endEditing:YES];
    [self yk_dismissActiveSheet];

    YKProfilePickSheetView *sheet = [[YKProfilePickSheetView alloc] initWithTitle:@"Avatar"];
    __weak typeof(self) weakSelf = self;
    __weak YKProfilePickSheetView *weakSheet = sheet;
    sheet.onDismiss = ^{
        if (weakSelf.yk_activeSheet == weakSheet) {
            weakSelf.yk_activeSheet = nil;
        }
    };
    self.yk_activeSheet = sheet;

    UIButton *cameraButton = [self yk_genderOptionButtonWithTitle:@"Camera" selected:NO];
    cameraButton.tag = 9201;
    [cameraButton addTarget:self action:@selector(yk_avatarSourceTapped:) forControlEvents:UIControlEventTouchUpInside];
    cameraButton.enabled = [UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera];
    cameraButton.alpha = cameraButton.enabled ? 1.0 : 0.45;

    UIButton *libraryButton = [self yk_genderOptionButtonWithTitle:@"Photo Library" selected:NO];
    libraryButton.tag = 9202;
    [libraryButton addTarget:self action:@selector(yk_avatarSourceTapped:) forControlEvents:UIControlEventTouchUpInside];

    [sheet.panelView addSubview:cameraButton];
    [sheet.panelView addSubview:libraryButton];

    UIButton *cancelButton = [sheet yk_pixelActionButtonWithImageName:@"auth_asset_06" action:@selector(yk_sheetCancelTapped) target:self];
    [sheet.panelView addSubview:cancelButton];

    UILabel *titleLabel = [sheet yk_titleLabel];
    [NSLayoutConstraint activateConstraints:@[
        [cameraButton.topAnchor constraintEqualToAnchor:titleLabel.bottomAnchor constant:22.0],
        [cameraButton.leadingAnchor constraintEqualToAnchor:sheet.panelView.leadingAnchor constant:28.0],
        [cameraButton.trailingAnchor constraintEqualToAnchor:sheet.panelView.trailingAnchor constant:-28.0],
        [cameraButton.heightAnchor constraintEqualToConstant:52.0],

        [libraryButton.topAnchor constraintEqualToAnchor:cameraButton.bottomAnchor constant:12.0],
        [libraryButton.leadingAnchor constraintEqualToAnchor:cameraButton.leadingAnchor],
        [libraryButton.trailingAnchor constraintEqualToAnchor:cameraButton.trailingAnchor],
        [libraryButton.heightAnchor constraintEqualToConstant:52.0],

        [cancelButton.topAnchor constraintEqualToAnchor:libraryButton.bottomAnchor constant:24.0],
        [cancelButton.centerXAnchor constraintEqualToAnchor:sheet.panelView.centerXAnchor],
        [cancelButton.widthAnchor constraintEqualToConstant:140.0],
        [cancelButton.heightAnchor constraintEqualToConstant:42.0],
        [cancelButton.bottomAnchor constraintEqualToAnchor:sheet.panelView.safeAreaLayoutGuide.bottomAnchor constant:-18.0]
    ]];

    [sheet yk_showInView:self.view];
}

- (void)yk_avatarSourceTapped:(UIButton *)sender {
    UIImagePickerControllerSourceType sourceType = (sender.tag == 9201)
        ? UIImagePickerControllerSourceTypeCamera
        : UIImagePickerControllerSourceTypePhotoLibrary;
    [self yk_dismissActiveSheet];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self yk_presentPicker:sourceType];
    });
}

- (void)yk_presentPicker:(UIImagePickerControllerSourceType)sourceType {
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.sourceType = sourceType;
    picker.allowsEditing = YES;
    picker.delegate = self;
    [self presentViewController:picker animated:YES completion:nil];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<UIImagePickerControllerInfoKey,id> *)info {
    UIImage *image = info[UIImagePickerControllerEditedImage] ?: info[UIImagePickerControllerOriginalImage];
    self.yk_pendingPortrait = image;
    self.yk_avatarImageView.image = image;
    self.yk_avatarImageView.contentMode = UIViewContentModeScaleAspectFill;
    [picker dismissViewControllerAnimated:YES completion:nil];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:nil];
}

- (void)yk_dismissActiveSheet {
    if (!self.yk_activeSheet) {
        return;
    }
    YKProfilePickSheetView *sheet = self.yk_activeSheet;
    self.yk_activeSheet = nil;
    self.yk_sheetDatePicker = nil;
    self.yk_sheetSelectedGender = nil;
    [sheet yk_dismissAnimated:YES completion:nil];
}

- (UIButton *)yk_genderOptionButtonWithTitle:(NSString *)title selected:(BOOL)selected {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.translatesAutoresizingMaskIntoConstraints = NO;
    button.layer.cornerRadius = 14.0;
    button.layer.borderWidth = 1.5;
    button.layer.borderColor = UIColor.whiteColor.CGColor;
    button.titleLabel.font = [UIFont systemFontOfSize:17.0 weight:UIFontWeightBold];
    [button setTitle:title forState:UIControlStateNormal];
    [button setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    button.backgroundColor = selected ? [UIColor colorWithWhite:1.0 alpha:0.28] : [UIColor colorWithWhite:1.0 alpha:0.12];
    return button;
}

- (void)yk_refreshGenderOptionStylesInSheet:(YKProfilePickSheetView *)sheet {
    UIButton *maleButton = [sheet.panelView viewWithTag:9101];
    UIButton *femaleButton = [sheet.panelView viewWithTag:9102];
    BOOL maleSelected = [self.yk_sheetSelectedGender isEqualToString:@"Male"];
    maleButton.backgroundColor = maleSelected ? [UIColor colorWithWhite:1.0 alpha:0.28] : [UIColor colorWithWhite:1.0 alpha:0.12];
    femaleButton.backgroundColor = (!maleSelected) ? [UIColor colorWithWhite:1.0 alpha:0.28] : [UIColor colorWithWhite:1.0 alpha:0.12];
}

- (NSArray<NSLayoutConstraint *> *)yk_sheetActionConstraintsForCancel:(UIButton *)cancelButton
                                                                 done:(UIButton *)doneButton
                                                                below:(NSLayoutAnchor *)belowAnchor
                                                                panel:(UIView *)panel
                                                            topOffset:(CGFloat)topOffset {
    UIStackView *row = [[UIStackView alloc] initWithArrangedSubviews:@[cancelButton, doneButton]];
    row.translatesAutoresizingMaskIntoConstraints = NO;
    row.axis = UILayoutConstraintAxisHorizontal;
    row.alignment = UIStackViewAlignmentFill;
    row.distribution = UIStackViewDistributionFillEqually;
    row.spacing = 14.0;
    [panel addSubview:row];

    CGFloat height = 49.0;
    return @[
        [row.topAnchor constraintEqualToAnchor:belowAnchor constant:topOffset],
        [row.leadingAnchor constraintEqualToAnchor:panel.leadingAnchor constant:28.0],
        [row.trailingAnchor constraintEqualToAnchor:panel.trailingAnchor constant:-28.0],
        [row.heightAnchor constraintEqualToConstant:height],
        [row.bottomAnchor constraintEqualToAnchor:panel.safeAreaLayoutGuide.bottomAnchor constant:-18.0]
    ];
}

- (void)yk_birthdayTapped:(UIButton *)sender {
    [self.view endEditing:YES];
    [self yk_dismissActiveSheet];

    YKProfilePickSheetView *sheet = [[YKProfilePickSheetView alloc] initWithTitle:@"Birthday"];
    __weak typeof(self) weakSelf = self;
    __weak YKProfilePickSheetView *weakSheet = sheet;
    sheet.onDismiss = ^{
        if (weakSelf.yk_activeSheet == weakSheet) {
            weakSelf.yk_activeSheet = nil;
            weakSelf.yk_sheetDatePicker = nil;
        }
    };
    self.yk_activeSheet = sheet;

    UIDatePicker *picker = [[UIDatePicker alloc] init];
    picker.translatesAutoresizingMaskIntoConstraints = NO;
    picker.datePickerMode = UIDatePickerModeDate;
    picker.preferredDatePickerStyle = UIDatePickerStyleWheels;
    picker.maximumDate = [NSDate date];
    picker.tintColor = UIColor.whiteColor;
    if (@available(iOS 13.0, *)) {
        picker.overrideUserInterfaceStyle = UIUserInterfaceStyleDark;
    }

    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"yyyy-MM-dd";
    NSDate *current = [formatter dateFromString:[self yk_selectButtonTitle:self.yk_birthdayButton]];
    if (current) {
        picker.date = current;
    }
    self.yk_sheetDatePicker = picker;
    [sheet.panelView addSubview:picker];

    UIButton *cancelButton = [sheet yk_pixelActionButtonWithImageName:@"auth_asset_06" action:@selector(yk_sheetCancelTapped) target:self];
    UIButton *doneButton = [sheet yk_pixelActionButtonWithImageName:@"auth_asset_02" action:@selector(yk_birthdayDoneTapped) target:self];
    [sheet.panelView addSubview:cancelButton];
    [sheet.panelView addSubview:doneButton];

    UILabel *titleLabel = [sheet yk_titleLabel];
    NSMutableArray<NSLayoutConstraint *> *constraints = [NSMutableArray arrayWithArray:@[
        [picker.topAnchor constraintEqualToAnchor:titleLabel.bottomAnchor constant:8.0],
        [picker.leadingAnchor constraintEqualToAnchor:sheet.panelView.leadingAnchor constant:8.0],
        [picker.trailingAnchor constraintEqualToAnchor:sheet.panelView.trailingAnchor constant:-8.0],
        [picker.heightAnchor constraintEqualToConstant:180.0]
    ]];
    [constraints addObjectsFromArray:[self yk_sheetActionConstraintsForCancel:cancelButton
                                                                         done:doneButton
                                                                        below:picker.bottomAnchor
                                                                        panel:sheet.panelView
                                                                    topOffset:8.0]];
    [NSLayoutConstraint activateConstraints:constraints];

    [sheet yk_showInView:self.view];
}

- (void)yk_genderTapped:(UIButton *)sender {
    [self.view endEditing:YES];
    [self yk_dismissActiveSheet];

    self.yk_sheetSelectedGender = [self yk_normalizedGender:[self yk_selectButtonTitle:self.yk_genderButton]];

    YKProfilePickSheetView *sheet = [[YKProfilePickSheetView alloc] initWithTitle:@"Gender"];
    __weak typeof(self) weakSelf = self;
    __weak YKProfilePickSheetView *weakSheet = sheet;
    sheet.onDismiss = ^{
        if (weakSelf.yk_activeSheet == weakSheet) {
            weakSelf.yk_activeSheet = nil;
            weakSelf.yk_sheetSelectedGender = nil;
        }
    };
    self.yk_activeSheet = sheet;

    UIButton *maleButton = [self yk_genderOptionButtonWithTitle:@"Male" selected:[self.yk_sheetSelectedGender isEqualToString:@"Male"]];
    maleButton.tag = 9101;
    [maleButton addTarget:self action:@selector(yk_genderOptionTapped:) forControlEvents:UIControlEventTouchUpInside];

    UIButton *femaleButton = [self yk_genderOptionButtonWithTitle:@"Female" selected:[self.yk_sheetSelectedGender isEqualToString:@"Female"]];
    femaleButton.tag = 9102;
    [femaleButton addTarget:self action:@selector(yk_genderOptionTapped:) forControlEvents:UIControlEventTouchUpInside];

    [sheet.panelView addSubview:maleButton];
    [sheet.panelView addSubview:femaleButton];

    UIButton *cancelButton = [sheet yk_pixelActionButtonWithImageName:@"auth_asset_06" action:@selector(yk_sheetCancelTapped) target:self];
    UIButton *doneButton = [sheet yk_pixelActionButtonWithImageName:@"auth_asset_02" action:@selector(yk_genderDoneTapped) target:self];
    [sheet.panelView addSubview:cancelButton];
    [sheet.panelView addSubview:doneButton];

    UILabel *titleLabel = [sheet yk_titleLabel];
    NSMutableArray<NSLayoutConstraint *> *constraints = [NSMutableArray arrayWithArray:@[
        [maleButton.topAnchor constraintEqualToAnchor:titleLabel.bottomAnchor constant:22.0],
        [maleButton.leadingAnchor constraintEqualToAnchor:sheet.panelView.leadingAnchor constant:28.0],
        [maleButton.trailingAnchor constraintEqualToAnchor:sheet.panelView.trailingAnchor constant:-28.0],
        [maleButton.heightAnchor constraintEqualToConstant:52.0],

        [femaleButton.topAnchor constraintEqualToAnchor:maleButton.bottomAnchor constant:12.0],
        [femaleButton.leadingAnchor constraintEqualToAnchor:maleButton.leadingAnchor],
        [femaleButton.trailingAnchor constraintEqualToAnchor:maleButton.trailingAnchor],
        [femaleButton.heightAnchor constraintEqualToConstant:52.0]
    ]];
    [constraints addObjectsFromArray:[self yk_sheetActionConstraintsForCancel:cancelButton
                                                                         done:doneButton
                                                                        below:femaleButton.bottomAnchor
                                                                        panel:sheet.panelView
                                                                    topOffset:24.0]];
    [NSLayoutConstraint activateConstraints:constraints];

    [sheet yk_showInView:self.view];
}

- (void)yk_genderOptionTapped:(UIButton *)sender {
    self.yk_sheetSelectedGender = sender.tag == 9102 ? @"Female" : @"Male";
    if (self.yk_activeSheet) {
        [self yk_refreshGenderOptionStylesInSheet:self.yk_activeSheet];
    }
}

- (void)yk_sheetCancelTapped {
    [self yk_dismissActiveSheet];
}

- (void)yk_birthdayDoneTapped {
    NSDate *date = self.yk_sheetDatePicker.date ?: [NSDate date];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"yyyy-MM-dd";
    [self yk_setSelectButton:self.yk_birthdayButton title:[formatter stringFromDate:date]];
    [self yk_dismissActiveSheet];
}

- (void)yk_genderDoneTapped {
    NSString *gender = [self yk_normalizedGender:self.yk_sheetSelectedGender ?: @"Male"];
    [self yk_setSelectButton:self.yk_genderButton title:gender];
    [self yk_dismissActiveSheet];
}

- (void)yk_saveButtonTapped:(UIButton *)sender {
    [self.view endEditing:YES];
    [self yk_dismissActiveSheet];
    NSString *name = [self.yk_nameField.text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet] ?: @"";
    if (name.length == 0) {
        [YKCenterToast yk_showNotice:@"Please enter your name" inView:self.view];
        return;
    }
    NSString *location = [self.yk_locationField.text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet] ?: @"";
    if (location.length == 0) {
        [YKCenterToast yk_showNotice:@"Please enter" inView:self.view];
        return;
    }
    NSString *gender = [self yk_normalizedGender:[self yk_selectButtonTitle:self.yk_genderButton]];
    __weak typeof(self) weakSelf = self;
    [YKCenterToast yk_showLoadingInView:self.view performAfterDelay:0.55 work:^{
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) { return; }
        [[YKAccountVault sharedVault] yk_saveDossierName:name
                                                birthday:[self yk_selectButtonTitle:self.yk_birthdayButton]
                                                location:location
                                                  gender:gender
                                           portraitImage:self.yk_pendingPortrait];
        self.yk_pendingPortrait = nil;

        if (self.yk_firstPassSetup) {
            [YKBootNavigator yk_showMainTabs];
        } else {
            [YKCenterToast yk_showNotice:@"Saved" inView:self.view];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.6 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self.navigationController popViewControllerAnimated:YES];
            });
        }
    }];
}

@end
