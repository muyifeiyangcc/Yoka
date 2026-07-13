//
//  YKPublicGoodsViewController.m
//  Yoka
//

#import "YKPublicGoodsViewController.h"
#import <PhotosUI/PhotosUI.h>

@interface YKPublicGoodsViewController () <PHPickerViewControllerDelegate, UITextViewDelegate>

@property (nonatomic, strong) UITextField *nameTextField;
@property (nonatomic, strong) UITextView *descriptionTextView;
@property (nonatomic, strong) UILabel *descriptionPlaceholderLabel;
@property (nonatomic, strong) UILabel *countLabel;
@property (nonatomic, strong) UIButton *uploadButton;
@property (nonatomic, strong, nullable) UIImage *selectedImage;

@end

@implementation YKPublicGoodsViewController

- (void)yk_configurePage {
    [super yk_configurePage];
    [self yk_setupViews];
}

- (void)yk_setupViews {
    [self yk_addBackButton];

    UILabel *nameLabel = [self yk_titleLabelWithText:@"Name"];
    [self.view addSubview:nameLabel];

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
    [self.view addSubview:nameTextField];
    self.nameTextField = nameTextField;

    UILabel *descriptionLabel = [self yk_titleLabelWithText:@"Description"];
    [self.view addSubview:descriptionLabel];

    UITextView *descriptionTextView = [[UITextView alloc] init];
    descriptionTextView.translatesAutoresizingMaskIntoConstraints = NO;
    descriptionTextView.backgroundColor = UIColor.whiteColor;
    descriptionTextView.layer.borderColor = UIColor.blackColor.CGColor;
    descriptionTextView.layer.borderWidth = 2.0;
    descriptionTextView.textColor = UIColor.blackColor;
    descriptionTextView.font = [UIFont systemFontOfSize:16.0];
    descriptionTextView.textContainerInset = UIEdgeInsetsMake(16.0, 16.0, 34.0, 16.0);
    descriptionTextView.delegate = self;
    [self.view addSubview:descriptionTextView];
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
    [self.view addSubview:uploadLabel];

    UIButton *uploadButton = [UIButton buttonWithType:UIButtonTypeCustom];
    uploadButton.translatesAutoresizingMaskIntoConstraints = NO;
    uploadButton.backgroundColor = UIColor.whiteColor;
    uploadButton.layer.borderColor = UIColor.blackColor.CGColor;
    uploadButton.layer.borderWidth = 1.5;
    uploadButton.imageView.contentMode = UIViewContentModeCenter;
    [uploadButton setImage:[[UIImage imageNamed:@"addshop"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] forState:UIControlStateNormal];
    [uploadButton addTarget:self action:@selector(yk_uploadButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:uploadButton];
    self.uploadButton = uploadButton;

    UIButton *releaseButton = [UIButton buttonWithType:UIButtonTypeCustom];
    releaseButton.translatesAutoresizingMaskIntoConstraints = NO;
    releaseButton.adjustsImageWhenHighlighted = NO;
    [releaseButton setImage:[[UIImage imageNamed:@"releasepub"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] forState:UIControlStateNormal];
    [releaseButton addTarget:self action:@selector(yk_releaseButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:releaseButton];

    UILayoutGuide *safeGuide = self.view.safeAreaLayoutGuide;
    [NSLayoutConstraint activateConstraints:@[
        [nameLabel.topAnchor constraintEqualToAnchor:safeGuide.topAnchor constant:92.0],
        [nameLabel.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:24.0],

        [nameTextField.topAnchor constraintEqualToAnchor:nameLabel.bottomAnchor constant:8.0],
        [nameTextField.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:24.0],
        [nameTextField.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-24.0],
        [nameTextField.heightAnchor constraintEqualToConstant:60.0],

        [descriptionLabel.topAnchor constraintEqualToAnchor:nameTextField.bottomAnchor constant:22.0],
        [descriptionLabel.leadingAnchor constraintEqualToAnchor:nameLabel.leadingAnchor],

        [descriptionTextView.topAnchor constraintEqualToAnchor:descriptionLabel.bottomAnchor constant:8.0],
        [descriptionTextView.leadingAnchor constraintEqualToAnchor:nameTextField.leadingAnchor],
        [descriptionTextView.trailingAnchor constraintEqualToAnchor:nameTextField.trailingAnchor],
        [descriptionTextView.heightAnchor constraintEqualToConstant:186.0],

        [descriptionPlaceholderLabel.topAnchor constraintEqualToAnchor:descriptionTextView.topAnchor constant:18.0],
        [descriptionPlaceholderLabel.leadingAnchor constraintEqualToAnchor:descriptionTextView.leadingAnchor constant:20.0],

        [countLabel.trailingAnchor constraintEqualToAnchor:descriptionTextView.trailingAnchor constant:-18.0],
        [countLabel.bottomAnchor constraintEqualToAnchor:descriptionTextView.bottomAnchor constant:-20.0],

        [uploadLabel.topAnchor constraintEqualToAnchor:descriptionTextView.bottomAnchor constant:22.0],
        [uploadLabel.leadingAnchor constraintEqualToAnchor:nameLabel.leadingAnchor],

        [uploadButton.topAnchor constraintEqualToAnchor:uploadLabel.bottomAnchor constant:8.0],
        [uploadButton.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:24.0],
        [uploadButton.widthAnchor constraintEqualToConstant:148.0],
        [uploadButton.heightAnchor constraintEqualToConstant:180.0],

        [releaseButton.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [releaseButton.bottomAnchor constraintEqualToAnchor:safeGuide.bottomAnchor constant:-26.0],
        [releaseButton.widthAnchor constraintEqualToConstant:238.0],
        [releaseButton.heightAnchor constraintEqualToConstant:58.0]
    ]];
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
    PHPickerConfiguration *configuration = [[PHPickerConfiguration alloc] init];
    configuration.selectionLimit = 1;
    configuration.filter = [PHPickerFilter imagesFilter];

    PHPickerViewController *picker = [[PHPickerViewController alloc] initWithConfiguration:configuration];
    picker.delegate = self;
    [self presentViewController:picker animated:YES completion:nil];
}

- (void)yk_releaseButtonTapped:(UIButton *)sender {
    if (!self.selectedImage) {
        return;
    }

    if (self.completion) {
        self.completion(self.selectedImage);
    }
    [self.navigationController popViewControllerAnimated:YES];
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

    __weak typeof(self) weakSelf = self;
    [provider loadObjectOfClass:UIImage.class completionHandler:^(__kindof id<NSItemProviderReading> _Nullable object, NSError * _Nullable error) {
        UIImage *image = [object isKindOfClass:UIImage.class] ? (UIImage *)object : nil;
        if (!image) {
            return;
        }

        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf yk_applySelectedImage:image];
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

- (void)textViewDidChange:(UITextView *)textView {
    if (textView.text.length > 50) {
        textView.text = [textView.text substringToIndex:50];
    }
    self.descriptionPlaceholderLabel.hidden = textView.text.length > 0;
    self.countLabel.text = [NSString stringWithFormat:@"%lu/50", (unsigned long)textView.text.length];
}

@end
