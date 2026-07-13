//
//  YKPublicPostViewController.m
//  Yoka
//

#import "YKPublicPostViewController.h"
#import "YKPublicGoodsViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <PhotosUI/PhotosUI.h>
#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>

@interface YKPublicPostViewController () <PHPickerViewControllerDelegate, UITextViewDelegate>

@property (nonatomic, strong) UITextView *textView;
@property (nonatomic, strong) UILabel *placeholderLabel;
@property (nonatomic, strong) UIStackView *sourcesStackView;
@property (nonatomic, strong) NSMutableArray<UIImage *> *goodsImages;
@property (nonatomic, strong, nullable) UIImage *sourceThumbnail;
@property (nonatomic, assign) BOOL sourceIsVideo;

@end

@implementation YKPublicPostViewController

- (void)yk_configurePage {
    [super yk_configurePage];
    self.goodsImages = [NSMutableArray array];
    [self yk_setupViews];
    [self yk_reloadSourceItems];
}

- (void)yk_setupViews {
    [self yk_addBackButton];

    UIButton *postButton = [UIButton buttonWithType:UIButtonTypeCustom];
    postButton.translatesAutoresizingMaskIntoConstraints = NO;
    postButton.layer.cornerRadius = 18.0;
    postButton.layer.borderColor = UIColor.whiteColor.CGColor;
    postButton.layer.borderWidth = 2.0;
    postButton.titleLabel.font = [UIFont systemFontOfSize:16.0 weight:UIFontWeightSemibold];
    [postButton setTitle:@"Post" forState:UIControlStateNormal];
    [postButton setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    [self.view addSubview:postButton];

    UITextView *textView = [[UITextView alloc] init];
    textView.translatesAutoresizingMaskIntoConstraints = NO;
    textView.backgroundColor = UIColor.whiteColor;
    textView.layer.borderColor = UIColor.blackColor.CGColor;
    textView.layer.borderWidth = 3.0;
    textView.textColor = UIColor.blackColor;
    textView.font = [UIFont systemFontOfSize:17.0];
    textView.textContainerInset = UIEdgeInsetsMake(20.0, 18.0, 20.0, 18.0);
    textView.delegate = self;
    [self.view addSubview:textView];
    self.textView = textView;

    UILabel *placeholderLabel = [[UILabel alloc] init];
    placeholderLabel.translatesAutoresizingMaskIntoConstraints = NO;
    placeholderLabel.text = @"Say something";
    placeholderLabel.textColor = [UIColor colorWithWhite:0.42 alpha:1.0];
    placeholderLabel.font = [UIFont systemFontOfSize:17.0];
    [textView addSubview:placeholderLabel];
    self.placeholderLabel = placeholderLabel;

    UIScrollView *itemsScrollView = [[UIScrollView alloc] init];
    itemsScrollView.translatesAutoresizingMaskIntoConstraints = NO;
    itemsScrollView.showsHorizontalScrollIndicator = NO;
    [self.view addSubview:itemsScrollView];

    UIStackView *sourcesStackView = [[UIStackView alloc] init];
    sourcesStackView.translatesAutoresizingMaskIntoConstraints = NO;
    sourcesStackView.axis = UILayoutConstraintAxisHorizontal;
    sourcesStackView.alignment = UIStackViewAlignmentCenter;
    sourcesStackView.spacing = 14.0;
    [itemsScrollView addSubview:sourcesStackView];
    self.sourcesStackView = sourcesStackView;

    UILayoutGuide *safeGuide = self.view.safeAreaLayoutGuide;
    [NSLayoutConstraint activateConstraints:@[
        [postButton.topAnchor constraintEqualToAnchor:safeGuide.topAnchor constant:22.0],
        [postButton.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-24.0],
        [postButton.widthAnchor constraintEqualToConstant:78.0],
        [postButton.heightAnchor constraintEqualToConstant:38.0],

        [textView.topAnchor constraintEqualToAnchor:safeGuide.topAnchor constant:78.0],
        [textView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:24.0],
        [textView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-24.0],
        [textView.heightAnchor constraintEqualToConstant:410.0],

        [placeholderLabel.topAnchor constraintEqualToAnchor:textView.topAnchor constant:22.0],
        [placeholderLabel.leadingAnchor constraintEqualToAnchor:textView.leadingAnchor constant:20.0],

        [itemsScrollView.topAnchor constraintEqualToAnchor:textView.bottomAnchor constant:22.0],
        [itemsScrollView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:24.0],
        [itemsScrollView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [itemsScrollView.heightAnchor constraintEqualToConstant:126.0],

        [sourcesStackView.topAnchor constraintEqualToAnchor:itemsScrollView.contentLayoutGuide.topAnchor],
        [sourcesStackView.leadingAnchor constraintEqualToAnchor:itemsScrollView.contentLayoutGuide.leadingAnchor],
        [sourcesStackView.trailingAnchor constraintEqualToAnchor:itemsScrollView.contentLayoutGuide.trailingAnchor constant:-24.0],
        [sourcesStackView.bottomAnchor constraintEqualToAnchor:itemsScrollView.contentLayoutGuide.bottomAnchor],
        [sourcesStackView.heightAnchor constraintEqualToAnchor:itemsScrollView.frameLayoutGuide.heightAnchor]
    ]];
}

- (void)yk_reloadSourceItems {
    for (UIView *view in self.sourcesStackView.arrangedSubviews) {
        [self.sourcesStackView removeArrangedSubview:view];
        [view removeFromSuperview];
    }

    UIButton *addButton = [self yk_thumbnailButtonWithImage:nil];
    [addButton setImage:[[UIImage imageNamed:@"addsources"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] forState:UIControlStateNormal];
    [addButton addTarget:self action:@selector(yk_addButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.sourcesStackView addArrangedSubview:addButton];

    if (self.sourceThumbnail) {
        UIView *sourceView = [self yk_imageTileWithImage:self.sourceThumbnail showPlay:self.sourceIsVideo deleteSelector:@selector(yk_deleteSourceTapped:)];
        [self.sourcesStackView addArrangedSubview:sourceView];
    }

    for (UIImage *image in self.goodsImages) {
        [self.sourcesStackView addArrangedSubview:[self yk_imageTileWithImage:image showPlay:NO deleteSelector:nil]];
    }
}

- (UIButton *)yk_thumbnailButtonWithImage:(nullable UIImage *)image {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.translatesAutoresizingMaskIntoConstraints = NO;
    button.backgroundColor = UIColor.blackColor;
    button.adjustsImageWhenHighlighted = NO;
    button.imageView.contentMode = UIViewContentModeCenter;
    if (image) {
        [button setBackgroundImage:image forState:UIControlStateNormal];
    }
    [NSLayoutConstraint activateConstraints:@[
        [button.widthAnchor constraintEqualToConstant:94.0],
        [button.heightAnchor constraintEqualToConstant:126.0]
    ]];
    return button;
}

- (UIView *)yk_imageTileWithImage:(UIImage *)image showPlay:(BOOL)showPlay deleteSelector:(nullable SEL)deleteSelector {
    UIView *container = [[UIView alloc] init];
    container.translatesAutoresizingMaskIntoConstraints = NO;
    container.clipsToBounds = NO;

    UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
    imageView.translatesAutoresizingMaskIntoConstraints = NO;
    imageView.contentMode = UIViewContentModeScaleAspectFill;
    imageView.clipsToBounds = YES;
    [container addSubview:imageView];

    if (showPlay) {
        UILabel *playLabel = [[UILabel alloc] init];
        playLabel.translatesAutoresizingMaskIntoConstraints = NO;
        playLabel.text = @"▶";
        playLabel.textColor = UIColor.whiteColor;
        playLabel.textAlignment = NSTextAlignmentCenter;
        playLabel.font = [UIFont systemFontOfSize:26.0 weight:UIFontWeightBold];
        playLabel.backgroundColor = [UIColor colorWithWhite:0 alpha:0.28];
        playLabel.layer.cornerRadius = 20.0;
        playLabel.layer.masksToBounds = YES;
        [container addSubview:playLabel];
        [NSLayoutConstraint activateConstraints:@[
            [playLabel.centerXAnchor constraintEqualToAnchor:imageView.centerXAnchor],
            [playLabel.centerYAnchor constraintEqualToAnchor:imageView.centerYAnchor],
            [playLabel.widthAnchor constraintEqualToConstant:40.0],
            [playLabel.heightAnchor constraintEqualToConstant:40.0]
        ]];
    }

    if (deleteSelector) {
        UIButton *deleteButton = [UIButton buttonWithType:UIButtonTypeCustom];
        deleteButton.translatesAutoresizingMaskIntoConstraints = NO;
        deleteButton.backgroundColor = [UIColor colorWithWhite:0 alpha:0.65];
        deleteButton.layer.cornerRadius = 11.0;
        deleteButton.titleLabel.font = [UIFont systemFontOfSize:16.0 weight:UIFontWeightBold];
        [deleteButton setTitle:@"×" forState:UIControlStateNormal];
        [deleteButton setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
        [deleteButton addTarget:self action:deleteSelector forControlEvents:UIControlEventTouchUpInside];
        [container addSubview:deleteButton];
        [NSLayoutConstraint activateConstraints:@[
            [deleteButton.topAnchor constraintEqualToAnchor:container.topAnchor constant:-7.0],
            [deleteButton.trailingAnchor constraintEqualToAnchor:container.trailingAnchor constant:7.0],
            [deleteButton.widthAnchor constraintEqualToConstant:22.0],
            [deleteButton.heightAnchor constraintEqualToConstant:22.0]
        ]];
    }

    [NSLayoutConstraint activateConstraints:@[
        [container.widthAnchor constraintEqualToConstant:94.0],
        [container.heightAnchor constraintEqualToConstant:126.0],
        [imageView.topAnchor constraintEqualToAnchor:container.topAnchor],
        [imageView.leadingAnchor constraintEqualToAnchor:container.leadingAnchor],
        [imageView.trailingAnchor constraintEqualToAnchor:container.trailingAnchor],
        [imageView.bottomAnchor constraintEqualToAnchor:container.bottomAnchor]
    ]];
    return container;
}

- (void)yk_addButtonTapped:(UIButton *)sender {
    if (self.sourceThumbnail) {
        [self yk_pushGoodsPage];
    } else {
        [self yk_presentSourcePicker];
    }
}

- (void)yk_deleteSourceTapped:(UIButton *)sender {
    self.sourceThumbnail = nil;
    self.sourceIsVideo = NO;
    [self.goodsImages removeAllObjects];
    [self yk_reloadSourceItems];
}

- (void)yk_pushGoodsPage {
    YKPublicGoodsViewController *goodsViewController = [[YKPublicGoodsViewController alloc] init];
    __weak typeof(self) weakSelf = self;
    goodsViewController.completion = ^(UIImage *image) {
        [weakSelf.goodsImages addObject:image];
        [weakSelf yk_reloadSourceItems];
    };
    [self.navigationController pushViewController:goodsViewController animated:YES];
}

- (void)yk_presentSourcePicker {
    PHPickerConfiguration *configuration = [[PHPickerConfiguration alloc] init];
    configuration.selectionLimit = 1;
    configuration.filter = [PHPickerFilter anyFilterMatchingSubfilters:@[
        [PHPickerFilter imagesFilter],
        [PHPickerFilter videosFilter]
    ]];

    PHPickerViewController *picker = [[PHPickerViewController alloc] initWithConfiguration:configuration];
    picker.delegate = self;
    [self presentViewController:picker animated:YES completion:nil];
}

- (void)picker:(PHPickerViewController *)picker didFinishPicking:(NSArray<PHPickerResult *> *)results {
    [picker dismissViewControllerAnimated:YES completion:nil];
    PHPickerResult *result = results.firstObject;
    if (!result) {
        return;
    }

    NSItemProvider *provider = result.itemProvider;
    __weak typeof(self) weakSelf = self;
    if ([provider canLoadObjectOfClass:UIImage.class]) {
        [provider loadObjectOfClass:UIImage.class completionHandler:^(__kindof id<NSItemProviderReading> _Nullable object, NSError * _Nullable error) {
            UIImage *image = [object isKindOfClass:UIImage.class] ? (UIImage *)object : nil;
            if (!image) {
                return;
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf yk_applySourceThumbnail:image isVideo:NO];
            });
        }];
        return;
    }

    NSString *movieIdentifier = UTTypeMovie.identifier;
    if (![provider hasItemConformingToTypeIdentifier:movieIdentifier]) {
        return;
    }

    [provider loadFileRepresentationForTypeIdentifier:movieIdentifier completionHandler:^(NSURL * _Nullable url, NSError * _Nullable error) {
        if (!url) {
            return;
        }
        UIImage *thumbnail = [weakSelf yk_videoThumbnailWithURL:url];
        if (!thumbnail) {
            return;
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf yk_applySourceThumbnail:thumbnail isVideo:YES];
        });
    }];
}

- (UIImage *)yk_videoThumbnailWithURL:(NSURL *)url {
    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:url options:nil];
    AVAssetImageGenerator *generator = [[AVAssetImageGenerator alloc] initWithAsset:asset];
    generator.appliesPreferredTrackTransform = YES;
    generator.maximumSize = CGSizeMake(600.0, 600.0);

    NSError *error = nil;
    CGImageRef imageRef = [generator copyCGImageAtTime:kCMTimeZero actualTime:NULL error:&error];
    if (!imageRef) {
        return nil;
    }
    UIImage *image = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    return image;
}

- (void)yk_applySourceThumbnail:(UIImage *)thumbnail isVideo:(BOOL)isVideo {
    self.sourceThumbnail = thumbnail;
    self.sourceIsVideo = isVideo;
    [self.goodsImages removeAllObjects];
    [self yk_reloadSourceItems];
}

- (void)textViewDidChange:(UITextView *)textView {
    self.placeholderLabel.hidden = textView.text.length > 0;
}

@end
