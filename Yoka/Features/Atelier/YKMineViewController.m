//
//  YKMineViewController.m
//  Yoka
//

#import "YKMineViewController.h"
#import "YKSettingViewController.h"
#import "YKBondListViewController.h"
#import "YKSparkTopUpViewController.h"
#import "YKRosterVault.h"
#import "YKProfileInfoViewController.h"
#import "YKPersonaCatalog.h"
#import "YKBondLedger.h"
#import "YKSparkCoffer.h"
#import "YKOutfitFeedCatalog.h"
#import "YKFindDetailViewController.h"
#import "YKFindFavorLedger.h"
#import "YKPublishLedger.h"
#import "YKRemarkLedger.h"
#import "YKEmptyStateView.h"
#import <AVFoundation/AVFoundation.h>
#import "YKCipherLoom.h"

@interface YKMinePostCell : UICollectionViewCell

- (void)configureWithEntry:(NSDictionary *)post
              displayName:(NSString *)displayName
                   avatar:(UIImage *)avatar
                 ownerKey:(NSString *)ownerKey;

@end

@interface YKMinePostCell ()

@property (nonatomic, strong) UIView *photoView;
@property (nonatomic, strong) CAGradientLayer *photoGradientLayer;
@property (nonatomic, strong) UIImageView *coverImageView;
@property (nonatomic, strong) UIImageView *avatarImageView;
@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) UILabel *subNameLabel;
@property (nonatomic, strong) UILabel *photoTitleLabel;
@property (nonatomic, strong) UIImageView *playImageView;
@property (nonatomic, strong) UIImageView *favorIconView;
@property (nonatomic, strong) UILabel *favorsLabel;
@property (nonatomic, strong) UILabel *commentsLabel;
@property (nonatomic, strong) UIButton *moreButton;
@property (nonatomic, strong) UIButton *favorButton;
@property (nonatomic, copy) NSDictionary *yk_entry;
@property (nonatomic, copy) NSString *yk_ownerKey;
@property (nonatomic, assign) BOOL yk_favored;
@property (nonatomic, assign) NSInteger yk_favorCount;
@property (nonatomic, assign) NSInteger yk_baseLikeCount;
@property (nonatomic, copy) NSString *yk_videoToken;

@end

@implementation YKMinePostCell

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self yk_setupViews];
    }
    return self;
}

- (void)yk_setupViews {
    self.contentView.backgroundColor = UIColor.whiteColor;
    self.contentView.layer.cornerRadius = 14.0;
    self.contentView.layer.masksToBounds = YES;

    UIImageView *avatarImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"headplace"]];
    avatarImageView.translatesAutoresizingMaskIntoConstraints = NO;
    avatarImageView.contentMode = UIViewContentModeScaleAspectFill;
    avatarImageView.layer.cornerRadius = 18.0;
    avatarImageView.layer.masksToBounds = YES;
    [self.contentView addSubview:avatarImageView];
    self.avatarImageView = avatarImageView;

    UILabel *nameLabel = [[UILabel alloc] init];
    nameLabel.translatesAutoresizingMaskIntoConstraints = NO;
    nameLabel.text = @"Amelia";
    nameLabel.textColor = UIColor.blackColor;
    nameLabel.font = [UIFont systemFontOfSize:15.0 weight:UIFontWeightBold];
    [self.contentView addSubview:nameLabel];
    self.nameLabel = nameLabel;

    UILabel *subNameLabel = [[UILabel alloc] init];
    subNameLabel.translatesAutoresizingMaskIntoConstraints = NO;
    subNameLabel.text = @"Amelia";
    subNameLabel.textColor = [UIColor colorWithWhite:0.35 alpha:1.0];
    subNameLabel.font = [UIFont systemFontOfSize:12.0 weight:UIFontWeightRegular];
    [self.contentView addSubview:subNameLabel];
    self.subNameLabel = subNameLabel;

    UIButton *moreButton = [UIButton buttonWithType:UIButtonTypeCustom];
    moreButton.translatesAutoresizingMaskIntoConstraints = NO;
    [moreButton setImage:[[UIImage imageNamed:@"detail_more_button"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] forState:UIControlStateNormal];
    moreButton.hidden = YES; // Own posts never show the overflow menu.
    [self.contentView addSubview:moreButton];
    self.moreButton = moreButton;

    UIView *photoView = [[UIView alloc] init];
    photoView.translatesAutoresizingMaskIntoConstraints = NO;
    photoView.layer.cornerRadius = 10.0;
    photoView.layer.masksToBounds = YES;
    photoView.backgroundColor = [UIColor colorWithRed:0.12 green:0.11 blue:0.18 alpha:1.0];
    [self.contentView addSubview:photoView];
    self.photoView = photoView;

    CAGradientLayer *photoGradientLayer = [CAGradientLayer layer];
    photoGradientLayer.startPoint = CGPointMake(0.0, 0.0);
    photoGradientLayer.endPoint = CGPointMake(1.0, 1.0);
    [photoView.layer addSublayer:photoGradientLayer];
    self.photoGradientLayer = photoGradientLayer;

    UIImageView *coverImageView = [[UIImageView alloc] init];
    coverImageView.translatesAutoresizingMaskIntoConstraints = NO;
    coverImageView.contentMode = UIViewContentModeScaleAspectFill;
    coverImageView.clipsToBounds = YES;
    [photoView addSubview:coverImageView];
    self.coverImageView = coverImageView;

    UILabel *photoTitleLabel = [[UILabel alloc] init];
    photoTitleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    photoTitleLabel.text = @"Y2K FIT";
    photoTitleLabel.textColor = [UIColor colorWithWhite:1.0 alpha:0.86];
    photoTitleLabel.textAlignment = NSTextAlignmentCenter;
    photoTitleLabel.font = [UIFont systemFontOfSize:30.0 weight:UIFontWeightBlack];
    [photoView addSubview:photoTitleLabel];
    self.photoTitleLabel = photoTitleLabel;

    UIImageView *playImageView = [[UIImageView alloc] initWithImage:[[UIImage imageNamed:@"mine_play_icon"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]];
    playImageView.translatesAutoresizingMaskIntoConstraints = NO;
    playImageView.contentMode = UIViewContentModeScaleAspectFit;
    playImageView.hidden = YES;
    [photoView addSubview:playImageView];
    self.playImageView = playImageView;

    UIStackView *statsStackView = [[UIStackView alloc] init];
    statsStackView.translatesAutoresizingMaskIntoConstraints = NO;
    statsStackView.axis = UILayoutConstraintAxisHorizontal;
    statsStackView.alignment = UIStackViewAlignmentCenter;
    statsStackView.spacing = 18.0;
    [self.contentView addSubview:statsStackView];

    UIButton *favorBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    favorBtn.translatesAutoresizingMaskIntoConstraints = NO;
    [favorBtn addTarget:self action:@selector(yk_favorTapped:) forControlEvents:UIControlEventTouchUpInside];
    [statsStackView addArrangedSubview:favorBtn];
    self.favorButton = favorBtn;

    UIStackView *favorStack = [[UIStackView alloc] init];
    favorStack.translatesAutoresizingMaskIntoConstraints = NO;
    favorStack.axis = UILayoutConstraintAxisHorizontal;
    favorStack.alignment = UIStackViewAlignmentCenter;
    favorStack.spacing = 4.0;
    favorStack.userInteractionEnabled = NO;
    [favorBtn addSubview:favorStack];

    UIImageView *favorIconView = [[UIImageView alloc] init];
    favorIconView.translatesAutoresizingMaskIntoConstraints = NO;
    favorIconView.contentMode = UIViewContentModeScaleAspectFit;
    [favorStack addArrangedSubview:favorIconView];
    self.favorIconView = favorIconView;

    UILabel *favorsLabel = [[UILabel alloc] init];
    favorsLabel.text = @"0";
    favorsLabel.textColor = UIColor.blackColor;
    favorsLabel.font = [UIFont systemFontOfSize:10.0 weight:UIFontWeightRegular];
    [favorStack addArrangedSubview:favorsLabel];
    self.favorsLabel = favorsLabel;

    UIStackView *remarksStack = [[UIStackView alloc] init];
    remarksStack.axis = UILayoutConstraintAxisHorizontal;
    remarksStack.alignment = UIStackViewAlignmentCenter;
    remarksStack.spacing = 4.0;
    [statsStackView addArrangedSubview:remarksStack];

    UIImageView *remarkIconView = [[UIImageView alloc] init];
    remarkIconView.translatesAutoresizingMaskIntoConstraints = NO;
    remarkIconView.contentMode = UIViewContentModeScaleAspectFit;
    // Asset is white (for purple detail); tint black so it reads on the white Mine card.
    remarkIconView.image = [[UIImage imageNamed:@"detail_remark_icon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    remarkIconView.tintColor = UIColor.blackColor;
    [remarksStack addArrangedSubview:remarkIconView];

    UILabel *commentsLabel = [[UILabel alloc] init];
    commentsLabel.text = @"0";
    commentsLabel.textColor = UIColor.blackColor;
    commentsLabel.font = [UIFont systemFontOfSize:10.0 weight:UIFontWeightRegular];
    [remarksStack addArrangedSubview:commentsLabel];
    self.commentsLabel = commentsLabel;

    [NSLayoutConstraint activateConstraints:@[
        [avatarImageView.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:14.0],
        [avatarImageView.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:18.0],
        [avatarImageView.widthAnchor constraintEqualToConstant:36.0],
        [avatarImageView.heightAnchor constraintEqualToConstant:36.0],

        [nameLabel.topAnchor constraintEqualToAnchor:avatarImageView.topAnchor constant:2.0],
        [nameLabel.leadingAnchor constraintEqualToAnchor:avatarImageView.trailingAnchor constant:10.0],

        [subNameLabel.topAnchor constraintEqualToAnchor:nameLabel.bottomAnchor constant:1.0],
        [subNameLabel.leadingAnchor constraintEqualToAnchor:nameLabel.leadingAnchor],

        [moreButton.centerYAnchor constraintEqualToAnchor:avatarImageView.centerYAnchor],
        [moreButton.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-16.0],
        [moreButton.widthAnchor constraintEqualToConstant:28.0],
        [moreButton.heightAnchor constraintEqualToConstant:28.0],

        [photoView.topAnchor constraintEqualToAnchor:avatarImageView.bottomAnchor constant:16.0],
        [photoView.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:18.0],
        [photoView.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-18.0],
        [photoView.heightAnchor constraintEqualToAnchor:photoView.widthAnchor multiplier:0.83],

        [coverImageView.topAnchor constraintEqualToAnchor:photoView.topAnchor],
        [coverImageView.leadingAnchor constraintEqualToAnchor:photoView.leadingAnchor],
        [coverImageView.trailingAnchor constraintEqualToAnchor:photoView.trailingAnchor],
        [coverImageView.bottomAnchor constraintEqualToAnchor:photoView.bottomAnchor],

        [photoTitleLabel.centerXAnchor constraintEqualToAnchor:photoView.centerXAnchor],
        [photoTitleLabel.centerYAnchor constraintEqualToAnchor:photoView.centerYAnchor],

        [playImageView.centerXAnchor constraintEqualToAnchor:photoView.centerXAnchor],
        [playImageView.centerYAnchor constraintEqualToAnchor:photoView.centerYAnchor],
        [playImageView.widthAnchor constraintEqualToConstant:24.0],
        [playImageView.heightAnchor constraintEqualToConstant:24.0],

        [statsStackView.topAnchor constraintEqualToAnchor:photoView.bottomAnchor constant:10.0],
        [statsStackView.leadingAnchor constraintEqualToAnchor:photoView.leadingAnchor],
        [statsStackView.heightAnchor constraintEqualToConstant:18.0],
        [statsStackView.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor constant:-14.0],

        [favorStack.topAnchor constraintEqualToAnchor:favorBtn.topAnchor],
        [favorStack.leadingAnchor constraintEqualToAnchor:favorBtn.leadingAnchor],
        [favorStack.trailingAnchor constraintEqualToAnchor:favorBtn.trailingAnchor],
        [favorStack.bottomAnchor constraintEqualToAnchor:favorBtn.bottomAnchor],
        [favorIconView.widthAnchor constraintEqualToConstant:14.0],
        [favorIconView.heightAnchor constraintEqualToConstant:14.0],
        [remarkIconView.widthAnchor constraintEqualToConstant:14.0],
        [remarkIconView.heightAnchor constraintEqualToConstant:14.0]
    ]];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.photoGradientLayer.frame = self.photoView.bounds;
}

- (void)prepareForReuse {
    [super prepareForReuse];
    self.yk_videoToken = nil;
    self.yk_entry = nil;
    self.yk_ownerKey = nil;
    self.coverImageView.image = nil;
    self.photoTitleLabel.alpha = 1.0;
}

- (void)yk_refreshFavorAppearance {
    YKFindFavorLedger *ledger = [YKFindFavorLedger sharedLedger];
    NSString *iconName = self.yk_favored ? [ledger yk_favoredStarImageName] : [ledger yk_unfavoredStarImageName];
    self.favorIconView.image = [[UIImage imageNamed:iconName] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    self.favorsLabel.text = [NSString stringWithFormat:@"%ld", (long)self.yk_favorCount];
}

- (void)yk_favorTapped:(UIButton *)sender {
    if (!self.yk_entry || self.yk_ownerKey.length == 0) {
        return;
    }
    self.yk_favored = !self.yk_favored;
    self.yk_favorCount += self.yk_favored ? 1 : -1;
    if (self.yk_favorCount < 0) {
        self.yk_favorCount = 0;
    }
    if (self.yk_favorCount > 20) {
        self.yk_favorCount = 20;
    }
    [[YKFindFavorLedger sharedLedger] yk_setEntry:self.yk_entry favored:self.yk_favored ownerKey:self.yk_ownerKey];
    [self yk_refreshFavorAppearance];
}

- (void)configureWithEntry:(NSDictionary *)post
              displayName:(NSString *)displayName
                   avatar:(UIImage *)avatar
                 ownerKey:(NSString *)ownerKey {
    self.yk_entry = post ?: @{};
    self.yk_ownerKey = ownerKey ?: @"";

    NSString *name = displayName.length > 0 ? displayName : (post[@"name"] ?: @"Yoka");
    self.nameLabel.text = name;
    self.subNameLabel.text = name;
    if (avatar) {
        self.avatarImageView.image = [avatar imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    } else {
        self.avatarImageView.image = [UIImage imageNamed:@"headplace"];
    }

    NSArray *catalogRemarksList = post[@"remarks"];
    NSString *postKey = [YKFindFavorLedger yk_entryKeyForEntry:post];
    NSArray *merged = [[YKRemarkLedger sharedLedger] yk_remarksForOwnerKey:ownerKey
                                                                   postKey:postKey
                                                              catalogRemarks:catalogRemarksList];
    self.commentsLabel.text = [NSString stringWithFormat:@"%ld", (long)merged.count];

    // Same base favor mix as detail so list / detail stay in sync.
    NSNumber *likesNumber = post[@"favors"];
    NSInteger baseFavors;
    if ([likesNumber isKindOfClass:NSNumber.class]) {
        baseFavors = MAX(0, MIN(20, likesNumber.integerValue));
    } else {
        baseFavors = (NSInteger)(postKey.hash % 20) + 1;
    }
    self.yk_baseLikeCount = baseFavors;
    self.yk_favored = [[YKFindFavorLedger sharedLedger] yk_isEntryFavored:post ownerKey:ownerKey];
    self.yk_favorCount = MIN(20, baseFavors + (self.yk_favored ? 1 : 0));
    [self yk_refreshFavorAppearance];
    self.moreButton.hidden = YES;

    self.photoGradientLayer.colors = @[
        (__bridge id)[UIColor colorWithRed:0.12 green:0.11 blue:0.18 alpha:1.0].CGColor,
        (__bridge id)[UIColor colorWithRed:0.92 green:0.02 blue:0.80 alpha:1.0].CGColor
    ];

    NSString *videoName = [post[@"video"] isKindOfClass:NSString.class] ? post[@"video"] : @"";
    NSString *imageName = [post[@"image"] isKindOfClass:NSString.class] ? post[@"image"] : @"";
    BOOL isVideo = videoName.length > 0 || [post[@"isVideo"] boolValue];
    self.playImageView.hidden = !isVideo;
    self.yk_videoToken = videoName.length > 0 ? videoName : (imageName.length > 0 ? imageName : (post[@"imageFile"] ?: @""));
    self.coverImageView.image = nil;
    self.photoTitleLabel.alpha = 1.0;

    // Published posts use local imageFile / imagePath cover.
    UIImage *fileCover = [YKPublishLedger yk_coverImageForEntry:post];
    if (fileCover && videoName.length == 0) {
        self.coverImageView.image = [fileCover imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
        self.photoTitleLabel.alpha = 0.0;
        return;
    }

    if (imageName.length > 0 && videoName.length == 0) {
        self.coverImageView.image = [[UIImage imageNamed:imageName] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
        self.photoTitleLabel.alpha = 0.0;
        return;
    }

    if (videoName.length == 0) {
        return;
    }
    NSURL *url = [[NSBundle mainBundle] URLForResource:videoName withExtension:@"mp4"];
    if (!url) {
        if (fileCover) {
            self.coverImageView.image = [fileCover imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
            self.photoTitleLabel.alpha = 0.0;
        }
        return;
    }
    NSString *token = videoName;
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        AVAsset *asset = [AVAsset assetWithURL:url];
        AVAssetImageGenerator *generator = [AVAssetImageGenerator assetImageGeneratorWithAsset:asset];
        generator.appliesPreferredTrackTransform = YES;
        generator.maximumSize = CGSizeMake(800.0, 800.0);
        NSError *error = nil;
        CGImageRef cgImage = [generator copyCGImageAtTime:CMTimeMake(1, 2) actualTime:NULL error:&error];
        if (!cgImage) {
            return;
        }
        UIImage *thumb = [UIImage imageWithCGImage:cgImage];
        CGImageRelease(cgImage);
        dispatch_async(dispatch_get_main_queue(), ^{
            if (![self.yk_videoToken isEqualToString:token]) {
                return;
            }
            self.coverImageView.image = thumb;
            self.photoTitleLabel.alpha = 0.0;
        });
    });
}

@end

@interface YKMineCollectionCell : UICollectionViewCell

- (void)configureWithEntry:(NSDictionary *)post;

@end

@interface YKMineCollectionCell ()

@property (nonatomic, strong) UIImageView *coverImageView;
@property (nonatomic, strong) UIImageView *playImageView;
@property (nonatomic, strong) CAGradientLayer *gradientLayer;
@property (nonatomic, copy) NSString *yk_coverToken;

@end

@implementation YKMineCollectionCell

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.contentView.layer.cornerRadius = 14.0;
        self.contentView.layer.masksToBounds = YES;
        self.contentView.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.12];

        CAGradientLayer *gradientLayer = [CAGradientLayer layer];
        gradientLayer.startPoint = CGPointMake(0.0, 0.0);
        gradientLayer.endPoint = CGPointMake(1.0, 1.0);
        [self.contentView.layer insertSublayer:gradientLayer atIndex:0];
        self.gradientLayer = gradientLayer;

        UIImageView *coverImageView = [[UIImageView alloc] init];
        coverImageView.translatesAutoresizingMaskIntoConstraints = NO;
        coverImageView.contentMode = UIViewContentModeScaleAspectFill;
        coverImageView.clipsToBounds = YES;
        [self.contentView addSubview:coverImageView];
        self.coverImageView = coverImageView;

        UIImageView *playImageView = [[UIImageView alloc] initWithImage:[[UIImage imageNamed:@"mine_play_icon"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]];
        playImageView.translatesAutoresizingMaskIntoConstraints = NO;
        playImageView.contentMode = UIViewContentModeScaleAspectFit;
        [self.contentView addSubview:playImageView];
        self.playImageView = playImageView;

        [NSLayoutConstraint activateConstraints:@[
            [coverImageView.topAnchor constraintEqualToAnchor:self.contentView.topAnchor],
            [coverImageView.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor],
            [coverImageView.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor],
            [coverImageView.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor],

            [playImageView.centerXAnchor constraintEqualToAnchor:self.contentView.centerXAnchor],
            [playImageView.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],
            [playImageView.widthAnchor constraintEqualToConstant:24.0],
            [playImageView.heightAnchor constraintEqualToConstant:24.0]
        ]];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.gradientLayer.frame = self.contentView.bounds;
}

- (void)prepareForReuse {
    [super prepareForReuse];
    self.yk_coverToken = nil;
    self.coverImageView.image = nil;
    self.playImageView.hidden = NO;
}

- (void)configureWithEntry:(NSDictionary *)post {
    NSString *videoName = [post[@"video"] isKindOfClass:NSString.class] ? post[@"video"] : @"";
    NSString *imageName = [post[@"image"] isKindOfClass:NSString.class] ? post[@"image"] : @"";
    BOOL isPublishedVideo = [post[@"isVideo"] boolValue];
    self.playImageView.hidden = (videoName.length == 0 && !isPublishedVideo);
    self.coverImageView.image = nil;
    self.gradientLayer.colors = @[
        (__bridge id)[UIColor colorWithRed:0.12 green:0.11 blue:0.18 alpha:1.0].CGColor,
        (__bridge id)[UIColor colorWithRed:0.14 green:0.10 blue:0.18 alpha:1.0].CGColor
    ];

    if (imageName.length > 0 && videoName.length == 0) {
        self.yk_coverToken = imageName;
        self.coverImageView.image = [[UIImage imageNamed:imageName] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
        return;
    }
    UIImage *fileCover = [YKPublishLedger yk_coverImageForEntry:post];
    if (fileCover && videoName.length == 0) {
        self.yk_coverToken = post[@"imageFile"] ?: post[@"imagePath"] ?: @"file";
        self.coverImageView.image = [fileCover imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
        return;
    }
    if (videoName.length == 0) {
        self.yk_coverToken = nil;
        return;
    }

    self.yk_coverToken = videoName;
    NSURL *url = [[NSBundle mainBundle] URLForResource:videoName withExtension:@"mp4"];
    if (!url) {
        return;
    }
    NSString *token = videoName;
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        AVAsset *asset = [AVAsset assetWithURL:url];
        AVAssetImageGenerator *generator = [AVAssetImageGenerator assetImageGeneratorWithAsset:asset];
        generator.appliesPreferredTrackTransform = YES;
        generator.maximumSize = CGSizeMake(600.0, 600.0);
        NSError *error = nil;
        CGImageRef cgImage = [generator copyCGImageAtTime:CMTimeMake(1, 2) actualTime:NULL error:&error];
        if (!cgImage) {
            return;
        }
        UIImage *thumb = [UIImage imageWithCGImage:cgImage];
        CGImageRelease(cgImage);
        dispatch_async(dispatch_get_main_queue(), ^{
            if (![self.yk_coverToken isEqualToString:token]) {
                return;
            }
            self.coverImageView.image = thumb;
        });
    });
}

@end

@interface YKMineSegmentButton : UIControl

@property (nonatomic, copy, readonly) NSString *title;

- (instancetype)initWithTitle:(NSString *)title NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithFrame:(CGRect)frame NS_UNAVAILABLE;
- (instancetype)initWithCoder:(NSCoder *)coder NS_UNAVAILABLE;
- (void)setSelectionProgress:(CGFloat)progress;

@end

@interface YKMineSegmentButton ()

@property (nonatomic, copy) NSString *title;
@property (nonatomic, strong) UILabel *label;

@end

@implementation YKMineSegmentButton

- (instancetype)initWithTitle:(NSString *)title {
    self = [super initWithFrame:CGRectZero];
    if (self) {
        _title = [title copy];
        UILabel *label = [[UILabel alloc] init];
        label.translatesAutoresizingMaskIntoConstraints = NO;
        label.text = title;
        label.textAlignment = NSTextAlignmentCenter;
        [self addSubview:label];
        self.label = label;

        [NSLayoutConstraint activateConstraints:@[
            [label.topAnchor constraintEqualToAnchor:self.topAnchor],
            [label.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
            [label.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
            [label.bottomAnchor constraintEqualToAnchor:self.bottomAnchor]
        ]];
        [self setSelectionProgress:0.0];
    }
    return self;
}

- (void)setSelectionProgress:(CGFloat)progress {
    CGFloat boundedProgress = MIN(MAX(progress, 0.0), 1.0);
    CGFloat fontSize = 20.0 + 4.0 * boundedProgress;
    CGFloat alpha = 0.44 + 0.56 * boundedProgress;
    self.label.font = [UIFont systemFontOfSize:fontSize weight:boundedProgress > 0.5 ? UIFontWeightBold : UIFontWeightRegular];
    self.label.textColor = [UIColor colorWithWhite:1.0 alpha:alpha];
}

@end

@interface YKMineViewController () <UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UIScrollViewDelegate>

@property (nonatomic, strong) NSArray<NSString *> *segmentTitles;
@property (nonatomic, strong) NSMutableArray<YKMineSegmentButton *> *segmentButtons;
@property (nonatomic, strong) UIView *indicatorView;
@property (nonatomic, strong) NSLayoutConstraint *indicatorLeadingConstraint;
@property (nonatomic, strong) NSLayoutConstraint *indicatorWidthConstraint;
@property (nonatomic, strong) UIButton *settingsButton;
@property (nonatomic, strong) UIScrollView *pageScrollView;
@property (nonatomic, strong) UIScrollView *contentScrollView;
@property (nonatomic, strong) UICollectionView *entriesCollectionView;
@property (nonatomic, strong) UICollectionView *collectionsCollectionView;
@property (nonatomic, strong) YKEmptyStateView *yk_entriesEmptyView;
@property (nonatomic, strong) YKEmptyStateView *yk_collectionsEmptyView;
@property (nonatomic, strong) NSLayoutConstraint *pagerHeightConstraint;
@property (nonatomic, strong) NSArray<UIColor *> *itemColors;
@property (nonatomic, copy) NSArray<NSDictionary *> *myPosts;
@property (nonatomic, copy) NSArray<NSDictionary *> *myCollections;
@property (nonatomic, assign) NSInteger selectedIndex;
@property (nonatomic, strong) UIImageView *yk_headerAvatarView;
@property (nonatomic, strong) UILabel *yk_headerNameLabel;
@property (nonatomic, strong) UILabel *yk_inboundValueLabel;
@property (nonatomic, strong) UILabel *yk_outboundValueLabel;
@property (nonatomic, strong) UILabel *yk_tallyValueLabel;

@end

@implementation YKMineViewController

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self yk_reloadMyPostsForActiveAccount];
    [self yk_refreshFavoredCollections];
    [self yk_refreshAccountHeader];
    [self.entriesCollectionView reloadData];
    [self.collectionsCollectionView reloadData];
    [self yk_updateMineEmptyStates];
    [self yk_updatePagerHeightIfNeeded];
}

- (NSString *)yk_ownerKey {
    YKRosterVault *vault = [YKRosterVault sharedRoster];
    if ([YKRosterVault yk_isReviewMailbox:vault.yk_activeMailbox ?: @""]) {
        return [YKPersonaCatalog yk_reviewPersonaId];
    }
    return vault.yk_activeMailbox.length > 0 ? vault.yk_activeMailbox : @"guest";
}

/// Published entries for the active account; review mailbox also keeps primed “my” entries.
- (void)yk_reloadMyPostsForActiveAccount {
    NSMutableArray *posts = [NSMutableArray array];
    [posts addObjectsFromArray:[[YKPublishLedger sharedLedger] yk_entriesForOwnerKey:[self yk_ownerKey]]];
    YKRosterVault *vault = [YKRosterVault sharedRoster];
    if ([YKRosterVault yk_isReviewMailbox:vault.yk_activeMailbox ?: @""]) {
        [posts addObjectsFromArray:[YKOutfitFeedCatalog yk_myPosts]];
    }
    self.myPosts = posts;
}

- (void)yk_refreshFavoredCollections {
    NSString *owner = [self yk_ownerKey];
    NSMutableArray<NSDictionary *> *favoredBag = [NSMutableArray array];
    NSMutableSet<NSString *> *seen = [NSMutableSet set];
    YKFindFavorLedger *ledger = [YKFindFavorLedger sharedLedger];
    // Same favor rule as Discover (explicit tap OR default via link).
    NSMutableArray *pool = [NSMutableArray array];
    [pool addObjectsFromArray:[[YKPublishLedger sharedLedger] yk_allPublishedEntries]];
    [pool addObjectsFromArray:[YKOutfitFeedCatalog yk_allPosts]];
    for (NSDictionary *entry in pool) {
        if (![ledger yk_isEntryFavored:entry ownerKey:owner]) {
            continue;
        }
        NSString *key = [YKFindFavorLedger yk_entryKeyForEntry:entry];
        if (key.length == 0 || [seen containsObject:key]) {
            continue;
        }
        [seen addObject:key];
        [favoredBag addObject:entry];
    }
    self.myCollections = [favoredBag copy];
}

- (void)yk_configurePage {
    [super yk_configurePage];

    self.segmentTitles = @[[YKCipherLoom yk_unfurl:@"BJOCwYUjx2NBenty6NZ6Xw=="], @"Collections"];
    self.segmentButtons = [NSMutableArray arrayWithCapacity:self.segmentTitles.count];
    self.itemColors = @[
        [UIColor colorWithRed:0.12 green:0.11 blue:0.18 alpha:1.0],
        [UIColor colorWithRed:0.54 green:0.36 blue:0.26 alpha:1.0],
        [UIColor colorWithRed:0.40 green:0.20 blue:0.18 alpha:1.0],
        [UIColor colorWithRed:0.24 green:0.23 blue:0.30 alpha:1.0],
        [UIColor colorWithRed:0.60 green:0.42 blue:0.36 alpha:1.0],
        [UIColor colorWithRed:0.18 green:0.30 blue:0.38 alpha:1.0]
    ];
    self.myPosts = @[];
    [self yk_reloadMyPostsForActiveAccount];
    [self yk_refreshFavoredCollections];

    [self yk_setupSettingsBar];
    [self yk_setupPageScrollView];
    [self yk_updateSelectionWithProgress:0.0];
    [self yk_refreshAccountHeader];
    [self yk_updateMineEmptyStates];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    [self yk_updatePagerHeightIfNeeded];
    if (!self.contentScrollView.isDragging && !self.contentScrollView.isDecelerating) {
        [self yk_updateSelectionWithProgress:self.selectedIndex];
    }
}

- (void)yk_setupSettingsBar {
    UIButton *settingsButton = [UIButton buttonWithType:UIButtonTypeCustom];
    settingsButton.translatesAutoresizingMaskIntoConstraints = NO;
    [settingsButton setImage:[[UIImage imageNamed:@"mine_settings_button"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] forState:UIControlStateNormal];
    [settingsButton addTarget:self action:@selector(yk_settingsTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:settingsButton];
    self.settingsButton = settingsButton;

    [NSLayoutConstraint activateConstraints:@[
        [settingsButton.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:24.0],
        [settingsButton.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-28.0],
        [settingsButton.widthAnchor constraintEqualToConstant:32.0],
        [settingsButton.heightAnchor constraintEqualToConstant:32.0]
    ]];
}

- (void)yk_setupPageScrollView {
    UIScrollView *pageScrollView = [[UIScrollView alloc] init];
    pageScrollView.translatesAutoresizingMaskIntoConstraints = NO;
    pageScrollView.showsVerticalScrollIndicator = NO;
    pageScrollView.alwaysBounceVertical = YES;
    pageScrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    [self.view addSubview:pageScrollView];
    self.pageScrollView = pageScrollView;

    UIView *pageContentView = [[UIView alloc] init];
    pageContentView.translatesAutoresizingMaskIntoConstraints = NO;
    [pageScrollView addSubview:pageContentView];

    UIImageView *avatarImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"headplace"]];
    avatarImageView.translatesAutoresizingMaskIntoConstraints = NO;
    avatarImageView.layer.cornerRadius = 50.0;
    avatarImageView.layer.masksToBounds = YES;
    avatarImageView.contentMode = UIViewContentModeScaleAspectFill;
    [pageContentView addSubview:avatarImageView];
    self.yk_headerAvatarView = avatarImageView;

    UILabel *inboundValueLabel = [self yk_countLabelWithText:@"0"];
    UILabel *inboundTitleLabel = [self yk_captionLabelWithText:[YKCipherLoom yk_unfurl:@"zp3IYTxq3Gjb3hnCBF06xA=="]];
    UILabel *outboundValueLabel = [self yk_countLabelWithText:@"2"];
    UILabel *outboundTitleLabel = [self yk_captionLabelWithText:[YKCipherLoom yk_unfurl:@"mQ3A5aWGAwIw5fwUx6iQZw=="]];
    [pageContentView addSubview:inboundValueLabel];
    [pageContentView addSubview:inboundTitleLabel];
    [pageContentView addSubview:outboundValueLabel];
    [pageContentView addSubview:outboundTitleLabel];
    self.yk_inboundValueLabel = inboundValueLabel;
    self.yk_outboundValueLabel = outboundValueLabel;

    UIButton *inboundHit = [UIButton buttonWithType:UIButtonTypeCustom];
    inboundHit.translatesAutoresizingMaskIntoConstraints = NO;
    inboundHit.backgroundColor = UIColor.clearColor;
    [inboundHit addTarget:self action:@selector(yk_inboundTapped:) forControlEvents:UIControlEventTouchUpInside];
    [pageContentView addSubview:inboundHit];

    UIButton *outboundHit = [UIButton buttonWithType:UIButtonTypeCustom];
    outboundHit.translatesAutoresizingMaskIntoConstraints = NO;
    outboundHit.backgroundColor = UIColor.clearColor;
    [outboundHit addTarget:self action:@selector(yk_outboundTapped:) forControlEvents:UIControlEventTouchUpInside];
    [pageContentView addSubview:outboundHit];

    UILabel *nameLabel = [[UILabel alloc] init];
    nameLabel.translatesAutoresizingMaskIntoConstraints = NO;
    nameLabel.text = @"Amelia";
    nameLabel.textColor = UIColor.whiteColor;
    nameLabel.font = [UIFont systemFontOfSize:27.0 weight:UIFontWeightBold];
    [pageContentView addSubview:nameLabel];
    self.yk_headerNameLabel = nameLabel;

    UIButton *editButton = [UIButton buttonWithType:UIButtonTypeCustom];
    editButton.translatesAutoresizingMaskIntoConstraints = NO;
    [editButton setTitle:@"Edit" forState:UIControlStateNormal];
    [editButton setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    editButton.titleLabel.font = [UIFont systemFontOfSize:15.0 weight:UIFontWeightBold];
    editButton.layer.cornerRadius = 19.0;
    editButton.layer.borderWidth = 2.0;
    editButton.layer.borderColor = UIColor.whiteColor.CGColor;
    [editButton addTarget:self action:@selector(yk_editTapped:) forControlEvents:UIControlEventTouchUpInside];
    [pageContentView addSubview:editButton];

    UIImageView *balanceImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"mine_balance_banner"]];
    balanceImageView.translatesAutoresizingMaskIntoConstraints = NO;
    balanceImageView.contentMode = UIViewContentModeScaleAspectFit;
    balanceImageView.userInteractionEnabled = YES;
    [pageContentView addSubview:balanceImageView];

    UILabel *tallyValueLabel = [[UILabel alloc] init];
    tallyValueLabel.translatesAutoresizingMaskIntoConstraints = NO;
    tallyValueLabel.text = @"0";
    tallyValueLabel.textColor = UIColor.whiteColor;
    tallyValueLabel.font = [UIFont systemFontOfSize:27.0 weight:UIFontWeightBold];
    [balanceImageView addSubview:tallyValueLabel];
    self.yk_tallyValueLabel = tallyValueLabel;

    UILabel *balanceTitleLabel = [[UILabel alloc] init];
    balanceTitleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    balanceTitleLabel.text = @"Balance";
    balanceTitleLabel.textColor = UIColor.whiteColor;
    balanceTitleLabel.font = [UIFont systemFontOfSize:16.0 weight:UIFontWeightRegular];
    [balanceImageView addSubview:balanceTitleLabel];

    UIButton *balanceHit = [UIButton buttonWithType:UIButtonTypeCustom];
    balanceHit.translatesAutoresizingMaskIntoConstraints = NO;
    balanceHit.backgroundColor = UIColor.clearColor;
    [balanceHit addTarget:self action:@selector(yk_rechargeTapped:) forControlEvents:UIControlEventTouchUpInside];
    [balanceImageView addSubview:balanceHit];

    UIView *segmentContainer = [[UIView alloc] init];
    segmentContainer.translatesAutoresizingMaskIntoConstraints = NO;
    [pageContentView addSubview:segmentContainer];

    UIStackView *stackView = [[UIStackView alloc] init];
    stackView.translatesAutoresizingMaskIntoConstraints = NO;
    stackView.axis = UILayoutConstraintAxisHorizontal;
    stackView.alignment = UIStackViewAlignmentCenter;
    stackView.distribution = UIStackViewDistributionFillEqually;
    [segmentContainer addSubview:stackView];

    for (NSInteger index = 0; index < self.segmentTitles.count; index++) {
        YKMineSegmentButton *button = [[YKMineSegmentButton alloc] initWithTitle:self.segmentTitles[index]];
        button.tag = index;
        [button addTarget:self action:@selector(yk_segmentButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
        [stackView addArrangedSubview:button];
        [self.segmentButtons addObject:button];
    }

    UIView *indicatorView = [[UIView alloc] init];
    indicatorView.translatesAutoresizingMaskIntoConstraints = NO;
    indicatorView.backgroundColor = UIColor.whiteColor;
    indicatorView.layer.cornerRadius = 2.0;
    indicatorView.layer.masksToBounds = YES;
    [segmentContainer addSubview:indicatorView];
    self.indicatorView = indicatorView;
    self.indicatorLeadingConstraint = [indicatorView.leadingAnchor constraintEqualToAnchor:segmentContainer.leadingAnchor constant:0.0];
    self.indicatorWidthConstraint = [indicatorView.widthAnchor constraintEqualToConstant:170.0];

    UIScrollView *pagerScrollView = [[UIScrollView alloc] init];
    pagerScrollView.translatesAutoresizingMaskIntoConstraints = NO;
    pagerScrollView.pagingEnabled = YES;
    pagerScrollView.showsHorizontalScrollIndicator = NO;
    pagerScrollView.showsVerticalScrollIndicator = NO;
    pagerScrollView.delegate = self;
    pagerScrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    [pageContentView addSubview:pagerScrollView];
    self.contentScrollView = pagerScrollView;

    UIView *pagerContentView = [[UIView alloc] init];
    pagerContentView.translatesAutoresizingMaskIntoConstraints = NO;
    [pagerScrollView addSubview:pagerContentView];

    UICollectionView *entriesCollectionView = [self yk_collectionViewWithTag:0];
    UICollectionView *collectionsCollectionView = [self yk_collectionViewWithTag:1];
    [pagerContentView addSubview:entriesCollectionView];
    [pagerContentView addSubview:collectionsCollectionView];
    self.entriesCollectionView = entriesCollectionView;
    self.collectionsCollectionView = collectionsCollectionView;

    YKEmptyStateView *postsEmpty = [[YKEmptyStateView alloc] init];
    YKEmptyStateView *collectionsEmpty = [[YKEmptyStateView alloc] init];
    [pagerContentView addSubview:postsEmpty];
    [pagerContentView addSubview:collectionsEmpty];
    self.yk_entriesEmptyView = postsEmpty;
    self.yk_collectionsEmptyView = collectionsEmpty;
    [NSLayoutConstraint activateConstraints:@[
        [postsEmpty.centerXAnchor constraintEqualToAnchor:entriesCollectionView.centerXAnchor],
        [postsEmpty.topAnchor constraintEqualToAnchor:entriesCollectionView.topAnchor constant:40.0],
        [postsEmpty.widthAnchor constraintEqualToConstant:200.0],
        [collectionsEmpty.centerXAnchor constraintEqualToAnchor:collectionsCollectionView.centerXAnchor],
        [collectionsEmpty.topAnchor constraintEqualToAnchor:collectionsCollectionView.topAnchor constant:40.0],
        [collectionsEmpty.widthAnchor constraintEqualToConstant:200.0]
    ]];

    self.pagerHeightConstraint = [pagerScrollView.heightAnchor constraintEqualToConstant:400.0];

    [NSLayoutConstraint activateConstraints:@[
        [pageScrollView.topAnchor constraintEqualToAnchor:self.settingsButton.bottomAnchor constant:12.0],
        [pageScrollView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [pageScrollView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [pageScrollView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor constant:-92.0],

        [pageContentView.topAnchor constraintEqualToAnchor:pageScrollView.contentLayoutGuide.topAnchor],
        [pageContentView.leadingAnchor constraintEqualToAnchor:pageScrollView.contentLayoutGuide.leadingAnchor],
        [pageContentView.trailingAnchor constraintEqualToAnchor:pageScrollView.contentLayoutGuide.trailingAnchor],
        [pageContentView.bottomAnchor constraintEqualToAnchor:pageScrollView.contentLayoutGuide.bottomAnchor],
        [pageContentView.widthAnchor constraintEqualToAnchor:pageScrollView.frameLayoutGuide.widthAnchor],

        [avatarImageView.topAnchor constraintEqualToAnchor:pageContentView.topAnchor constant:8.0],
        [avatarImageView.leadingAnchor constraintEqualToAnchor:pageContentView.leadingAnchor constant:26.0],
        [avatarImageView.widthAnchor constraintEqualToConstant:100.0],
        [avatarImageView.heightAnchor constraintEqualToConstant:100.0],

        [inboundValueLabel.leadingAnchor constraintEqualToAnchor:avatarImageView.trailingAnchor constant:30.0],
        [inboundValueLabel.topAnchor constraintEqualToAnchor:avatarImageView.topAnchor constant:26.0],
        [inboundTitleLabel.leadingAnchor constraintEqualToAnchor:inboundValueLabel.leadingAnchor],
        [inboundTitleLabel.topAnchor constraintEqualToAnchor:inboundValueLabel.bottomAnchor constant:3.0],

        [outboundValueLabel.leadingAnchor constraintEqualToAnchor:inboundValueLabel.trailingAnchor constant:68.0],
        [outboundValueLabel.centerYAnchor constraintEqualToAnchor:inboundValueLabel.centerYAnchor],
        [outboundTitleLabel.leadingAnchor constraintEqualToAnchor:outboundValueLabel.leadingAnchor],
        [outboundTitleLabel.topAnchor constraintEqualToAnchor:outboundValueLabel.bottomAnchor constant:3.0],

        [inboundHit.topAnchor constraintEqualToAnchor:inboundValueLabel.topAnchor],
        [inboundHit.leadingAnchor constraintEqualToAnchor:inboundValueLabel.leadingAnchor],
        [inboundHit.trailingAnchor constraintEqualToAnchor:inboundTitleLabel.trailingAnchor],
        [inboundHit.bottomAnchor constraintEqualToAnchor:inboundTitleLabel.bottomAnchor],

        [outboundHit.topAnchor constraintEqualToAnchor:outboundValueLabel.topAnchor],
        [outboundHit.leadingAnchor constraintEqualToAnchor:outboundValueLabel.leadingAnchor],
        [outboundHit.trailingAnchor constraintEqualToAnchor:outboundTitleLabel.trailingAnchor],
        [outboundHit.bottomAnchor constraintEqualToAnchor:outboundTitleLabel.bottomAnchor],

        [nameLabel.topAnchor constraintEqualToAnchor:avatarImageView.bottomAnchor constant:12.0],
        [nameLabel.leadingAnchor constraintEqualToAnchor:pageContentView.leadingAnchor constant:38.0],

        [editButton.centerYAnchor constraintEqualToAnchor:nameLabel.centerYAnchor],
        [editButton.trailingAnchor constraintEqualToAnchor:pageContentView.trailingAnchor constant:-28.0],
        [editButton.widthAnchor constraintEqualToConstant:78.0],
        [editButton.heightAnchor constraintEqualToConstant:38.0],

        [balanceImageView.topAnchor constraintEqualToAnchor:nameLabel.bottomAnchor constant:28.0],
        [balanceImageView.leadingAnchor constraintEqualToAnchor:pageContentView.leadingAnchor constant:26.0],
        [balanceImageView.trailingAnchor constraintEqualToAnchor:pageContentView.trailingAnchor constant:-26.0],
        [balanceImageView.heightAnchor constraintEqualToAnchor:balanceImageView.widthAnchor multiplier:258.0 / 969.0],

        [tallyValueLabel.leadingAnchor constraintEqualToAnchor:balanceImageView.leadingAnchor constant:46.0],
        [tallyValueLabel.topAnchor constraintEqualToAnchor:balanceImageView.topAnchor constant:20.0],
        [balanceTitleLabel.leadingAnchor constraintEqualToAnchor:tallyValueLabel.leadingAnchor],
        [balanceTitleLabel.topAnchor constraintEqualToAnchor:tallyValueLabel.bottomAnchor constant:1.0],

        [balanceHit.topAnchor constraintEqualToAnchor:balanceImageView.topAnchor],
        [balanceHit.leadingAnchor constraintEqualToAnchor:balanceImageView.leadingAnchor],
        [balanceHit.trailingAnchor constraintEqualToAnchor:balanceImageView.trailingAnchor],
        [balanceHit.bottomAnchor constraintEqualToAnchor:balanceImageView.bottomAnchor],

        [segmentContainer.topAnchor constraintEqualToAnchor:balanceImageView.bottomAnchor constant:18.0],
        [segmentContainer.leadingAnchor constraintEqualToAnchor:pageContentView.leadingAnchor constant:28.0],
        [segmentContainer.trailingAnchor constraintEqualToAnchor:pageContentView.trailingAnchor constant:-28.0],
        [segmentContainer.heightAnchor constraintEqualToConstant:58.0],

        [stackView.topAnchor constraintEqualToAnchor:segmentContainer.topAnchor],
        [stackView.leadingAnchor constraintEqualToAnchor:segmentContainer.leadingAnchor],
        [stackView.trailingAnchor constraintEqualToAnchor:segmentContainer.trailingAnchor],
        [stackView.heightAnchor constraintEqualToConstant:40.0],

        self.indicatorLeadingConstraint,
        [indicatorView.topAnchor constraintEqualToAnchor:stackView.bottomAnchor constant:4.0],
        self.indicatorWidthConstraint,
        [indicatorView.heightAnchor constraintEqualToConstant:4.0],

        [pagerScrollView.topAnchor constraintEqualToAnchor:segmentContainer.bottomAnchor constant:2.0],
        [pagerScrollView.leadingAnchor constraintEqualToAnchor:pageContentView.leadingAnchor],
        [pagerScrollView.trailingAnchor constraintEqualToAnchor:pageContentView.trailingAnchor],
        [pagerScrollView.bottomAnchor constraintEqualToAnchor:pageContentView.bottomAnchor],
        self.pagerHeightConstraint,

        [pagerContentView.topAnchor constraintEqualToAnchor:pagerScrollView.contentLayoutGuide.topAnchor],
        [pagerContentView.leadingAnchor constraintEqualToAnchor:pagerScrollView.contentLayoutGuide.leadingAnchor],
        [pagerContentView.trailingAnchor constraintEqualToAnchor:pagerScrollView.contentLayoutGuide.trailingAnchor],
        [pagerContentView.bottomAnchor constraintEqualToAnchor:pagerScrollView.contentLayoutGuide.bottomAnchor],
        [pagerContentView.heightAnchor constraintEqualToAnchor:pagerScrollView.frameLayoutGuide.heightAnchor],

        [entriesCollectionView.topAnchor constraintEqualToAnchor:pagerContentView.topAnchor],
        [entriesCollectionView.leadingAnchor constraintEqualToAnchor:pagerContentView.leadingAnchor],
        [entriesCollectionView.bottomAnchor constraintEqualToAnchor:pagerContentView.bottomAnchor],
        [entriesCollectionView.widthAnchor constraintEqualToAnchor:pagerScrollView.frameLayoutGuide.widthAnchor],

        [collectionsCollectionView.topAnchor constraintEqualToAnchor:pagerContentView.topAnchor],
        [collectionsCollectionView.leadingAnchor constraintEqualToAnchor:entriesCollectionView.trailingAnchor],
        [collectionsCollectionView.bottomAnchor constraintEqualToAnchor:pagerContentView.bottomAnchor],
        [collectionsCollectionView.widthAnchor constraintEqualToAnchor:pagerScrollView.frameLayoutGuide.widthAnchor],
        [collectionsCollectionView.trailingAnchor constraintEqualToAnchor:pagerContentView.trailingAnchor]
    ]];

    [self.view bringSubviewToFront:self.settingsButton];
}

- (UILabel *)yk_countLabelWithText:(NSString *)text {
    UILabel *label = [[UILabel alloc] init];
    label.translatesAutoresizingMaskIntoConstraints = NO;
    label.text = text;
    label.textColor = UIColor.whiteColor;
    label.font = [UIFont systemFontOfSize:23.0 weight:UIFontWeightBold];
    return label;
}

- (UILabel *)yk_captionLabelWithText:(NSString *)text {
    UILabel *label = [[UILabel alloc] init];
    label.translatesAutoresizingMaskIntoConstraints = NO;
    label.text = text;
    label.textColor = [UIColor colorWithWhite:1.0 alpha:0.76];
    label.font = [UIFont systemFontOfSize:15.0 weight:UIFontWeightRegular];
    return label;
}

- (UICollectionView *)yk_collectionViewWithTag:(NSInteger)tag {
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.scrollDirection = UICollectionViewScrollDirectionVertical;
    layout.minimumLineSpacing = tag == 0 ? 18.0 : 14.0;
    layout.minimumInteritemSpacing = 14.0;

    UICollectionView *collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
    collectionView.translatesAutoresizingMaskIntoConstraints = NO;
    collectionView.backgroundColor = UIColor.clearColor;
    collectionView.showsVerticalScrollIndicator = NO;
    collectionView.scrollEnabled = NO;
    collectionView.dataSource = self;
    collectionView.delegate = self;
    collectionView.tag = tag;
    collectionView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    if (tag == 0) {
        [collectionView registerClass:YKMinePostCell.class forCellWithReuseIdentifier:@"YKMinePostCell"];
    } else {
        [collectionView registerClass:YKMineCollectionCell.class forCellWithReuseIdentifier:@"YKMineCollectionCell"];
    }
    return collectionView;
}

- (CGFloat)yk_emptyPagerHeight {
    // One-screen leftover under the segment: page viewport minus header above the pager.
    CGFloat viewport = CGRectGetHeight(self.pageScrollView.bounds);
    if (viewport <= 1.0) {
        return 280.0;
    }
    CGFloat pagerTop = CGRectGetMinY(self.contentScrollView.frame);
    if (pagerTop < 40.0) {
        // Before first layout of page content, approximate header (avatar…segment).
        pagerTop = 340.0;
    }
    return MAX(viewport - pagerTop, 220.0);
}

- (CGFloat)yk_postItemHeightForWidth:(CGFloat)itemWidth {
    CGFloat photoWidth = MAX(itemWidth - 36.0, 1.0);
    CGFloat photoHeight = floor(photoWidth * 0.83);
    // top + avatar + gap + photo + gap + stats + bottom
    return 14.0 + 36.0 + 16.0 + photoHeight + 10.0 + 18.0 + 14.0;
}

- (CGFloat)yk_contentHeightForCollectionTag:(NSInteger)tag width:(CGFloat)width {
    if (width <= 0.0) {
        return 0.0;
    }
    if (tag == 0) {
        NSInteger count = (NSInteger)self.myPosts.count;
        if (count <= 0) {
            return [self yk_emptyPagerHeight];
        }
        CGFloat itemWidth = width - 52.0;
        CGFloat itemHeight = [self yk_postItemHeightForWidth:itemWidth];
        return 18.0 + count * itemHeight + MAX(0, count - 1) * 18.0;
    }

    NSInteger count = (NSInteger)self.myCollections.count;
    if (count <= 0) {
        return [self yk_emptyPagerHeight];
    }
    CGFloat itemWidth = floor((width - 28.0 * 2.0 - 14.0) / 2.0);
    CGFloat itemHeight = itemWidth * 1.09;
    NSInteger rows = (count + 1) / 2;
    return 18.0 + rows * itemHeight + MAX(0, rows - 1) * 14.0;
}

- (void)yk_updatePagerHeightIfNeeded {
    CGFloat width = CGRectGetWidth(self.contentScrollView.bounds);
    if (width <= 0.0) {
        return;
    }
    // Height follows the visible tab only — empty Collections must not inherit Posts height.
    CGFloat targetHeight = [self yk_contentHeightForCollectionTag:self.selectedIndex width:width];
    if (fabs(self.pagerHeightConstraint.constant - targetHeight) > 0.5) {
        self.pagerHeightConstraint.constant = targetHeight;
        [self.view layoutIfNeeded];
        // After shrinking (e.g. Posts → empty Collections), clamp outer scroll so nodata stays on screen.
        CGFloat maxY = MAX(0.0, self.pageScrollView.contentSize.height - CGRectGetHeight(self.pageScrollView.bounds));
        if (self.pageScrollView.contentOffset.y > maxY) {
            [self.pageScrollView setContentOffset:CGPointMake(0.0, maxY) animated:NO];
        }
    }
}

- (void)yk_segmentButtonTapped:(YKMineSegmentButton *)sender {
    if (sender.tag == 1) {
        [self yk_refreshFavoredCollections];
        [self.collectionsCollectionView reloadData];
        [self yk_updateMineEmptyStates];
    }
    self.selectedIndex = sender.tag;
    CGFloat targetX = CGRectGetWidth(self.contentScrollView.bounds) * sender.tag;
    [self.contentScrollView setContentOffset:CGPointMake(targetX, 0.0) animated:YES];
    BOOL emptyTab = (sender.tag == 0) ? (self.myPosts.count == 0) : (self.myCollections.count == 0);
    if (emptyTab && self.pageScrollView.contentOffset.y > 0.0) {
        [self.pageScrollView setContentOffset:CGPointZero animated:YES];
    }
    [self yk_updatePagerHeightIfNeeded];
    [UIView animateWithDuration:0.22 animations:^{
        [self yk_updateSelectionWithProgress:(CGFloat)sender.tag];
        [self.view layoutIfNeeded];
    }];
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return collectionView.tag == 0 ? (NSInteger)self.myPosts.count : (NSInteger)self.myCollections.count;
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    if (collectionView.tag == 0) {
        YKMinePostCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"YKMinePostCell" forIndexPath:indexPath];
        NSDictionary *entry = self.myPosts[indexPath.item];
        YKRosterVault *vault = YKRosterVault.sharedRoster;
        NSString *displayName = [vault yk_displayNameForActiveMailbox] ?: entry[@"name"];
        UIImage *avatar = [vault yk_portraitImageForActiveMailbox];
        if (!avatar) {
            avatar = [YKPersonaCatalog yk_avatarImageForPersonaId:entry[@"personaId"]];
        }
        [cell configureWithEntry:entry
                    displayName:displayName
                         avatar:avatar
                       ownerKey:[self yk_ownerKey]];
        return cell;
    }

    if (indexPath.item < 0 || indexPath.item >= (NSInteger)self.myCollections.count) {
        return [collectionView dequeueReusableCellWithReuseIdentifier:@"YKMineCollectionCell" forIndexPath:indexPath];
    }
    YKMineCollectionCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"YKMineCollectionCell" forIndexPath:indexPath];
    [cell configureWithEntry:self.myCollections[indexPath.item]];
    return cell;
}

- (void)yk_updateMineEmptyStates {
    BOOL postsEmpty = self.myPosts.count == 0;
    BOOL collectionsEmpty = self.myCollections.count == 0;
    self.yk_entriesEmptyView.hidden = !postsEmpty;
    self.yk_collectionsEmptyView.hidden = !collectionsEmpty;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (collectionView.tag == 0) {
        if (indexPath.item < 0 || indexPath.item >= (NSInteger)self.myPosts.count) {
            return;
        }
        NSMutableDictionary *post = [self.myPosts[indexPath.item] mutableCopy];
        post[@"isMine"] = @YES;
        YKRosterVault *vault = YKRosterVault.sharedRoster;
        NSString *displayName = [vault yk_displayNameForActiveMailbox];
        if (displayName.length > 0) {
            post[@"name"] = displayName;
        }
        YKFindDetailViewController *detail = [[YKFindDetailViewController alloc] initWithEntry:post];
        [self.navigationController pushViewController:detail animated:YES];
        return;
    }

    if (indexPath.item < 0 || indexPath.item >= (NSInteger)self.myCollections.count) {
        return;
    }
    YKFindDetailViewController *detail = [[YKFindDetailViewController alloc] initWithEntry:self.myCollections[indexPath.item]];
    [self.navigationController pushViewController:detail animated:YES];
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    CGFloat width = CGRectGetWidth(collectionView.bounds);
    if (collectionView.tag == 0) {
        CGFloat itemWidth = width - 52.0;
        return CGSizeMake(itemWidth, [self yk_postItemHeightForWidth:itemWidth]);
    }

    CGFloat itemWidth = floor((width - 28.0 * 2.0 - 14.0) / 2.0);
    return CGSizeMake(itemWidth, itemWidth * 1.09);
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    return collectionView.tag == 0 ? UIEdgeInsetsMake(0.0, 26.0, 18.0, 26.0) : UIEdgeInsetsMake(0.0, 28.0, 18.0, 28.0);
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (scrollView != self.contentScrollView) {
        return;
    }

    CGFloat width = CGRectGetWidth(scrollView.bounds);
    if (width <= 0.0) {
        return;
    }

    CGFloat progress = MIN(MAX(scrollView.contentOffset.x / width, 0.0), 1.0);
    [self yk_updateSelectionWithProgress:progress];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    if (scrollView == self.contentScrollView) {
        CGFloat width = CGRectGetWidth(scrollView.bounds);
        self.selectedIndex = width > 0.0 ? (NSInteger)lround(scrollView.contentOffset.x / width) : 0;
        if (self.selectedIndex == 1) {
            [self yk_refreshFavoredCollections];
            [self.collectionsCollectionView reloadData];
            [self yk_updateMineEmptyStates];
        }
        [self yk_updateSelectionWithProgress:(CGFloat)self.selectedIndex];
        BOOL emptyTab = (self.selectedIndex == 0) ? (self.myPosts.count == 0) : (self.myCollections.count == 0);
        if (emptyTab && self.pageScrollView.contentOffset.y > 0.0) {
            [self.pageScrollView setContentOffset:CGPointZero animated:YES];
        }
        [self yk_updatePagerHeightIfNeeded];
        [UIView animateWithDuration:0.18 animations:^{
            [self.view layoutIfNeeded];
        }];
    }
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView {
    if (scrollView == self.contentScrollView) {
        CGFloat width = CGRectGetWidth(scrollView.bounds);
        self.selectedIndex = width > 0.0 ? (NSInteger)lround(scrollView.contentOffset.x / width) : self.selectedIndex;
        [self yk_updateSelectionWithProgress:(CGFloat)self.selectedIndex];
        BOOL emptyTab = (self.selectedIndex == 0) ? (self.myPosts.count == 0) : (self.myCollections.count == 0);
        if (emptyTab && self.pageScrollView.contentOffset.y > 0.0) {
            [self.pageScrollView setContentOffset:CGPointZero animated:YES];
        }
        [self yk_updatePagerHeightIfNeeded];
        [UIView animateWithDuration:0.18 animations:^{
            [self.view layoutIfNeeded];
        }];
    }
}

- (void)yk_updateSelectionWithProgress:(CGFloat)progress {
    CGFloat boundedProgress = MIN(MAX(progress, 0.0), 1.0);
    [self.segmentButtons[0] setSelectionProgress:1.0 - boundedProgress];
    [self.segmentButtons[1] setSelectionProgress:boundedProgress];

    YKMineSegmentButton *firstButton = self.segmentButtons.firstObject;
    YKMineSegmentButton *secondButton = self.segmentButtons.lastObject;
    CGFloat firstX = CGRectGetMinX(firstButton.frame);
    CGFloat secondX = CGRectGetMinX(secondButton.frame);
    CGFloat firstWidth = CGRectGetWidth(firstButton.bounds);
    CGFloat secondWidth = CGRectGetWidth(secondButton.bounds);
    self.indicatorLeadingConstraint.constant = firstX + (secondX - firstX) * boundedProgress;
    self.indicatorWidthConstraint.constant = firstWidth + (secondWidth - firstWidth) * boundedProgress;
}

- (void)yk_refreshAccountHeader {
    YKRosterVault *vault = YKRosterVault.sharedRoster;
    self.yk_headerNameLabel.text = [vault yk_displayNameForActiveMailbox] ?: @"Yoka User";
    UIImage *portrait = [vault yk_portraitImageForActiveMailbox];
    if (portrait) {
        self.yk_headerAvatarView.image = portrait;
    } else {
        self.yk_headerAvatarView.image = [UIImage imageNamed:@"headplace"];
    }

    NSString *ownerKey = [YKPersonaCatalog yk_reviewPersonaId];
    NSDictionary *dossier = [vault yk_dossierForActiveMailbox];
    NSString *personaId = dossier[@"personaId"];
    if ([personaId isKindOfClass:NSString.class] && personaId.length > 0) {
        ownerKey = personaId;
    } else if (![YKRosterVault yk_isReviewMailbox:[vault yk_activeMailbox] ?: @""]) {
        ownerKey = [vault yk_activeMailbox] ?: ownerKey;
    }
    NSInteger outboundCount = (NSInteger)[[YKBondLedger sharedLedger] yk_outboundIdsForOwnerKey:ownerKey].count;
    NSInteger inboundCount = (NSInteger)[[YKBondLedger sharedLedger] yk_inboundIdsForOwnerKey:ownerKey].count;
    self.yk_outboundValueLabel.text = [NSString stringWithFormat:@"%ld", (long)outboundCount];
    self.yk_inboundValueLabel.text = [NSString stringWithFormat:@"%ld", (long)inboundCount];
    NSInteger sparkQty = [[YKSparkCoffer sharedCoffer] yk_tallyForOwnerKey:[self yk_ownerKey]];
    self.yk_tallyValueLabel.text = [NSString stringWithFormat:@"%ld", (long)sparkQty];
    [self yk_reloadMyPostsForActiveAccount];
    [self yk_refreshFavoredCollections];
    [self.entriesCollectionView reloadData];
    [self.collectionsCollectionView reloadData];
    [self yk_updateMineEmptyStates];
    [self yk_updatePagerHeightIfNeeded];
}

- (void)yk_inboundTapped:(UIButton *)sender {
    YKBondListViewController *list = [[YKBondListViewController alloc] initWithKind:YKBondListKindInbound];
    [self.navigationController pushViewController:list animated:YES];
}

- (void)yk_outboundTapped:(UIButton *)sender {
    YKBondListViewController *list = [[YKBondListViewController alloc] initWithKind:YKBondListKindOutbound];
    [self.navigationController pushViewController:list animated:YES];
}

- (void)yk_editTapped:(UIButton *)sender {
    YKProfileInfoViewController *profile = [[YKProfileInfoViewController alloc] init];
    profile.yk_firstPassSetup = NO;
    [self.navigationController pushViewController:profile animated:YES];
}

- (void)yk_rechargeTapped:(id)sender {
    [self.navigationController pushViewController:[[YKSparkTopUpViewController alloc] init] animated:YES];
}

- (void)yk_settingsTapped:(UIButton *)sender {
    [self.navigationController pushViewController:[[YKSettingViewController alloc] init] animated:YES];
}

@end
