//
//  YKFindViewController.m
//  Yoka
//

#import "YKFindViewController.h"
#import "YKFindDetailViewController.h"
#import "YKOutfitFeedCatalog.h"
#import "YKFindFavorLedger.h"
#import "YKPublishLedger.h"
#import "YKPersonaCatalog.h"
#import "YKRosterVault.h"
#import "YKBondLedger.h"
#import "YKShadeRoster.h"
#import "YKReportShadeSheet.h"
#import "YKReportViewController.h"
#import "YKEmptyStateView.h"
#import "YKCenterToast.h"
#import <AVFoundation/AVFoundation.h>
#import "YKCipherLoom.h"

@interface YKFindSegmentButton : UIControl

@property (nonatomic, copy, readonly) NSString *title;
@property (nonatomic, assign, readonly) CGFloat selectedTextWidth;

- (instancetype)initWithTitle:(NSString *)title NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithFrame:(CGRect)frame NS_UNAVAILABLE;
- (instancetype)initWithCoder:(NSCoder *)coder NS_UNAVAILABLE;
- (void)setSelectionProgress:(CGFloat)progress;
- (void)setActive:(BOOL)active animated:(BOOL)animated;

@end

@interface YKFindSegmentButton ()

@property (nonatomic, copy) NSString *title;
@property (nonatomic, assign) CGFloat selectedTextWidth;
@property (nonatomic, strong) UILabel *normalLabel;
@property (nonatomic, strong) UIView *gradientTextView;
@property (nonatomic, strong) UILabel *gradientMaskLabel;
@property (nonatomic, strong) CAGradientLayer *gradientLayer;
@property (nonatomic, assign) BOOL active;

@end

@implementation YKFindSegmentButton

- (instancetype)initWithTitle:(NSString *)title {
    self = [super initWithFrame:CGRectZero];
    if (self) {
        _title = [title copy];
        [self yk_setupViews];
    }
    return self;
}

- (void)yk_setupViews {
    self.translatesAutoresizingMaskIntoConstraints = NO;
    self.isAccessibilityElement = YES;
    self.accessibilityLabel = self.title;
    self.accessibilityTraits = UIAccessibilityTraitButton;

    UIFont *normalFont = [UIFont systemFontOfSize:20.0 weight:UIFontWeightRegular];
    UIFont *selectedFont = [UIFont systemFontOfSize:24.0 weight:UIFontWeightBold];
    self.selectedTextWidth = ceil([self.title sizeWithAttributes:@{NSFontAttributeName: selectedFont}].width);

    UILabel *normalLabel = [self yk_labelWithText:self.title font:normalFont];
    normalLabel.textColor = [UIColor colorWithWhite:1.0 alpha:0.48];
    [self addSubview:normalLabel];
    self.normalLabel = normalLabel;

    UIView *gradientTextView = [[UIView alloc] init];
    gradientTextView.translatesAutoresizingMaskIntoConstraints = NO;
    gradientTextView.userInteractionEnabled = NO;
    gradientTextView.alpha = 0.0;
    [self addSubview:gradientTextView];
    self.gradientTextView = gradientTextView;

    CAGradientLayer *gradientLayer = [CAGradientLayer layer];
    gradientLayer.startPoint = CGPointMake(0.0, 0.5);
    gradientLayer.endPoint = CGPointMake(1.0, 0.5);
    gradientLayer.colors = @[
        (__bridge id)UIColor.whiteColor.CGColor,
        (__bridge id)[UIColor colorWithRed:1.0 green:0.0 blue:242.0 / 255.0 alpha:1.0].CGColor
    ];
    [gradientTextView.layer addSublayer:gradientLayer];
    self.gradientLayer = gradientLayer;

    UILabel *gradientMaskLabel = [self yk_labelWithText:self.title font:selectedFont];
    gradientTextView.layer.mask = gradientMaskLabel.layer;
    self.gradientMaskLabel = gradientMaskLabel;

    [NSLayoutConstraint activateConstraints:@[
        [normalLabel.topAnchor constraintEqualToAnchor:self.topAnchor],
        [normalLabel.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
        [normalLabel.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
        [normalLabel.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],

        [gradientTextView.topAnchor constraintEqualToAnchor:self.topAnchor],
        [gradientTextView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
        [gradientTextView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
        [gradientTextView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor]
    ]];
}

- (UILabel *)yk_labelWithText:(NSString *)text font:(UIFont *)font {
    UILabel *label = [[UILabel alloc] init];
    label.translatesAutoresizingMaskIntoConstraints = NO;
    label.text = text;
    label.font = font;
    label.textAlignment = NSTextAlignmentLeft;
    return label;
}

- (CGSize)intrinsicContentSize {
    return CGSizeMake(self.selectedTextWidth, 32.0);
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.gradientLayer.frame = self.gradientTextView.bounds;
    self.gradientMaskLabel.frame = self.gradientTextView.bounds;
}

- (void)setActive:(BOOL)active animated:(BOOL)animated {
    void (^changes)(void) = ^{
        [self setSelectionProgress:active ? 1.0 : 0.0];
    };

    if (animated) {
        [UIView animateWithDuration:0.24 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:changes completion:nil];
    } else {
        changes();
    }
}

- (void)setSelectionProgress:(CGFloat)progress {
    CGFloat boundedProgress = MIN(MAX(progress, 0.0), 1.0);
    _active = boundedProgress >= 0.5;
    self.accessibilityTraits = self.active ? (UIAccessibilityTraitButton | UIAccessibilityTraitSelected) : UIAccessibilityTraitButton;
    self.gradientTextView.alpha = boundedProgress;
    self.normalLabel.alpha = 1.0 - boundedProgress;
}

@end

@class YKFindWaterfallLayout;

@protocol YKFindWaterfallLayoutDelegate <NSObject>

- (CGFloat)waterfallLayout:(YKFindWaterfallLayout *)layout heightForItemAtIndexPath:(NSIndexPath *)indexPath itemWidth:(CGFloat)itemWidth;

@end

@interface YKFindWaterfallLayout : UICollectionViewLayout

@property (nonatomic, weak) id<YKFindWaterfallLayoutDelegate> delegate;
@property (nonatomic, assign) NSInteger columnCount;
@property (nonatomic, assign) CGFloat columnSpacing;
@property (nonatomic, assign) CGFloat rowSpacing;
@property (nonatomic, assign) UIEdgeInsets sectionInset;

@end

@interface YKFindWaterfallLayout ()

@property (nonatomic, strong) NSMutableArray<UICollectionViewLayoutAttributes *> *cachedAttributes;
@property (nonatomic, assign) CGSize contentSize;

@end

@implementation YKFindWaterfallLayout

- (instancetype)init {
    self = [super init];
    if (self) {
        _columnCount = 2;
        _columnSpacing = 14.0;
        _rowSpacing = 14.0;
        _sectionInset = UIEdgeInsetsMake(0.0, 20.0, 18.0, 20.0);
        _cachedAttributes = [NSMutableArray array];
    }
    return self;
}

- (void)prepareLayout {
    [super prepareLayout];
    [self.cachedAttributes removeAllObjects];

    NSInteger itemCount = [self.collectionView numberOfItemsInSection:0];
    if (itemCount <= 0 || self.columnCount <= 0) {
        self.contentSize = self.collectionView.bounds.size;
        return;
    }

    CGFloat contentWidth = CGRectGetWidth(self.collectionView.bounds) - self.sectionInset.left - self.sectionInset.right;
    CGFloat itemWidth = floor((contentWidth - self.columnSpacing * (CGFloat)(self.columnCount - 1)) / (CGFloat)self.columnCount);
    NSMutableArray<NSNumber *> *columnHeights = [NSMutableArray arrayWithCapacity:self.columnCount];
    for (NSInteger column = 0; column < self.columnCount; column++) {
        [columnHeights addObject:@(self.sectionInset.top)];
    }

    for (NSInteger item = 0; item < itemCount; item++) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:item inSection:0];
        NSInteger targetColumn = 0;
        CGFloat minHeight = columnHeights.firstObject.doubleValue;
        for (NSInteger column = 1; column < self.columnCount; column++) {
            CGFloat height = columnHeights[column].doubleValue;
            if (height < minHeight) {
                minHeight = height;
                targetColumn = column;
            }
        }

        CGFloat itemHeight = [self.delegate waterfallLayout:self heightForItemAtIndexPath:indexPath itemWidth:itemWidth];
        CGFloat x = self.sectionInset.left + (itemWidth + self.columnSpacing) * (CGFloat)targetColumn;
        CGFloat y = minHeight;
        UICollectionViewLayoutAttributes *attributes = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:indexPath];
        attributes.frame = CGRectMake(x, y, itemWidth, itemHeight);
        [self.cachedAttributes addObject:attributes];
        columnHeights[targetColumn] = @(CGRectGetMaxY(attributes.frame) + self.rowSpacing);
    }

    CGFloat maxHeight = columnHeights.firstObject.doubleValue;
    for (NSNumber *height in columnHeights) {
        maxHeight = MAX(maxHeight, height.doubleValue);
    }
    maxHeight = maxHeight - self.rowSpacing + self.sectionInset.bottom;
    self.contentSize = CGSizeMake(CGRectGetWidth(self.collectionView.bounds), maxHeight);
}

- (CGSize)collectionViewContentSize {
    return self.contentSize;
}

- (NSArray<UICollectionViewLayoutAttributes *> *)layoutAttributesForElementsInRect:(CGRect)rect {
    NSMutableArray<UICollectionViewLayoutAttributes *> *visibleAttributes = [NSMutableArray array];
    for (UICollectionViewLayoutAttributes *attributes in self.cachedAttributes) {
        if (CGRectIntersectsRect(attributes.frame, rect)) {
            [visibleAttributes addObject:attributes];
        }
    }
    return visibleAttributes;
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.item < self.cachedAttributes.count) {
        return self.cachedAttributes[indexPath.item];
    }
    return nil;
}

- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds {
    return !CGSizeEqualToSize(newBounds.size, self.collectionView.bounds.size);
}

@end

@interface YKFindDiscoverCell : UICollectionViewCell

@property (nonatomic, copy, nullable) void (^yk_moreTapHandler)(NSDictionary *entry);

- (void)configureWithEntry:(NSDictionary *)post ownerKey:(NSString *)ownerKey;

@end

@interface YKFindDiscoverCell ()

@property (nonatomic, strong) UIImageView *coverImageView;
@property (nonatomic, strong) CAGradientLayer *overlayLayer;
@property (nonatomic, strong) UIImageView *avatarImageView;
@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) UILabel *descLabel;
@property (nonatomic, strong) UIButton *favorButton;
@property (nonatomic, strong) UIButton *moreButton;
@property (nonatomic, copy) NSDictionary *yk_entry;
@property (nonatomic, copy) NSString *yk_ownerKey;
@property (nonatomic, copy) NSString *yk_videoToken;

@end

@implementation YKFindDiscoverCell

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self yk_setupViews];
    }
    return self;
}

- (void)yk_setupViews {
    self.contentView.layer.cornerRadius = 12.0;
    self.contentView.layer.masksToBounds = YES;
    self.contentView.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.12];

    UIImageView *coverImageView = [[UIImageView alloc] init];
    coverImageView.translatesAutoresizingMaskIntoConstraints = NO;
    coverImageView.contentMode = UIViewContentModeScaleAspectFill;
    coverImageView.clipsToBounds = YES;
    [self.contentView addSubview:coverImageView];
    self.coverImageView = coverImageView;

    CAGradientLayer *overlayLayer = [CAGradientLayer layer];
    overlayLayer.colors = @[
        (__bridge id)[UIColor colorWithWhite:0.0 alpha:0.0].CGColor,
        (__bridge id)[UIColor colorWithWhite:0.0 alpha:0.66].CGColor
    ];
    overlayLayer.locations = @[@0.45, @1.0];
    [self.contentView.layer addSublayer:overlayLayer];
    self.overlayLayer = overlayLayer;

    UIButton *moreButton = [UIButton buttonWithType:UIButtonTypeCustom];
    moreButton.translatesAutoresizingMaskIntoConstraints = NO;
    [moreButton setImage:[[UIImage imageNamed:@"nav_more"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] forState:UIControlStateNormal];
    [moreButton addTarget:self action:@selector(yk_moreTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.contentView addSubview:moreButton];
    self.moreButton = moreButton;

    UIImageView *avatarImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"headplace"]];
    avatarImageView.translatesAutoresizingMaskIntoConstraints = NO;
    avatarImageView.contentMode = UIViewContentModeScaleAspectFill;
    avatarImageView.layer.cornerRadius = 10.0;
    avatarImageView.layer.masksToBounds = YES;
    [self.contentView addSubview:avatarImageView];
    self.avatarImageView = avatarImageView;

    UILabel *nameLabel = [[UILabel alloc] init];
    nameLabel.translatesAutoresizingMaskIntoConstraints = NO;
    nameLabel.textColor = UIColor.whiteColor;
    nameLabel.font = [UIFont systemFontOfSize:12.0 weight:UIFontWeightBold];
    [self.contentView addSubview:nameLabel];
    self.nameLabel = nameLabel;

    UILabel *descLabel = [[UILabel alloc] init];
    descLabel.translatesAutoresizingMaskIntoConstraints = NO;
    descLabel.textColor = [UIColor colorWithWhite:1.0 alpha:0.82];
    descLabel.font = [UIFont systemFontOfSize:10.0 weight:UIFontWeightRegular];
    descLabel.numberOfLines = 2;
    [self.contentView addSubview:descLabel];
    self.descLabel = descLabel;

    UIButton *favorBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    favorBtn.translatesAutoresizingMaskIntoConstraints = NO;
    favorBtn.backgroundColor = UIColor.clearColor;
    favorBtn.imageView.contentMode = UIViewContentModeScaleAspectFit;
    [favorBtn addTarget:self action:@selector(yk_favorTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.contentView addSubview:favorBtn];
    self.favorButton = favorBtn;

    [NSLayoutConstraint activateConstraints:@[
        [coverImageView.topAnchor constraintEqualToAnchor:self.contentView.topAnchor],
        [coverImageView.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor],
        [coverImageView.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor],
        [coverImageView.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor],

        [moreButton.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:8.0],
        [moreButton.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-8.0],
        [moreButton.widthAnchor constraintEqualToConstant:28.0],
        [moreButton.heightAnchor constraintEqualToConstant:28.0],

        [avatarImageView.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:10.0],
        [avatarImageView.bottomAnchor constraintEqualToAnchor:nameLabel.bottomAnchor constant:2.0],
        [avatarImageView.widthAnchor constraintEqualToConstant:20.0],
        [avatarImageView.heightAnchor constraintEqualToConstant:20.0],

        [nameLabel.leadingAnchor constraintEqualToAnchor:avatarImageView.trailingAnchor constant:5.0],
        [nameLabel.trailingAnchor constraintLessThanOrEqualToAnchor:favorBtn.leadingAnchor constant:-8.0],
        [nameLabel.bottomAnchor constraintEqualToAnchor:descLabel.topAnchor constant:-2.0],

        [descLabel.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:10.0],
        [descLabel.trailingAnchor constraintLessThanOrEqualToAnchor:favorBtn.leadingAnchor constant:-8.0],
        [descLabel.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor constant:-12.0],

        [favorBtn.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-8.0],
        [favorBtn.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor constant:-8.0],
        [favorBtn.widthAnchor constraintEqualToConstant:24.0],
        [favorBtn.heightAnchor constraintEqualToConstant:24.0]
    ]];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.overlayLayer.frame = self.contentView.bounds;
}

- (void)prepareForReuse {
    [super prepareForReuse];
    self.nameLabel.text = nil;
    self.descLabel.text = nil;
    self.coverImageView.image = nil;
    self.yk_videoToken = nil;
    self.yk_entry = nil;
    self.yk_ownerKey = nil;
    self.yk_moreTapHandler = nil;
    self.moreButton.hidden = NO;
    self.avatarImageView.image = [UIImage imageNamed:@"headplace"];
}

- (void)yk_moreTapped:(UIButton *)sender {
    if (self.yk_moreTapHandler && self.yk_entry) {
        self.yk_moreTapHandler(self.yk_entry);
    }
}

- (void)yk_refreshFavorAppearance {
    YKFindFavorLedger *ledger = [YKFindFavorLedger sharedLedger];
    BOOL favored = [ledger yk_isEntryFavored:self.yk_entry ?: @{} ownerKey:self.yk_ownerKey ?: @""];
    NSString *iconName = favored ? [ledger yk_favoredStarImageName] : [ledger yk_unfavoredStarImageName];
    [self.favorButton setImage:[[UIImage imageNamed:iconName] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]
                     forState:UIControlStateNormal];
}

- (void)yk_favorTapped:(UIButton *)sender {
    if (!self.yk_entry || self.yk_ownerKey.length == 0) {
        return;
    }
    YKFindFavorLedger *ledger = [YKFindFavorLedger sharedLedger];
    BOOL favored = [ledger yk_isEntryFavored:self.yk_entry ownerKey:self.yk_ownerKey];
    [ledger yk_setEntry:self.yk_entry favored:!favored ownerKey:self.yk_ownerKey];
    [self yk_refreshFavorAppearance];
}

- (void)configureWithEntry:(NSDictionary *)post ownerKey:(NSString *)ownerKey {
    self.yk_entry = post;
    self.yk_ownerKey = ownerKey;
    [self yk_refreshFavorAppearance];

    NSString *personaId = post[@"personaId"];
    BOOL isOwn = [post[@"isMine"] boolValue] ||
        ([personaId isKindOfClass:NSString.class] && personaId.length > 0 && [personaId isEqualToString:ownerKey]);
    self.moreButton.hidden = isOwn;
    self.nameLabel.text = post[@"name"];
    self.descLabel.text = post[@"caption"];
    UIImage *avatar = [YKPersonaCatalog yk_avatarImageForPersonaId:personaId];
    if (!avatar && [personaId isKindOfClass:NSString.class] && [personaId isEqualToString:ownerKey]) {
        avatar = [[YKRosterVault sharedRoster] yk_portraitImageForActiveMailbox];
    }
    if (avatar) {
        self.avatarImageView.image = [avatar imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    } else if (isOwn) {
        UIImage *mine = [[YKRosterVault sharedRoster] yk_portraitImageForActiveMailbox];
        self.avatarImageView.image = [(mine ?: [UIImage imageNamed:@"headplace"]) imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    }

    NSString *videoName = post[@"video"];
    NSString *imageName = post[@"image"];
    self.yk_videoToken = videoName.length > 0 ? videoName : (imageName ?: @"");
    self.coverImageView.image = nil;

    if (imageName.length > 0 && videoName.length == 0) {
        self.coverImageView.image = [[UIImage imageNamed:imageName] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
        return;
    }

    UIImage *fileCover = [YKPublishLedger yk_coverImageForEntry:post];
    if (fileCover && videoName.length == 0) {
        self.coverImageView.image = [fileCover imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
        return;
    }

    if (videoName.length == 0) {
        return;
    }
    NSURL *url = [[NSBundle mainBundle] URLForResource:videoName withExtension:@"mp4"];
    if (!url) {
        return;
    }
    NSString *token = videoName;
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        AVAsset *asset = [AVAsset assetWithURL:url];
        AVAssetImageGenerator *generator = [AVAssetImageGenerator assetImageGeneratorWithAsset:asset];
        generator.appliesPreferredTrackTransform = YES;
        generator.maximumSize = CGSizeMake(600.0, 900.0);
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
        });
    });
}

@end

@interface YKFindViewController () <UIScrollViewDelegate, UICollectionViewDataSource, UICollectionViewDelegate, YKFindWaterfallLayoutDelegate>

@property (nonatomic, copy) NSArray<NSString *> *categoryTitles;
@property (nonatomic, strong) UIScrollView *segmentScrollView;
@property (nonatomic, strong) UIStackView *segmentStackView;
@property (nonatomic, strong) NSMutableArray<YKFindSegmentButton *> *segmentButtons;
@property (nonatomic, strong) UIView *tabUnderlineView;
@property (nonatomic, strong) CAGradientLayer *tabUnderlineGradientLayer;
@property (nonatomic, strong) NSLayoutConstraint *tabUnderlineLeadingConstraint;
@property (nonatomic, strong) NSLayoutConstraint *tabUnderlineWidthConstraint;
@property (nonatomic, strong) UIScrollView *contentScrollView;
@property (nonatomic, strong) NSMutableArray<UICollectionView *> *collectionViews;
@property (nonatomic, strong) NSMutableArray<YKEmptyStateView *> *yk_emptyViews;
@property (nonatomic, copy) NSArray<NSDictionary<NSString *, id> *> *outfitItems;
@property (nonatomic, copy) NSArray<NSDictionary<NSString *, id> *> *makeupItems;
@property (nonatomic, copy) NSArray<NSDictionary<NSString *, id> *> *hairItems;
@property (nonatomic, copy) NSArray<NSDictionary<NSString *, id> *> *jewelryItems;
@property (nonatomic, copy) NSArray<NSDictionary<NSString *, id> *> *shoesItems;
@property (nonatomic, assign) NSInteger selectedContentIndex;
@property (nonatomic, copy) NSString *yk_actionPeerId;

@end

@implementation YKFindViewController

- (void)yk_configurePage {
    [super yk_configurePage];

    self.categoryTitles = @[@"Outfit", @"Makeup", @"Hair", @"Jewelry", @"Shoes"];
    self.segmentButtons = [NSMutableArray arrayWithCapacity:self.categoryTitles.count];
    self.collectionViews = [NSMutableArray arrayWithCapacity:self.categoryTitles.count];
    self.yk_emptyViews = [NSMutableArray arrayWithCapacity:self.categoryTitles.count];
    self.selectedContentIndex = 0;

    [self yk_reloadFeedExcludingBlocked];
    [self yk_setupHeaderView];
    [self yk_setupSegmentTabs];
    [self yk_setupContentScrollView];
    [self yk_updateSegmentSelectionAnimated:NO];
    [self yk_updateFindEmptyStates];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self yk_reloadFeedExcludingBlocked];
    for (UICollectionView *collectionView in self.collectionViews) {
        [collectionView reloadData];
        [collectionView.collectionViewLayout invalidateLayout];
    }
    [self yk_updateFindEmptyStates];
}

- (NSString *)yk_ownerKey {
    YKRosterVault *vault = [YKRosterVault sharedRoster];
    if ([YKRosterVault yk_isReviewMailbox:vault.yk_activeMailbox ?: @""]) {
        return [YKPersonaCatalog yk_reviewPersonaId];
    }
    return vault.yk_activeMailbox.length > 0 ? vault.yk_activeMailbox : @"guest";
}

- (NSArray<NSDictionary *> *)yk_filterBlockedFromPosts:(NSArray<NSDictionary *> *)posts {
    NSString *owner = [self yk_ownerKey];
    NSMutableArray *filtered = [NSMutableArray array];
    for (NSDictionary *entry in posts) {
        NSString *personaId = entry[@"personaId"];
        if ([personaId isKindOfClass:NSString.class] &&
            [[YKShadeRoster sharedRoster] yk_ownerKey:owner hasShadedId:personaId]) {
            continue;
        }
        [filtered addObject:entry];
    }
    return filtered;
}

- (void)yk_reloadFeedExcludingBlocked {
    NSMutableArray *outfit = [NSMutableArray array];
    [outfit addObjectsFromArray:[[YKPublishLedger sharedLedger] yk_allPublishedEntries]];
    [outfit addObjectsFromArray:[YKOutfitFeedCatalog yk_outfitPosts]];
    self.outfitItems = [self yk_filterBlockedFromPosts:outfit];
    self.makeupItems = [self yk_filterBlockedFromPosts:[YKOutfitFeedCatalog yk_makeupPosts]];
    self.hairItems = [self yk_filterBlockedFromPosts:[YKOutfitFeedCatalog yk_hairPosts]];
    self.jewelryItems = [self yk_filterBlockedFromPosts:[YKOutfitFeedCatalog yk_jewelryPosts]];
    self.shoesItems = [self yk_filterBlockedFromPosts:[YKOutfitFeedCatalog yk_shoesPosts]];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    self.tabUnderlineGradientLayer.frame = self.tabUnderlineView.bounds;
    if (!self.contentScrollView.isDragging && !self.contentScrollView.isDecelerating) {
        [self yk_updateSegmentSelectionAnimated:NO];
    }
}

- (void)yk_setupHeaderView {
    UIImageView *titleImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Discover"]];
    titleImageView.translatesAutoresizingMaskIntoConstraints = NO;
    titleImageView.contentMode = UIViewContentModeScaleAspectFit;
    [self.view addSubview:titleImageView];

    [NSLayoutConstraint activateConstraints:@[
        [titleImageView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:24.0],
        [titleImageView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:28.0],
        [titleImageView.widthAnchor constraintEqualToConstant:108.0],
        [titleImageView.heightAnchor constraintEqualToConstant:30.0]
    ]];
}

- (void)yk_setupSegmentTabs {
    UIScrollView *segmentScrollView = [[UIScrollView alloc] init];
    segmentScrollView.translatesAutoresizingMaskIntoConstraints = NO;
    segmentScrollView.showsHorizontalScrollIndicator = NO;
    segmentScrollView.showsVerticalScrollIndicator = NO;
    segmentScrollView.backgroundColor = UIColor.clearColor;
    segmentScrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    [self.view addSubview:segmentScrollView];
    self.segmentScrollView = segmentScrollView;

    UIStackView *stackView = [[UIStackView alloc] init];
    stackView.translatesAutoresizingMaskIntoConstraints = NO;
    stackView.axis = UILayoutConstraintAxisHorizontal;
    stackView.alignment = UIStackViewAlignmentCenter;
    stackView.spacing = 14.0;
    [segmentScrollView addSubview:stackView];
    self.segmentStackView = stackView;

    for (NSInteger index = 0; index < self.categoryTitles.count; index++) {
        YKFindSegmentButton *button = [[YKFindSegmentButton alloc] initWithTitle:self.categoryTitles[index]];
        button.tag = index;
        [button addTarget:self action:@selector(yk_segmentButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
        [stackView addArrangedSubview:button];
        [self.segmentButtons addObject:button];

        [NSLayoutConstraint activateConstraints:@[
            [button.heightAnchor constraintEqualToConstant:32.0]
        ]];
    }

    UIView *underlineView = [[UIView alloc] init];
    underlineView.translatesAutoresizingMaskIntoConstraints = NO;
    underlineView.layer.cornerRadius = 2.0;
    underlineView.layer.masksToBounds = YES;
    [segmentScrollView addSubview:underlineView];
    self.tabUnderlineView = underlineView;

    CAGradientLayer *underlineGradientLayer = [CAGradientLayer layer];
    underlineGradientLayer.startPoint = CGPointMake(0.0, 0.5);
    underlineGradientLayer.endPoint = CGPointMake(1.0, 0.5);
    underlineGradientLayer.colors = @[
        (__bridge id)UIColor.whiteColor.CGColor,
        (__bridge id)[UIColor colorWithRed:1.0 green:0.0 blue:242.0 / 255.0 alpha:1.0].CGColor,
        (__bridge id)[UIColor colorWithRed:1.0 green:0.0 blue:242.0 / 255.0 alpha:1.0].CGColor,
        (__bridge id)[UIColor colorWithRed:1.0 green:0.0 blue:242.0 / 255.0 alpha:0.0].CGColor
    ];
    underlineGradientLayer.locations = @[@0.0, @0.5, @0.5, @1.0];
    [underlineView.layer addSublayer:underlineGradientLayer];
    self.tabUnderlineGradientLayer = underlineGradientLayer;

    self.tabUnderlineLeadingConstraint = [underlineView.leadingAnchor constraintEqualToAnchor:segmentScrollView.contentLayoutGuide.leadingAnchor constant:0.0];
    self.tabUnderlineWidthConstraint = [underlineView.widthAnchor constraintEqualToConstant:60.0];

    [NSLayoutConstraint activateConstraints:@[
        [segmentScrollView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:78.0],
        [segmentScrollView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:20.0],
        [segmentScrollView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [segmentScrollView.heightAnchor constraintEqualToConstant:42.0],

        [stackView.topAnchor constraintEqualToAnchor:segmentScrollView.contentLayoutGuide.topAnchor],
        [stackView.leadingAnchor constraintEqualToAnchor:segmentScrollView.contentLayoutGuide.leadingAnchor],
        [stackView.trailingAnchor constraintEqualToAnchor:segmentScrollView.contentLayoutGuide.trailingAnchor constant:-20.0],
        [stackView.heightAnchor constraintEqualToAnchor:segmentScrollView.frameLayoutGuide.heightAnchor],

        self.tabUnderlineLeadingConstraint,
        [underlineView.topAnchor constraintEqualToAnchor:stackView.topAnchor constant:32.0],
        self.tabUnderlineWidthConstraint,
        [underlineView.heightAnchor constraintEqualToConstant:4.0]
    ]];
}

- (void)yk_setupContentScrollView {
    UIScrollView *scrollView = [[UIScrollView alloc] init];
    scrollView.translatesAutoresizingMaskIntoConstraints = NO;
    scrollView.delegate = self;
    scrollView.pagingEnabled = YES;
    scrollView.showsHorizontalScrollIndicator = NO;
    scrollView.showsVerticalScrollIndicator = NO;
    scrollView.bounces = YES;
    scrollView.alwaysBounceHorizontal = YES;
    scrollView.backgroundColor = UIColor.clearColor;
    scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    [self.view addSubview:scrollView];
    self.contentScrollView = scrollView;

    UIView *contentView = [[UIView alloc] init];
    contentView.translatesAutoresizingMaskIntoConstraints = NO;
    [scrollView addSubview:contentView];

    NSMutableArray<UIView *> *pages = [NSMutableArray arrayWithCapacity:self.categoryTitles.count];
    for (NSInteger index = 0; index < self.categoryTitles.count; index++) {
        UIView *pageView = [self yk_categoryPageViewWithIndex:index];
        [contentView addSubview:pageView];
        [pages addObject:pageView];
    }

    NSMutableArray<NSLayoutConstraint *> *constraints = [NSMutableArray arrayWithArray:@[
        [scrollView.topAnchor constraintEqualToAnchor:self.segmentScrollView.bottomAnchor constant:10.0],
        [scrollView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [scrollView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [scrollView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor constant:-92.0],

        [contentView.topAnchor constraintEqualToAnchor:scrollView.contentLayoutGuide.topAnchor],
        [contentView.leadingAnchor constraintEqualToAnchor:scrollView.contentLayoutGuide.leadingAnchor],
        [contentView.trailingAnchor constraintEqualToAnchor:scrollView.contentLayoutGuide.trailingAnchor],
        [contentView.bottomAnchor constraintEqualToAnchor:scrollView.contentLayoutGuide.bottomAnchor],
        [contentView.heightAnchor constraintEqualToAnchor:scrollView.frameLayoutGuide.heightAnchor]
    ]];

    UIView *previousPageView = nil;
    for (UIView *pageView in pages) {
        [constraints addObject:[pageView.topAnchor constraintEqualToAnchor:contentView.topAnchor]];
        [constraints addObject:[pageView.bottomAnchor constraintEqualToAnchor:contentView.bottomAnchor]];
        [constraints addObject:[pageView.widthAnchor constraintEqualToAnchor:scrollView.frameLayoutGuide.widthAnchor]];

        if (previousPageView) {
            [constraints addObject:[pageView.leadingAnchor constraintEqualToAnchor:previousPageView.trailingAnchor]];
        } else {
            [constraints addObject:[pageView.leadingAnchor constraintEqualToAnchor:contentView.leadingAnchor]];
        }
        previousPageView = pageView;
    }
    if (previousPageView) {
        [constraints addObject:[previousPageView.trailingAnchor constraintEqualToAnchor:contentView.trailingAnchor]];
    }

    [NSLayoutConstraint activateConstraints:constraints];
}

- (UIView *)yk_categoryPageViewWithIndex:(NSInteger)index {
    UIView *pageView = [[UIView alloc] init];
    pageView.translatesAutoresizingMaskIntoConstraints = NO;
    pageView.backgroundColor = UIColor.clearColor;

    YKFindWaterfallLayout *layout = [[YKFindWaterfallLayout alloc] init];
    layout.delegate = self;
    layout.columnCount = 2;
    layout.columnSpacing = 14.0;
    layout.rowSpacing = 14.0;
    layout.sectionInset = UIEdgeInsetsMake(0.0, 20.0, 18.0, 20.0);

    UICollectionView *collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
    collectionView.translatesAutoresizingMaskIntoConstraints = NO;
    collectionView.backgroundColor = UIColor.clearColor;
    collectionView.showsVerticalScrollIndicator = NO;
    collectionView.showsHorizontalScrollIndicator = NO;
    collectionView.dataSource = self;
    collectionView.delegate = self;
    collectionView.tag = index;
    collectionView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    [collectionView registerClass:YKFindDiscoverCell.class forCellWithReuseIdentifier:@"YKFindDiscoverCell"];
    [pageView addSubview:collectionView];
    [self.collectionViews addObject:collectionView];

    YKEmptyStateView *emptyView = [[YKEmptyStateView alloc] init];
    [pageView addSubview:emptyView];
    [self.yk_emptyViews addObject:emptyView];

    [NSLayoutConstraint activateConstraints:@[
        [collectionView.topAnchor constraintEqualToAnchor:pageView.topAnchor],
        [collectionView.leadingAnchor constraintEqualToAnchor:pageView.leadingAnchor],
        [collectionView.trailingAnchor constraintEqualToAnchor:pageView.trailingAnchor],
        [collectionView.bottomAnchor constraintEqualToAnchor:pageView.bottomAnchor],

        [emptyView.centerXAnchor constraintEqualToAnchor:pageView.centerXAnchor],
        [emptyView.centerYAnchor constraintEqualToAnchor:pageView.centerYAnchor constant:-24.0],
        [emptyView.widthAnchor constraintEqualToConstant:200.0]
    ]];
    return pageView;
}

- (void)yk_updateFindEmptyStates {
    for (NSInteger index = 0; index < (NSInteger)self.yk_emptyViews.count; index++) {
        BOOL empty = [self yk_itemsForCollectionTag:index].count == 0;
        self.yk_emptyViews[index].hidden = !empty;
        if (index < (NSInteger)self.collectionViews.count) {
            self.collectionViews[index].hidden = empty;
        }
    }
}

- (void)yk_segmentButtonTapped:(YKFindSegmentButton *)sender {
    [self yk_selectContentIndex:sender.tag animated:YES];
}

- (void)yk_selectContentIndex:(NSInteger)index animated:(BOOL)animated {
    if (index < 0 || index >= (NSInteger)self.segmentButtons.count) {
        return;
    }

    self.selectedContentIndex = index;
    [self yk_updateSegmentSelectionAnimated:animated];

    CGFloat targetX = CGRectGetWidth(self.contentScrollView.bounds) * index;
    [self.contentScrollView setContentOffset:CGPointMake(targetX, 0.0) animated:animated];
}

- (void)yk_updateSegmentSelectionAnimated:(BOOL)animated {
    if (self.segmentButtons.count == 0) {
        return;
    }

    YKFindSegmentButton *selectedButton = self.segmentButtons[self.selectedContentIndex];
    [self.segmentButtons enumerateObjectsUsingBlock:^(YKFindSegmentButton *button, NSUInteger idx, BOOL *stop) {
        [button setActive:(NSInteger)idx == self.selectedContentIndex animated:animated];
    }];

    self.tabUnderlineLeadingConstraint.constant = CGRectGetMinX(selectedButton.frame);
    self.tabUnderlineWidthConstraint.constant = CGRectGetWidth(selectedButton.bounds);

    void (^changes)(void) = ^{
        [self.segmentScrollView layoutIfNeeded];
    };

    if (animated) {
        [UIView animateWithDuration:0.22 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:changes completion:nil];
    } else {
        changes();
    }

    [self yk_scrollSelectedSegmentButtonIntoView:selectedButton animated:animated];
}

- (void)yk_scrollSelectedSegmentButtonIntoView:(YKFindSegmentButton *)button animated:(BOOL)animated {
    CGRect buttonRect = [button.superview convertRect:button.frame toView:self.segmentScrollView];
    CGRect targetRect = CGRectInset(buttonRect, -28.0, 0.0);
    [self.segmentScrollView scrollRectToVisible:targetRect animated:animated];
}

- (void)yk_scrollSegmentButtonAtIndexIntoView:(NSInteger)index animated:(BOOL)animated {
    if (index < 0 || index >= (NSInteger)self.segmentButtons.count) {
        return;
    }
    [self yk_scrollSelectedSegmentButtonIntoView:self.segmentButtons[index] animated:animated];
}

- (void)yk_updateSegmentScrollOffsetWithProgress:(CGFloat)progress {
    if (self.segmentButtons.count == 0) {
        return;
    }

    [self.segmentScrollView layoutIfNeeded];
    CGFloat maxOffsetX = MAX(0.0, self.segmentScrollView.contentSize.width - CGRectGetWidth(self.segmentScrollView.bounds));
    if (maxOffsetX <= 0.0) {
        return;
    }

    NSInteger maxIndex = (NSInteger)self.segmentButtons.count - 1;
    CGFloat boundedProgress = MIN(MAX(progress, 0.0), (CGFloat)maxIndex);
    CGFloat targetOffsetX = 0.0;

    if (maxIndex > 0) {
        targetOffsetX = maxOffsetX * (boundedProgress / (CGFloat)maxIndex);
    }

    targetOffsetX = MIN(MAX(targetOffsetX, 0.0), maxOffsetX);
    CGPoint currentOffset = self.segmentScrollView.contentOffset;
    if (fabs(currentOffset.x - targetOffsetX) > 0.5) {
        self.segmentScrollView.contentOffset = CGPointMake(targetOffsetX, currentOffset.y);
    }
}

- (NSArray<NSDictionary<NSString *, id> *> *)yk_itemsForCollectionTag:(NSInteger)tag {
    if (tag == 0) {
        return self.outfitItems;
    }
    if (tag == 1) {
        return self.makeupItems;
    }
    if (tag == 2) {
        return self.hairItems;
    }
    if (tag == 3) {
        return self.jewelryItems;
    }
    if (tag == 4) {
        return self.shoesItems;
    }
    return @[];
}

- (NSDictionary<NSString *, id> *)yk_itemForCollectionView:(UICollectionView *)collectionView indexPath:(NSIndexPath *)indexPath {
    NSArray *items = [self yk_itemsForCollectionTag:collectionView.tag];
    if (indexPath.item < 0 || indexPath.item >= (NSInteger)items.count) {
        return @{};
    }
    return items[indexPath.item];
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return [self yk_itemsForCollectionTag:collectionView.tag].count;
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    YKFindDiscoverCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"YKFindDiscoverCell" forIndexPath:indexPath];
    NSDictionary<NSString *, id> *item = [self yk_itemForCollectionView:collectionView indexPath:indexPath];
    [cell configureWithEntry:item ownerKey:[self yk_ownerKey]];
    __weak typeof(self) weakSelf = self;
    cell.yk_moreTapHandler = ^(NSDictionary *entry) {
        [weakSelf yk_moreTappedForPost:entry];
    };
    return cell;
}

- (void)yk_moreTappedForPost:(NSDictionary *)post {
    NSString *peerId = [post[@"personaId"] isKindOfClass:NSString.class] ? post[@"personaId"] : @"";
    if (peerId.length == 0) {
        return;
    }
    NSString *owner = [self yk_ownerKey];
    if ([post[@"isMine"] boolValue] || [peerId isEqualToString:owner]) {
        return;
    }
    self.yk_actionPeerId = peerId;
    __weak typeof(self) weakSelf = self;
    [YKReportShadeSheet yk_presentInView:self.view
                                  report:^{
        YKReportViewController *report = [[YKReportViewController alloc] initWithPersonaId:weakSelf.yk_actionPeerId];
        [weakSelf.navigationController pushViewController:report animated:YES];
    }
                                   block:^{
        [weakSelf yk_blockPeer:weakSelf.yk_actionPeerId];
    }];
}

- (void)yk_blockPeer:(NSString *)peerId {
    if (peerId.length == 0) {
        return;
    }
    NSString *owner = [self yk_ownerKey];
    if ([peerId isEqualToString:owner]) {
        return;
    }
    [[YKShadeRoster sharedRoster] yk_ownerKey:owner shadeId:peerId];
    [[YKBondLedger sharedLedger] yk_ownerKey:owner setLink:peerId on:NO];
    [YKCenterToast yk_showNotice:[YKCipherLoom yk_unfurl:@"gXSk12fDfGwMlYIIaZYBKg=="] inView:self.view];
    [self yk_reloadFeedExcludingBlocked];
    for (UICollectionView *collectionView in self.collectionViews) {
        [collectionView reloadData];
        [collectionView.collectionViewLayout invalidateLayout];
    }
    [self yk_updateFindEmptyStates];
}

- (CGFloat)waterfallLayout:(YKFindWaterfallLayout *)layout heightForItemAtIndexPath:(NSIndexPath *)indexPath itemWidth:(CGFloat)itemWidth {
    UICollectionView *collectionView = layout.collectionView;
    NSDictionary<NSString *, id> *item = [self yk_itemForCollectionView:collectionView indexPath:indexPath];
    NSNumber *ratio = item[@"ratio"] ?: @1.3;
    return floor(itemWidth * ratio.doubleValue);
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary<NSString *, id> *item = [self yk_itemForCollectionView:collectionView indexPath:indexPath];
    if (item.count == 0) {
        return;
    }
    YKFindDetailViewController *detailViewController = [[YKFindDetailViewController alloc] initWithEntry:item];
    [self.navigationController pushViewController:detailViewController animated:YES];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (scrollView != self.contentScrollView) {
        return;
    }

    CGFloat width = CGRectGetWidth(scrollView.bounds);
    if (width <= 0.0 || self.segmentButtons.count == 0) {
        return;
    }

    CGFloat rawProgress = scrollView.contentOffset.x / width;
    CGFloat boundedProgress = MIN(MAX(rawProgress, 0.0), (CGFloat)self.segmentButtons.count - 1.0);
    NSInteger leftIndex = (NSInteger)floor(boundedProgress);
    NSInteger maxIndex = (NSInteger)self.segmentButtons.count - 1;
    NSInteger rightIndex = MIN(leftIndex + 1, maxIndex);
    CGFloat localProgress = boundedProgress - (CGFloat)leftIndex;

    [self.segmentButtons enumerateObjectsUsingBlock:^(YKFindSegmentButton *button, NSUInteger idx, BOOL *stop) {
        CGFloat progress = 0.0;
        if ((NSInteger)idx == leftIndex) {
            progress = 1.0 - localProgress;
        } else if ((NSInteger)idx == rightIndex) {
            progress = localProgress;
        }
        [button setSelectionProgress:progress];
    }];

    [self yk_updateUnderlineFromIndex:leftIndex toIndex:rightIndex progress:localProgress];
    [self yk_updateSegmentScrollOffsetWithProgress:boundedProgress];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    [self yk_syncSegmentWithScrollView:scrollView animated:YES];
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView {
    [self yk_syncSegmentWithScrollView:scrollView animated:YES];
}

- (void)yk_syncSegmentWithScrollView:(UIScrollView *)scrollView animated:(BOOL)animated {
    if (scrollView != self.contentScrollView) {
        return;
    }

    CGFloat width = CGRectGetWidth(scrollView.bounds);
    if (width <= 0.0) {
        return;
    }

    NSInteger index = (NSInteger)lround(scrollView.contentOffset.x / width);
    NSInteger maxIndex = (NSInteger)self.segmentButtons.count - 1;
    index = MAX(0, MIN(index, maxIndex));
    if (index == self.selectedContentIndex) {
        return;
    }

    self.selectedContentIndex = index;
    [self yk_updateSegmentSelectionAnimated:animated];
}

- (void)yk_updateUnderlineFromIndex:(NSInteger)fromIndex toIndex:(NSInteger)toIndex progress:(CGFloat)progress {
    if (fromIndex < 0 || toIndex >= (NSInteger)self.segmentButtons.count) {
        return;
    }

    YKFindSegmentButton *fromButton = self.segmentButtons[fromIndex];
    YKFindSegmentButton *toButton = self.segmentButtons[toIndex];
    CGFloat boundedProgress = MIN(MAX(progress, 0.0), 1.0);
    CGFloat startX = CGRectGetMinX(fromButton.frame);
    CGFloat endX = CGRectGetMinX(toButton.frame);
    CGFloat startWidth = CGRectGetWidth(fromButton.bounds);
    CGFloat endWidth = CGRectGetWidth(toButton.bounds);

    self.tabUnderlineLeadingConstraint.constant = startX + (endX - startX) * boundedProgress;
    self.tabUnderlineWidthConstraint.constant = startWidth + (endWidth - startWidth) * boundedProgress;
    [self.segmentScrollView layoutIfNeeded];
}

@end
