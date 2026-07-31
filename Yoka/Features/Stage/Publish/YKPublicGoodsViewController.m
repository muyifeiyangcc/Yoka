//
//  YKPublicGoodsViewController.m
//  Yoka
//

#import "YKPublicGoodsViewController.h"
#import <PhotosUI/PhotosUI.h>
#import "YKCenterToast.h"

@interface YKPublicGoodsViewController () <PHPickerViewControllerDelegate, UITextViewDelegate, UITextFieldDelegate>

@property (nonatomic, strong) UIScrollView *yk_scrollView;
@property (nonatomic, strong) UITextField *nameTextField;
@property (nonatomic, strong) UITextField *priceTextField;
@property (nonatomic, strong) UITextView *descriptionTextView;
@property (nonatomic, strong) UILabel *descriptionPlaceholderLabel;
@property (nonatomic, strong) UILabel *countLabel;
@property (nonatomic, strong) UIButton *uploadButton;
@property (nonatomic, strong) UIButton *yk_addButton;
@property (nonatomic, strong, nullable) UIImage *selectedImage;

@end

@implementation YKPublicGoodsViewController

- (void)yk_configurePage {
    [super yk_configurePage];
    [self yk_setupViews];
}

- (void)yk_setupViews {
    UIButton *backButton = [self yk_addBackButton];

    UIButton *addButton = [UIButton buttonWithType:UIButtonTypeCustom];
    addButton.translatesAutoresizingMaskIntoConstraints = NO;
    addButton.backgroundColor = [UIColor colorWithRed:1.0 green:0xD6 / 255.0 blue:0x2A / 255.0 alpha:1.0];
    addButton.layer.cornerRadius = 24.0;
    addButton.layer.borderColor = UIColor.blackColor.CGColor;
    addButton.layer.borderWidth = 3.0;
    addButton.titleLabel.font = [UIFont fontWithName:@"Limelight" size:24.0] ?: [UIFont systemFontOfSize:24.0 weight:UIFontWeightBold];
    [addButton setTitle:@"Add" forState:UIControlStateNormal];
    [addButton setTitleColor:UIColor.blackColor forState:UIControlStateNormal];
    [addButton addTarget:self action:@selector(yk_addButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:addButton];
    self.yk_addButton = addButton;

    UIScrollView *scrollView = [[UIScrollView alloc] init];
    scrollView.translatesAutoresizingMaskIntoConstraints = NO;
    scrollView.showsVerticalScrollIndicator = NO;
    scrollView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
    scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    [self.view addSubview:scrollView];
    self.yk_scrollView = scrollView;

    UIView *contentView = [[UIView alloc] init];
    contentView.translatesAutoresizingMaskIntoConstraints = NO;
    [scrollView addSubview:contentView];

    UILabel *nameLabel = [self yk_titleLabelWithText:@"Name"];
    [contentView addSubview:nameLabel];

    UITextField *nameTextField = [[UITextField alloc] init];
    nameTextField.translatesAutoresizingMaskIntoConstraints = NO;
    nameTextField.backgroundColor = UIColor.whiteColor;
    nameTextField.layer.borderColor = UIColor.blackColor.CGColor;
    nameTextField.layer.borderWidth = 2.0;
    nameTextField.font = [UIFont systemFontOfSize:16.0];
    nameTextField.textColor = UIColor.blackColor;
    nameTextField.placeholder = @"Please enter";
    nameTextField.leftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 20.0, 1.0)];
    nameTextField.leftViewMode = UITextFieldViewModeAlways;
    nameTextField.returnKeyType = UIReturnKeyNext;
    nameTextField.delegate = self;
    [contentView addSubview:nameTextField];
    self.nameTextField = nameTextField;

    UILabel *priceLabel = [self yk_titleLabelWithText:@"Price"];
    [contentView addSubview:priceLabel];

    UITextField *priceTextField = [[UITextField alloc] init];
    priceTextField.translatesAutoresizingMaskIntoConstraints = NO;
    priceTextField.backgroundColor = UIColor.whiteColor;
    priceTextField.layer.borderColor = UIColor.blackColor.CGColor;
    priceTextField.layer.borderWidth = 2.0;
    priceTextField.font = [UIFont systemFontOfSize:18.0 weight:UIFontWeightBold];
    priceTextField.textColor = [UIColor colorWithRed:1.0 green:0x9B / 255.0 blue:0x3D / 255.0 alpha:1.0];
    priceTextField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"0.00"
                                                                           attributes:@{
        NSForegroundColorAttributeName: [UIColor colorWithRed:1.0 green:0x9B / 255.0 blue:0x3D / 255.0 alpha:0.45],
        NSFontAttributeName: [UIFont systemFontOfSize:18.0 weight:UIFontWeightBold]
    }];
    priceTextField.keyboardType = UIKeyboardTypeDecimalPad;
    priceTextField.delegate = self;

    UILabel *currencyLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 36.0, 60.0)];
    currencyLabel.text = @"$";
    currencyLabel.textAlignment = NSTextAlignmentCenter;
    currencyLabel.font = [UIFont systemFontOfSize:20.0 weight:UIFontWeightBold];
    currencyLabel.textColor = [UIColor colorWithRed:1.0 green:0x9B / 255.0 blue:0x3D / 255.0 alpha:1.0];
    priceTextField.leftView = currencyLabel;
    priceTextField.leftViewMode = UITextFieldViewModeAlways;
    [contentView addSubview:priceTextField];
    self.priceTextField = priceTextField;

    UILabel *descriptionLabel = [self yk_titleLabelWithText:@"Description"];
    [contentView addSubview:descriptionLabel];

    UITextView *descriptionTextView = [[UITextView alloc] init];
    descriptionTextView.translatesAutoresizingMaskIntoConstraints = NO;
    descriptionTextView.backgroundColor = UIColor.whiteColor;
    descriptionTextView.layer.borderColor = UIColor.blackColor.CGColor;
    descriptionTextView.layer.borderWidth = 2.0;
    descriptionTextView.textColor = UIColor.blackColor;
    descriptionTextView.font = [UIFont systemFontOfSize:16.0];
    descriptionTextView.textContainerInset = UIEdgeInsetsMake(16.0, 16.0, 34.0, 16.0);
    descriptionTextView.delegate = self;
    [contentView addSubview:descriptionTextView];
    self.descriptionTextView = descriptionTextView;

    UILabel *descriptionPlaceholderLabel = [[UILabel alloc] init];
    descriptionPlaceholderLabel.translatesAutoresizingMaskIntoConstraints = NO;
    descriptionPlaceholderLabel.text = @"Please enter";
    descriptionPlaceholderLabel.textColor = [UIColor colorWithWhite:0.42 alpha:1.0];
    descriptionPlaceholderLabel.font = [UIFont systemFontOfSize:16.0];
    [descriptionTextView addSubview:descriptionPlaceholderLabel];
    self.descriptionPlaceholderLabel = descriptionPlaceholderLabel;

    UILabel *countLabel = [[UILabel alloc] init];
    countLabel.translatesAutoresizingMaskIntoConstraints = NO;
    countLabel.text = @"0/50";
    countLabel.textColor = [UIColor colorWithWhite:0.42 alpha:1.0];
    countLabel.font = [UIFont systemFontOfSize:16.0];
    [descriptionTextView addSubview:countLabel];
    self.countLabel = countLabel;

    UILabel *uploadLabel = [self yk_titleLabelWithText:@"Upload (Pic)"];
    [contentView addSubview:uploadLabel];

    UIButton *uploadButton = [UIButton buttonWithType:UIButtonTypeCustom];
    uploadButton.translatesAutoresizingMaskIntoConstraints = NO;
    uploadButton.backgroundColor = UIColor.whiteColor;
    uploadButton.layer.borderColor = UIColor.blackColor.CGColor;
    uploadButton.layer.borderWidth = 1.5;
    uploadButton.imageView.contentMode = UIViewContentModeCenter;
    [uploadButton setImage:[[UIImage imageNamed:@"addshop"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] forState:UIControlStateNormal];
    [uploadButton addTarget:self action:@selector(yk_uploadButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [contentView addSubview:uploadButton];
    self.uploadButton = uploadButton;

    UILayoutGuide *safeGuide = self.view.safeAreaLayoutGuide;
    [NSLayoutConstraint activateConstraints:@[
        [addButton.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [addButton.bottomAnchor constraintEqualToAnchor:safeGuide.bottomAnchor constant:-18.0],
        [addButton.widthAnchor constraintEqualToConstant:220.0],
        [addButton.heightAnchor constraintEqualToConstant:56.0],

        [scrollView.topAnchor constraintEqualToAnchor:safeGuide.topAnchor constant:52.0],
        [scrollView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [scrollView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [scrollView.bottomAnchor constraintEqualToAnchor:addButton.topAnchor constant:-12.0],

        [contentView.topAnchor constraintEqualToAnchor:scrollView.contentLayoutGuide.topAnchor],
        [contentView.leadingAnchor constraintEqualToAnchor:scrollView.contentLayoutGuide.leadingAnchor],
        [contentView.trailingAnchor constraintEqualToAnchor:scrollView.contentLayoutGuide.trailingAnchor],
        [contentView.bottomAnchor constraintEqualToAnchor:scrollView.contentLayoutGuide.bottomAnchor],
        [contentView.widthAnchor constraintEqualToAnchor:scrollView.frameLayoutGuide.widthAnchor],

        [nameLabel.topAnchor constraintEqualToAnchor:contentView.topAnchor constant:20.0],
        [nameLabel.leadingAnchor constraintEqualToAnchor:contentView.leadingAnchor constant:24.0],

        [nameTextField.topAnchor constraintEqualToAnchor:nameLabel.bottomAnchor constant:8.0],
        [nameTextField.leadingAnchor constraintEqualToAnchor:contentView.leadingAnchor constant:24.0],
        [nameTextField.trailingAnchor constraintEqualToAnchor:contentView.trailingAnchor constant:-24.0],
        [nameTextField.heightAnchor constraintEqualToConstant:60.0],

        [priceLabel.topAnchor constraintEqualToAnchor:nameTextField.bottomAnchor constant:22.0],
        [priceLabel.leadingAnchor constraintEqualToAnchor:nameLabel.leadingAnchor],

        [priceTextField.topAnchor constraintEqualToAnchor:priceLabel.bottomAnchor constant:8.0],
        [priceTextField.leadingAnchor constraintEqualToAnchor:nameTextField.leadingAnchor],
        [priceTextField.trailingAnchor constraintEqualToAnchor:nameTextField.trailingAnchor],
        [priceTextField.heightAnchor constraintEqualToConstant:60.0],

        [descriptionLabel.topAnchor constraintEqualToAnchor:priceTextField.bottomAnchor constant:22.0],
        [descriptionLabel.leadingAnchor constraintEqualToAnchor:nameLabel.leadingAnchor],

        [descriptionTextView.topAnchor constraintEqualToAnchor:descriptionLabel.bottomAnchor constant:8.0],
        [descriptionTextView.leadingAnchor constraintEqualToAnchor:nameTextField.leadingAnchor],
        [descriptionTextView.trailingAnchor constraintEqualToAnchor:nameTextField.trailingAnchor],
        [descriptionTextView.heightAnchor constraintEqualToConstant:160.0],

        [descriptionPlaceholderLabel.topAnchor constraintEqualToAnchor:descriptionTextView.topAnchor constant:18.0],
        [descriptionPlaceholderLabel.leadingAnchor constraintEqualToAnchor:descriptionTextView.leadingAnchor constant:20.0],

        [countLabel.trailingAnchor constraintEqualToAnchor:descriptionTextView.trailingAnchor constant:-18.0],
        [countLabel.bottomAnchor constraintEqualToAnchor:descriptionTextView.bottomAnchor constant:-20.0],

        [uploadLabel.topAnchor constraintEqualToAnchor:descriptionTextView.bottomAnchor constant:22.0],
        [uploadLabel.leadingAnchor constraintEqualToAnchor:nameLabel.leadingAnchor],

        [uploadButton.topAnchor constraintEqualToAnchor:uploadLabel.bottomAnchor constant:8.0],
        [uploadButton.leadingAnchor constraintEqualToAnchor:contentView.leadingAnchor constant:24.0],
        [uploadButton.widthAnchor constraintEqualToConstant:148.0],
        [uploadButton.heightAnchor constraintEqualToConstant:160.0],
        [uploadButton.bottomAnchor constraintEqualToAnchor:contentView.bottomAnchor constant:-20.0]
    ]];

    [self.view bringSubviewToFront:backButton];
    [self.view bringSubviewToFront:addButton];
}

- (UILabel *)yk_titleLabelWithText:(NSString *)text {
    UILabel *label = [[UILabel alloc] init];
    label.translatesAutoresizingMaskIntoConstraints = NO;
    label.text = text;
    label.textColor = UIColor.whiteColor;
    label.font = [UIFont fontWithName:@"Limelight" size:22.0] ?: [UIFont systemFontOfSize:22.0 weight:UIFontWeightBold];
    return label;
}

- (void)yk_uploadButtonTapped:(UIButton *)sender {
    [self.view endEditing:YES];
    PHPickerConfiguration *configuration = [[PHPickerConfiguration alloc] init];
    configuration.selectionLimit = 1;
    configuration.filter = [PHPickerFilter imagesFilter];

    PHPickerViewController *picker = [[PHPickerViewController alloc] initWithConfiguration:configuration];
    picker.delegate = self;
    [self presentViewController:picker animated:YES completion:nil];
}

- (NSString *)yk_normalizedPriceText {
    NSString *raw = [self.priceTextField.text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet] ?: @"";
    if ([raw hasPrefix:@"$"]) {
        raw = [[raw substringFromIndex:1] stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    }
    return raw;
}

- (BOOL)yk_isValidPriceText:(NSString *)price {
    if (price.length == 0) {
        return NO;
    }
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"^\\d+(\\.\\d{0,2})?$" options:0 error:nil];
    NSRange range = [regex rangeOfFirstMatchInString:price options:0 range:NSMakeRange(0, price.length)];
    if (range.location == NSNotFound || range.length != price.length) {
        return NO;
    }
    return price.doubleValue > 0;
}

- (void)yk_addButtonTapped:(UIButton *)sender {
    [self.view endEditing:YES];

    NSString *name = [self.nameTextField.text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet] ?: @"";
    NSString *price = [self yk_normalizedPriceText];
    NSString *desc = [self.descriptionTextView.text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet] ?: @"";

    if (name.length == 0) {
        [YKCenterToast yk_showNotice:@"Please enter Name" inView:self.view];
        return;
    }
    if (![self yk_isValidPriceText:price]) {
        [YKCenterToast yk_showNotice:@"Please enter a valid Price" inView:self.view];
        return;
    }
    if (desc.length == 0) {
        [YKCenterToast yk_showNotice:@"Please enter Description" inView:self.view];
        return;
    }
    if (!self.selectedImage) {
        [YKCenterToast yk_showNotice:@"Please upload a Pic" inView:self.view];
        return;
    }

    NSString *priceDisplay = [NSString stringWithFormat:@"$%@", price];
    __weak typeof(self) weakSelf = self;
    [YKCenterToast yk_showLoadingInView:self.view performAfterDelay:0.55 work:^{
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) { return; }
        if (self.completion) {
            self.completion(@{
                @"name": name,
                @"price": priceDisplay,
                @"description": desc,
                @"image": self.selectedImage
            });
        }
        [self.navigationController popViewControllerAnimated:YES];
    }];
}

- (void)picker:(PHPickerViewController *)picker didFinishPicking:(NSArray<PHPickerResult *> *)results {
    [picker dismissViewControllerAnimated:YES completion:nil];
    PHPickerResult *result = results.firstObject;
    if (!result) {
        return;
    }

    NSItemProvider *provider = result.itemProvider;
    if (![provider canLoadObjectOfClass:UIImage.class]) {
        return;
    }

    [YKCenterToast yk_showLoadingInView:self.view];
    __weak typeof(self) weakSelf = self;
    [provider loadObjectOfClass:UIImage.class completionHandler:^(__kindof id<NSItemProviderReading> _Nullable object, NSError * _Nullable error) {
        UIImage *image = [object isKindOfClass:UIImage.class] ? (UIImage *)object : nil;
        dispatch_async(dispatch_get_main_queue(), ^{
            __strong typeof(weakSelf) self = weakSelf;
            if (!self) { return; }
            [YKCenterToast yk_hideLoadingInView:self.view];
            if (!image) {
                return;
            }
            [self yk_applySelectedImage:image];
        });
    }];
}

- (void)yk_applySelectedImage:(UIImage *)image {
    self.selectedImage = image;
    [self.uploadButton setImage:nil forState:UIControlStateNormal];
    [self.uploadButton setBackgroundImage:image forState:UIControlStateNormal];
    self.uploadButton.imageView.contentMode = UIViewContentModeScaleAspectFill;
    self.uploadButton.clipsToBounds = YES;
}

#pragma mark - UITextFieldDelegate

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    if (textField != self.priceTextField) {
        return YES;
    }
    if (string.length == 0) {
        return YES;
    }

    NSCharacterSet *allowed = [NSCharacterSet characterSetWithCharactersInString:@"0123456789."];
    if ([string rangeOfCharacterFromSet:allowed.invertedSet].location != NSNotFound) {
        return NO;
    }

    NSString *next = [textField.text stringByReplacingCharactersInRange:range withString:string] ?: @"";
    NSArray<NSString *> *parts = [next componentsSeparatedByString:@"."];
    if (parts.count > 2) {
        return NO;
    }
    if (parts.count == 2 && parts.lastObject.length > 2) {
        return NO;
    }
    if (next.length > 10) {
        return NO;
    }
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (textField == self.nameTextField) {
        [self.priceTextField becomeFirstResponder];
        return NO;
    }
    return YES;
}

#pragma mark - UITextViewDelegate

- (void)textViewDidChange:(UITextView *)textView {
    if (textView.text.length > 50) {
        textView.text = [textView.text substringToIndex:50];
    }
    self.descriptionPlaceholderLabel.hidden = textView.text.length > 0;
    self.countLabel.text = [NSString stringWithFormat:@"%lu/50", (unsigned long)textView.text.length];
}

@end
