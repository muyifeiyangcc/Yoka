//
//  YKPublicPublishViewController.m
//  Yoka
//

#import "YKPublicPublishViewController.h"
#import "YKPublicGoodsViewController.h"
#import "../../../BaseClass/YKCenterToast.h"
#import "../../FindClass/YKPublishLedger.h"
#import "../../LoginandReClass/YKAccountVault.h"
#import "../../LoginandReClass/YKPersonaCatalog.h"

#import <AVFoundation/AVFoundation.h>
#import <PhotosUI/PhotosUI.h>
#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>
#import "../../../BaseClass/YKSigilForge.h"

@interface YKPublicPublishViewController () <PHPickerViewControllerDelegate, UITextViewDelegate>

@property (nonatomic, strong) UITextView *yk_dynamicTextView;
@property (nonatomic, strong) UILabel *yk_dynamicPlaceholderLabel;

@property (nonatomic, strong) UIScrollView *yk_sourcesScrollView;
@property (nonatomic, strong) UIStackView *yk_sourcesStackView;

@property (nonatomic, strong, nullable) UIImage *yk_sourceThumbnail;
@property (nonatomic, assign) BOOL yk_sourceIsVideo;
@property (nonatomic, copy, nullable) NSString *yk_pendingVideoFile;

@property (nonatomic, strong) NSMutableArray<NSDictionary<NSString *, id> *> *yk_goodItems;

@property (nonatomic, strong) UIButton *yk_dispatchEntryButton;
@property (nonatomic, strong) UIView *yk_goodsSectionView;
@property (nonatomic, strong) UIStackView *yk_goodsStackView;

@property (nonatomic, strong) UIButton *yk_addGoodButton;

@end

@implementation YKPublicPublishViewController

- (void)yk_configurePage {
    [super yk_configurePage];
    self.yk_sourceThumbnail = nil;
    self.yk_sourceIsVideo = NO;
    self.yk_pendingVideoFile = nil;
    self.yk_goodItems = [NSMutableArray array];
    [self yk_setupViews];
    [self yk_reloadSourceItems];
    [self yk_updateAddItemButtonEnabled];
}

- (void)yk_setupViews {
    UIButton *backButton = [self yk_addBackButton];

    UIScrollView *scrollView = [[UIScrollView alloc] init];
    scrollView.translatesAutoresizingMaskIntoConstraints = NO;
    scrollView.showsVerticalScrollIndicator = NO;
    scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    [self.view addSubview:scrollView];

    UIView *contentView = [[UIView alloc] init];
    contentView.translatesAutoresizingMaskIntoConstraints = NO;
    [scrollView addSubview:contentView];

    self.yk_sourcesScrollView = [[UIScrollView alloc] init];
    self.yk_sourcesScrollView.translatesAutoresizingMaskIntoConstraints = NO;
    self.yk_sourcesScrollView.showsHorizontalScrollIndicator = NO;
    self.yk_sourcesScrollView.clipsToBounds = NO;

    UIStackView *sourcesStackView = [[UIStackView alloc] init];
    sourcesStackView.translatesAutoresizingMaskIntoConstraints = NO;
    sourcesStackView.axis = UILayoutConstraintAxisHorizontal;
    sourcesStackView.alignment = UIStackViewAlignmentCenter;
    sourcesStackView.spacing = 14.0;
    sourcesStackView.clipsToBounds = NO;
    [self.yk_sourcesScrollView addSubview:sourcesStackView];
    self.yk_sourcesStackView = sourcesStackView;

    UITextView *textView = [[UITextView alloc] init];
    textView.translatesAutoresizingMaskIntoConstraints = NO;
    textView.backgroundColor = UIColor.whiteColor;
    textView.layer.borderColor = UIColor.blackColor.CGColor;
    textView.layer.borderWidth = 3.0;
    textView.textColor = UIColor.blackColor;
    textView.font = [UIFont systemFontOfSize:17.0];
    textView.textContainerInset = UIEdgeInsetsMake(20.0, 18.0, 20.0, 18.0);
    textView.delegate = self;
    [contentView addSubview:textView];
    self.yk_dynamicTextView = textView;

    UILabel *placeholderLabel = [[UILabel alloc] init];
    placeholderLabel.translatesAutoresizingMaskIntoConstraints = NO;
    placeholderLabel.text = @"Say something";
    placeholderLabel.textColor = [UIColor colorWithWhite:0.42 alpha:1.0];
    placeholderLabel.font = [UIFont systemFontOfSize:17.0];
    [textView addSubview:placeholderLabel];
    self.yk_dynamicPlaceholderLabel = placeholderLabel;

    [contentView addSubview:self.yk_sourcesScrollView];

    // Post stays in the nav bar (top-right).
    UIButton *postButton = [UIButton buttonWithType:UIButtonTypeCustom];
    postButton.translatesAutoresizingMaskIntoConstraints = NO;
    postButton.backgroundColor = [UIColor colorWithRed:0xDE / 255.0 green:0x74 / 255.0 blue:0xFF / 255.0 alpha:0.92];
    postButton.layer.cornerRadius = 16.0;
    postButton.layer.borderColor = UIColor.whiteColor.CGColor;
    postButton.layer.borderWidth = 2.0;
    postButton.titleLabel.font = [UIFont systemFontOfSize:16.0 weight:UIFontWeightBold];
    [postButton setTitle:[YKSigilForge yk_unveil:@"nUDz1MN7enUF4l9g/i/fmg=="] forState:UIControlStateNormal];
    [postButton setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    [postButton addTarget:self action:@selector(yk_dispatchEntryTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:postButton];
    self.yk_dispatchEntryButton = postButton;

    // Goods section (initially empty -> collapses)
    UIView *goodsSection = [[UIView alloc] init];
    goodsSection.translatesAutoresizingMaskIntoConstraints = NO;
    [contentView addSubview:goodsSection];
    self.yk_goodsSectionView = goodsSection;

    UIStackView *goodsStack = [[UIStackView alloc] init];
    goodsStack.translatesAutoresizingMaskIntoConstraints = NO;
    goodsStack.axis = UILayoutConstraintAxisVertical;
    goodsStack.alignment = UIStackViewAlignmentFill;
    goodsStack.distribution = UIStackViewDistributionFill;
    goodsStack.spacing = 16.0;
    [goodsSection addSubview:goodsStack];
    self.yk_goodsStackView = goodsStack;

    UIButton *addGoodButton = [UIButton buttonWithType:UIButtonTypeCustom];
    addGoodButton.translatesAutoresizingMaskIntoConstraints = NO;
    addGoodButton.backgroundColor = [UIColor colorWithRed:0xDE / 255.0 green:0x74 / 255.0 blue:0xFF / 255.0 alpha:0.92];
    addGoodButton.layer.cornerRadius = 21.0;
    addGoodButton.layer.borderColor = UIColor.whiteColor.CGColor;
    addGoodButton.layer.borderWidth = 2.0;
    addGoodButton.titleLabel.font = [UIFont systemFontOfSize:18.0 weight:UIFontWeightBold];
    [addGoodButton setTitle:@"Add item list" forState:UIControlStateNormal];
    [addGoodButton setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    [addGoodButton addTarget:self action:@selector(yk_addGoodTapped:) forControlEvents:UIControlEventTouchUpInside];
    [contentView addSubview:addGoodButton];
    self.yk_addGoodButton = addGoodButton;

    [NSLayoutConstraint activateConstraints:@[
        [postButton.centerYAnchor constraintEqualToAnchor:backButton.centerYAnchor],
        [postButton.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-20.0],
        [postButton.widthAnchor constraintEqualToConstant:80.0],
        [postButton.heightAnchor constraintEqualToConstant:34.0],

        [scrollView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:44.0],
        [scrollView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [scrollView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [scrollView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],

        [contentView.topAnchor constraintEqualToAnchor:scrollView.contentLayoutGuide.topAnchor],
        [contentView.leadingAnchor constraintEqualToAnchor:scrollView.contentLayoutGuide.leadingAnchor],
        [contentView.trailingAnchor constraintEqualToAnchor:scrollView.contentLayoutGuide.trailingAnchor],
        [contentView.bottomAnchor constraintEqualToAnchor:scrollView.contentLayoutGuide.bottomAnchor],
        [contentView.widthAnchor constraintEqualToAnchor:scrollView.frameLayoutGuide.widthAnchor],

        [textView.topAnchor constraintEqualToAnchor:contentView.topAnchor constant:20.0],
        [textView.leadingAnchor constraintEqualToAnchor:contentView.leadingAnchor constant:24.0],
        [textView.trailingAnchor constraintEqualToAnchor:contentView.trailingAnchor constant:-24.0],
        [textView.heightAnchor constraintEqualToConstant:180.0],

        [placeholderLabel.topAnchor constraintEqualToAnchor:textView.topAnchor constant:22.0],
        [placeholderLabel.leadingAnchor constraintEqualToAnchor:textView.leadingAnchor constant:20.0],

        [self.yk_sourcesScrollView.topAnchor constraintEqualToAnchor:textView.bottomAnchor constant:22.0],
        [self.yk_sourcesScrollView.leadingAnchor constraintEqualToAnchor:contentView.leadingAnchor constant:24.0],
        [self.yk_sourcesScrollView.trailingAnchor constraintEqualToAnchor:contentView.trailingAnchor constant:-24.0],
        [self.yk_sourcesScrollView.heightAnchor constraintEqualToConstant:140.0],

        [sourcesStackView.topAnchor constraintEqualToAnchor:self.yk_sourcesScrollView.contentLayoutGuide.topAnchor constant:4.0],
        [sourcesStackView.leadingAnchor constraintEqualToAnchor:self.yk_sourcesScrollView.contentLayoutGuide.leadingAnchor],
        [sourcesStackView.trailingAnchor constraintEqualToAnchor:self.yk_sourcesScrollView.contentLayoutGuide.trailingAnchor constant:-24.0],
        [sourcesStackView.bottomAnchor constraintEqualToAnchor:self.yk_sourcesScrollView.contentLayoutGuide.bottomAnchor constant:-4.0],
        [sourcesStackView.heightAnchor constraintEqualToConstant:136.0],

        [addGoodButton.topAnchor constraintEqualToAnchor:self.yk_sourcesScrollView.bottomAnchor constant:22.0],
        [addGoodButton.centerXAnchor constraintEqualToAnchor:contentView.centerXAnchor],
        [addGoodButton.widthAnchor constraintEqualToConstant:220.0],
        [addGoodButton.heightAnchor constraintEqualToConstant:46.0],

        [goodsSection.topAnchor constraintEqualToAnchor:addGoodButton.bottomAnchor constant:18.0],
        [goodsSection.leadingAnchor constraintEqualToAnchor:contentView.leadingAnchor constant:24.0],
        [goodsSection.trailingAnchor constraintEqualToAnchor:contentView.trailingAnchor constant:-24.0],

        [goodsStack.topAnchor constraintEqualToAnchor:goodsSection.topAnchor],
        [goodsStack.leadingAnchor constraintEqualToAnchor:goodsSection.leadingAnchor],
        [goodsStack.trailingAnchor constraintEqualToAnchor:goodsSection.trailingAnchor],
        [goodsStack.bottomAnchor constraintEqualToAnchor:goodsSection.bottomAnchor],
        [goodsSection.bottomAnchor constraintEqualToAnchor:contentView.bottomAnchor constant:-26.0]
    ]];

    [self.view bringSubviewToFront:backButton];
    [self.view bringSubviewToFront:postButton];
}

#pragma mark - Source tiles

- (void)yk_reloadSourceItems {
    for (UIView *view in self.yk_sourcesStackView.arrangedSubviews) {
        [self.yk_sourcesStackView removeArrangedSubview:view];
        [view removeFromSuperview];
    }

    if (self.yk_sourceThumbnail) {
        UIView *sourceView = [self yk_imageTileWithImage:self.yk_sourceThumbnail
                                                 showPlay:self.yk_sourceIsVideo
                                        deleteSelector:@selector(yk_deleteSourceTapped:)];
        [self.yk_sourcesStackView addArrangedSubview:sourceView];
    } else {
        UIButton *addSourceButton = [UIButton buttonWithType:UIButtonTypeCustom];
        addSourceButton.translatesAutoresizingMaskIntoConstraints = NO;
        addSourceButton.backgroundColor = UIColor.blackColor;
        addSourceButton.adjustsImageWhenHighlighted = NO;
        addSourceButton.imageView.contentMode = UIViewContentModeCenter;
        [addSourceButton setImage:[[UIImage imageNamed:@"addsources"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]
                         forState:UIControlStateNormal];
        [addSourceButton addTarget:self action:@selector(yk_addSourceTapped:) forControlEvents:UIControlEventTouchUpInside];

        [NSLayoutConstraint activateConstraints:@[
            [addSourceButton.widthAnchor constraintEqualToConstant:94.0],
            [addSourceButton.heightAnchor constraintEqualToConstant:126.0]
        ]];
        [self.yk_sourcesStackView addArrangedSubview:addSourceButton];
    }

    [self.view layoutIfNeeded];
    [self yk_updateSourceScrollBehavior];
}

- (void)yk_updateSourceScrollBehavior {
    [self.yk_sourcesStackView layoutIfNeeded];
    CGSize stackSize = [self.yk_sourcesStackView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize];
    CGFloat visibleWidth = CGRectGetWidth(self.yk_sourcesScrollView.bounds);
    BOOL needsHorizontalScroll = visibleWidth > 1.0 && stackSize.width > visibleWidth;
    self.yk_sourcesScrollView.scrollEnabled = needsHorizontalScroll;
    self.yk_sourcesScrollView.alwaysBounceHorizontal = needsHorizontalScroll;
    self.yk_sourcesScrollView.showsHorizontalScrollIndicator = needsHorizontalScroll;
}

- (void)yk_addSourceTapped:(UIButton *)sender {
    [self yk_presentSourcePicker];
}

- (UIView *)yk_imageTileWithImage:(UIImage *)image showPlay:(BOOL)showPlay deleteSelector:(SEL)deleteSelector {
    UIView *container = [[UIView alloc] init];
    container.translatesAutoresizingMaskIntoConstraints = NO;
    container.clipsToBounds = NO;

    CGFloat deleteGutter = deleteSelector ? 10.0 : 0.0;

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
            [deleteButton.topAnchor constraintEqualToAnchor:container.topAnchor],
            [deleteButton.trailingAnchor constraintEqualToAnchor:container.trailingAnchor],
            [deleteButton.widthAnchor constraintEqualToConstant:22.0],
            [deleteButton.heightAnchor constraintEqualToConstant:22.0]
        ]];
    }

    [NSLayoutConstraint activateConstraints:@[
        [container.widthAnchor constraintEqualToConstant:94.0 + deleteGutter],
        [container.heightAnchor constraintEqualToConstant:126.0 + deleteGutter],
        [imageView.topAnchor constraintEqualToAnchor:container.topAnchor constant:deleteGutter],
        [imageView.leadingAnchor constraintEqualToAnchor:container.leadingAnchor],
        [imageView.trailingAnchor constraintEqualToAnchor:container.trailingAnchor constant:-deleteGutter],
        [imageView.bottomAnchor constraintEqualToAnchor:container.bottomAnchor]
    ]];
    return container;
}

- (void)yk_deleteSourceTapped:(UIButton *)sender {
    [self yk_discardPendingVideoFile];
    self.yk_sourceThumbnail = nil;
    self.yk_sourceIsVideo = NO;

    // Reset goods list because it belongs to the chosen dynamic.
    [self yk_clearGoodsItems];

    [self yk_reloadSourceItems];
    [self yk_reloadGoodsSection];
    [self yk_updateAddItemButtonEnabled];
}

- (void)yk_discardPendingVideoFile {
    if (self.yk_pendingVideoFile.length == 0) {
        return;
    }
    [[YKPublishLedger sharedLedger] yk_deleteRelativeMediaName:self.yk_pendingVideoFile];
    self.yk_pendingVideoFile = nil;
}

- (void)yk_clearGoodsItems {
    [self.yk_goodItems removeAllObjects];

    NSArray<UIView *> *arranged = [self.yk_goodsStackView.arrangedSubviews copy];
    for (UIView *v in arranged) {
        [self.yk_goodsStackView removeArrangedSubview:v];
        [v removeFromSuperview];
    }
}

#pragma mark - Goods section

- (NSString *)yk_publishOwnerKey {
    YKAccountVault *vault = [YKAccountVault sharedVault];
    NSString *mailbox = vault.yk_activeMailbox ?: @"";
    if ([YKAccountVault yk_isReviewMailbox:mailbox]) {
        return [YKPersonaCatalog yk_reviewPersonaId];
    }
    return mailbox.length > 0 ? mailbox : @"guest";
}

- (NSDictionary *)yk_buildPublishedEntry {
    YKAccountVault *vault = [YKAccountVault sharedVault];
    YKPublishLedger *ledger = [YKPublishLedger sharedLedger];
    NSString *imageFile = [ledger yk_storeJPEGImage:self.yk_sourceThumbnail];
    if (imageFile.length == 0) {
        return nil;
    }
    if (self.yk_sourceIsVideo && self.yk_pendingVideoFile.length == 0) {
        [ledger yk_deleteRelativeMediaName:imageFile];
        return nil;
    }

    NSMutableArray *items = [NSMutableArray array];
    for (NSDictionary *good in self.yk_goodItems) {
        UIImage *goodsImage = [good[@"image"] isKindOfClass:UIImage.class] ? good[@"image"] : nil;
        NSString *goodsFile = [ledger yk_storeJPEGImage:goodsImage];
        if (goodsFile.length == 0) {
            continue;
        }
        NSString *brand = [good[@"name"] description] ?: @"";
        NSString *price = [good[@"price"] description] ?: @"";
        NSString *desc = [good[@"description"] description] ?: @"";
        [items addObject:@{
            @"brand": brand,
            @"price": price,
            @"description": desc,
            @"imageFile": goodsFile
        }];
    }

    CGFloat width = MAX(self.yk_sourceThumbnail.size.width, 1.0);
    CGFloat height = MAX(self.yk_sourceThumbnail.size.height, 1.0);
    CGFloat ratio = MIN(1.8, MAX(0.9, height / width));
    NSString *caption = [self.yk_dynamicTextView.text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet] ?: @"";
    NSString *name = [vault yk_displayNameForActiveMailbox] ?: @"Yoka User";
    NSString *ownerKey = [self yk_publishOwnerKey];

    NSMutableDictionary *post = [@{
        @"entryId": [NSUUID UUID].UUIDString.lowercaseString,
        @"personaId": ownerKey,
        @"name": name,
        @"caption": caption,
        @"imageFile": imageFile,
        @"isVideo": @(self.yk_sourceIsVideo),
        @"isMine": @YES,
        @"ratio": @(ratio),
        @"remarks": @[],
        @"items": items,
        @"favors": @0,
        @"createdAt": @([[NSDate date] timeIntervalSince1970])
    } mutableCopy];
    if (self.yk_pendingVideoFile.length > 0) {
        post[@"videoFile"] = self.yk_pendingVideoFile;
    }
    return post;
}

- (void)yk_dispatchEntryTapped:(UIButton *)sender {
    if (!self.yk_sourceThumbnail) {
        [YKCenterToast yk_showNotice:@"Add a photo or video first" inView:self.view];
        return;
    }

    __weak typeof(self) weakSelf = self;
    [YKCenterToast yk_showLoadingInView:self.view performAfterDelay:0.7 work:^{
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) { return; }

        NSDictionary *entry = [self yk_buildPublishedEntry];
        if (!entry) {
            [YKCenterToast yk_showNotice:@"Save failed" inView:self.view];
            return;
        }
        [[YKPublishLedger sharedLedger] yk_prependEntry:entry forOwnerKey:[self yk_publishOwnerKey]];
        // Ownership transferred into the ledger; don't delete on leave.
        self.yk_pendingVideoFile = nil;

        [YKCenterToast yk_showNotice:[YKSigilForge yk_unveil:@"JKASYqgvjpEMBfv9FzlXsA=="] inView:self.view];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.55 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if (self.navigationController) {
                [self.navigationController popViewControllerAnimated:YES];
            } else {
                [self dismissViewControllerAnimated:YES completion:nil];
            }
        });
    }];
}

- (void)yk_reloadGoodsSection {
    NSArray<UIView *> *arranged = [self.yk_goodsStackView.arrangedSubviews copy];
    for (UIView *v in arranged) {
        [self.yk_goodsStackView removeArrangedSubview:v];
        [v removeFromSuperview];
    }
    for (NSInteger index = 0; index < self.yk_goodItems.count; index++) {
        [self.yk_goodsStackView addArrangedSubview:[self yk_goodsListCardAtIndex:index]];
    }
}

- (void)yk_addGoodTapped:(UIButton *)sender {
    NSString *caption = [self.yk_dynamicTextView.text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet] ?: @"";
    if (caption.length == 0 || !self.yk_sourceThumbnail) {
        [YKCenterToast yk_showNotice:@"Add description and photo first" inView:self.view];
        return;
    }

    __weak typeof(self) weakSelf = self;
    YKPublicGoodsViewController *goodsViewController = [[YKPublicGoodsViewController alloc] init];
    goodsViewController.completion = ^(NSDictionary<NSString *,id> * _Nonnull item) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!self || !item) {
            return;
        }
        [self.yk_goodItems addObject:item];
        [self yk_reloadGoodsSection];
    };
    [self.navigationController pushViewController:goodsViewController animated:YES];
}

- (void)yk_updateAddItemButtonEnabled {
    NSString *caption = [self.yk_dynamicTextView.text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet] ?: @"";
    BOOL enabled = caption.length > 0 && self.yk_sourceThumbnail != nil;
    self.yk_addGoodButton.enabled = enabled;
    self.yk_addGoodButton.alpha = enabled ? 1.0 : 0.45;
}

- (UIView *)yk_goodsListCardAtIndex:(NSInteger)index {
    NSDictionary<NSString *, id> *item = self.yk_goodItems[index];
    BOOL useLightBorder = index % 2 == 1;

    UIView *card = [[UIView alloc] init];
    card.translatesAutoresizingMaskIntoConstraints = NO;
    card.backgroundColor = useLightBorder ? [UIColor colorWithRed:0xD9 / 255.0 green:0x75 / 255.0 blue:0xFF / 255.0 alpha:0.95] : UIColor.whiteColor;
    card.layer.borderWidth = 2.0;
    card.layer.borderColor = (useLightBorder ? UIColor.whiteColor : UIColor.blackColor).CGColor;

    UIButton *deleteButton = [UIButton buttonWithType:UIButtonTypeCustom];
    deleteButton.translatesAutoresizingMaskIntoConstraints = NO;
    deleteButton.tag = index;
    deleteButton.backgroundColor = [UIColor colorWithWhite:0 alpha:0.15];
    deleteButton.layer.cornerRadius = 12.0;
    deleteButton.titleLabel.font = [UIFont systemFontOfSize:18.0 weight:UIFontWeightBold];
    [deleteButton setTitle:@"×" forState:UIControlStateNormal];
    [deleteButton setTitleColor:(useLightBorder ? UIColor.whiteColor : UIColor.blackColor) forState:UIControlStateNormal];
    [deleteButton addTarget:self action:@selector(yk_deleteGoodTapped:) forControlEvents:UIControlEventTouchUpInside];
    [card addSubview:deleteButton];

    UIImageView *imageView = [[UIImageView alloc] initWithImage:item[@"image"]];
    imageView.translatesAutoresizingMaskIntoConstraints = NO;
    imageView.contentMode = UIViewContentModeScaleAspectFill;
    imageView.clipsToBounds = YES;
    imageView.layer.borderWidth = 2.0;
    imageView.layer.borderColor = (useLightBorder ? UIColor.whiteColor : UIColor.blackColor).CGColor;
    [card addSubview:imageView];

    UILabel *nameLabel = [[UILabel alloc] init];
    nameLabel.translatesAutoresizingMaskIntoConstraints = NO;
    nameLabel.text = [NSString stringWithFormat:@"Brand: %@", item[@"name"] ?: @""];
    nameLabel.textColor = useLightBorder ? UIColor.whiteColor : UIColor.blackColor;
    nameLabel.font = [UIFont systemFontOfSize:17.0 weight:UIFontWeightBold];
    [card addSubview:nameLabel];

    UILabel *priceLabel = [[UILabel alloc] init];
    priceLabel.translatesAutoresizingMaskIntoConstraints = NO;
    NSString *priceText = [item[@"price"] description] ?: @"";
    priceLabel.text = [NSString stringWithFormat:@"Price: %@", priceText];
    priceLabel.textColor = [UIColor colorWithRed:1.0 green:0x9B / 255.0 blue:0x3D / 255.0 alpha:1.0];
    priceLabel.font = [UIFont systemFontOfSize:16.0 weight:UIFontWeightBold];
    [card addSubview:priceLabel];

    UILabel *descriptionLabel = [[UILabel alloc] init];
    descriptionLabel.translatesAutoresizingMaskIntoConstraints = NO;
    descriptionLabel.text = item[@"description"] ?: @"";
    descriptionLabel.numberOfLines = 3;
    descriptionLabel.textColor = useLightBorder ? [UIColor colorWithWhite:1.0 alpha:0.95] : [UIColor colorWithWhite:0.22 alpha:1.0];
    descriptionLabel.font = [UIFont systemFontOfSize:14.0 weight:UIFontWeightMedium];
    [card addSubview:descriptionLabel];

    [NSLayoutConstraint activateConstraints:@[
        [card.heightAnchor constraintEqualToConstant:148.0],
        [deleteButton.topAnchor constraintEqualToAnchor:card.topAnchor constant:8.0],
        [deleteButton.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-8.0],
        [deleteButton.widthAnchor constraintEqualToConstant:24.0],
        [deleteButton.heightAnchor constraintEqualToConstant:24.0],

        [imageView.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:14.0],
        [imageView.centerYAnchor constraintEqualToAnchor:card.centerYAnchor],
        [imageView.widthAnchor constraintEqualToConstant:108.0],
        [imageView.heightAnchor constraintEqualToConstant:108.0],

        [nameLabel.topAnchor constraintEqualToAnchor:card.topAnchor constant:18.0],
        [nameLabel.leadingAnchor constraintEqualToAnchor:imageView.trailingAnchor constant:14.0],
        [nameLabel.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-16.0],

        [priceLabel.topAnchor constraintEqualToAnchor:nameLabel.bottomAnchor constant:8.0],
        [priceLabel.leadingAnchor constraintEqualToAnchor:nameLabel.leadingAnchor],
        [priceLabel.trailingAnchor constraintEqualToAnchor:nameLabel.trailingAnchor],

        [descriptionLabel.topAnchor constraintEqualToAnchor:priceLabel.bottomAnchor constant:8.0],
        [descriptionLabel.leadingAnchor constraintEqualToAnchor:nameLabel.leadingAnchor],
        [descriptionLabel.trailingAnchor constraintEqualToAnchor:nameLabel.trailingAnchor]
    ]];

    return card;
}

- (void)yk_deleteGoodTapped:(UIButton *)sender {
    NSInteger index = sender.tag;
    if (index < 0 || index >= self.yk_goodItems.count) {
        return;
    }
    [self.yk_goodItems removeObjectAtIndex:index];
    [self yk_reloadGoodsSection];
}

#pragma mark - Dynamic picker

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

    [YKCenterToast yk_showLoadingInView:self.view];
    __weak typeof(self) weakSelf = self;

    // Dynamic pick (image or video thumbnail)
    if ([provider canLoadObjectOfClass:UIImage.class]) {
        [provider loadObjectOfClass:UIImage.class completionHandler:^(__kindof id<NSItemProviderReading> _Nullable object, NSError * _Nullable error) {
            UIImage *image = [object isKindOfClass:UIImage.class] ? (UIImage *)object : nil;
            dispatch_async(dispatch_get_main_queue(), ^{
                __strong typeof(weakSelf) self = weakSelf;
                if (!self) { return; }
                [YKCenterToast yk_hideLoadingInView:self.view];
                if (!image) { return; }
                [self yk_applySourceThumbnail:image isVideo:NO videoFile:nil];
            });
        }];
        return;
    }

    NSString *movieIdentifier = UTTypeMovie.identifier;
    if (![provider hasItemConformingToTypeIdentifier:movieIdentifier]) {
        [YKCenterToast yk_hideLoadingInView:weakSelf.view];
        return;
    }

    [provider loadFileRepresentationForTypeIdentifier:movieIdentifier completionHandler:^(NSURL * _Nullable url, NSError * _Nullable error) {
        UIImage *thumbnail = nil;
        NSString *storedVideo = nil;
        if (url) {
            AVURLAsset *asset = [AVURLAsset URLAssetWithURL:url options:nil];
            AVAssetImageGenerator *generator = [[AVAssetImageGenerator alloc] initWithAsset:asset];
            generator.appliesPreferredTrackTransform = YES;
            generator.maximumSize = CGSizeMake(600.0, 600.0);
            NSError *genError = nil;
            CGImageRef imageRef = [generator copyCGImageAtTime:kCMTimeZero actualTime:NULL error:&genError];
            if (imageRef) {
                thumbnail = [UIImage imageWithCGImage:imageRef];
                CGImageRelease(imageRef);
            }
            // Temp URL is only valid inside this handler — copy the movie now.
            storedVideo = [[YKPublishLedger sharedLedger] yk_storeVideoFileAtURL:url];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            __strong typeof(weakSelf) self = weakSelf;
            if (!self) { return; }
            [YKCenterToast yk_hideLoadingInView:self.view];
            if (!thumbnail || storedVideo.length == 0) {
                if (storedVideo.length > 0) {
                    [[YKPublishLedger sharedLedger] yk_deleteRelativeMediaName:storedVideo];
                }
                [YKCenterToast yk_showNotice:@"Video save failed" inView:self.view];
                return;
            }
            [self yk_applySourceThumbnail:thumbnail isVideo:YES videoFile:storedVideo];
        });
    }];
}

- (void)yk_applySourceThumbnail:(UIImage *)thumbnail isVideo:(BOOL)isVideo videoFile:(NSString *)videoFile {
    [self yk_discardPendingVideoFile];
    self.yk_sourceThumbnail = thumbnail;
    self.yk_sourceIsVideo = isVideo;
    self.yk_pendingVideoFile = videoFile;

    // Dynamic changed -> clear goods list, then enable goods add.
    [self yk_clearGoodsItems];

    [self yk_reloadSourceItems];
    [self yk_reloadGoodsSection];
    [self yk_updateAddItemButtonEnabled];
}

#pragma mark - UITextViewDelegate

- (void)textViewDidChange:(UITextView *)textView {
    self.yk_dynamicPlaceholderLabel.hidden = textView.text.length > 0;
    [self yk_updateAddItemButtonEnabled];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    [self yk_updateSourceScrollBehavior];
}

@end

