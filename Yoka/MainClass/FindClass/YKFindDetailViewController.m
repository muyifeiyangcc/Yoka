//
//  YKFindDetailViewController.m
//  Yoka
//

#import "YKFindDetailViewController.h"
#import "YKFindItemsViewController.h"
#import "YKFindUserProfileViewController.h"

@interface YKFindDetailPhotoView : UIView

@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) CAGradientLayer *fallbackGradientLayer;
@property (nonatomic, strong) CAGradientLayer *bottomGradientLayer;
@property (nonatomic, strong) UILabel *fallbackTitleLabel;

@end

@implementation YKFindDetailPhotoView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self yk_setupViews];
    }
    return self;
}

- (void)yk_setupViews {
    self.layer.cornerRadius = 14.0;
    self.layer.masksToBounds = YES;
    self.backgroundColor = [UIColor colorWithRed:0.39 green:0.13 blue:0.55 alpha:1.0];

    CAGradientLayer *fallbackGradientLayer = [CAGradientLayer layer];
    fallbackGradientLayer.startPoint = CGPointMake(0.0, 0.0);
    fallbackGradientLayer.endPoint = CGPointMake(1.0, 1.0);
    fallbackGradientLayer.colors = @[
        (__bridge id)[UIColor colorWithRed:0.10 green:0.11 blue:0.20 alpha:1.0].CGColor,
        (__bridge id)[UIColor colorWithRed:0.85 green:0.00 blue:0.76 alpha:1.0].CGColor
    ];
    [self.layer addSublayer:fallbackGradientLayer];
    self.fallbackGradientLayer = fallbackGradientLayer;

    UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"detail_main_photo"]];
    imageView.translatesAutoresizingMaskIntoConstraints = NO;
    imageView.contentMode = UIViewContentModeScaleAspectFill;
    imageView.clipsToBounds = YES;
    [self addSubview:imageView];
    self.imageView = imageView;

    UILabel *fallbackTitleLabel = [[UILabel alloc] init];
    fallbackTitleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    fallbackTitleLabel.text = @"Y2K FIT";
    fallbackTitleLabel.textColor = UIColor.whiteColor;
    fallbackTitleLabel.textAlignment = NSTextAlignmentCenter;
    fallbackTitleLabel.font = [UIFont systemFontOfSize:36.0 weight:UIFontWeightBlack];
    fallbackTitleLabel.alpha = imageView.image ? 0.0 : 1.0;
    [self addSubview:fallbackTitleLabel];
    self.fallbackTitleLabel = fallbackTitleLabel;

    CAGradientLayer *bottomGradientLayer = [CAGradientLayer layer];
    bottomGradientLayer.colors = @[
        (__bridge id)[UIColor colorWithWhite:0.0 alpha:0.0].CGColor,
        (__bridge id)[UIColor colorWithWhite:0.0 alpha:0.52].CGColor
    ];
    bottomGradientLayer.locations = @[@0.45, @1.0];
    [self.layer addSublayer:bottomGradientLayer];
    self.bottomGradientLayer = bottomGradientLayer;

    [NSLayoutConstraint activateConstraints:@[
        [imageView.topAnchor constraintEqualToAnchor:self.topAnchor],
        [imageView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
        [imageView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
        [imageView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],

        [fallbackTitleLabel.centerXAnchor constraintEqualToAnchor:self.centerXAnchor],
        [fallbackTitleLabel.centerYAnchor constraintEqualToAnchor:self.centerYAnchor]
    ]];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.fallbackGradientLayer.frame = self.bounds;
    self.bottomGradientLayer.frame = self.bounds;
}

@end

@interface YKFindDetailViewController ()

@property (nonatomic, copy) NSString *userName;
@property (nonatomic, strong) UIView *commentPanelView;
@property (nonatomic, strong) UIView *spendDialogOverlayView;

@end

@implementation YKFindDetailViewController

- (instancetype)initWithUserName:(NSString *)userName {
    self = [super init];
    if (self) {
        _userName = userName.length > 0 ? [userName copy] : @"Amelia";
    }
    return self;
}

- (void)yk_configurePage {
    [super yk_configurePage];
    [self yk_setupContentView];
}

- (void)yk_setupContentView {
    UIButton *backButton = [self yk_addBackButton];
    [self.view bringSubviewToFront:backButton];

    UIScrollView *scrollView = [[UIScrollView alloc] init];
    scrollView.translatesAutoresizingMaskIntoConstraints = NO;
    scrollView.showsVerticalScrollIndicator = NO;
    scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    [self.view addSubview:scrollView];

    UIView *contentView = [[UIView alloc] init];
    contentView.translatesAutoresizingMaskIntoConstraints = NO;
    [scrollView addSubview:contentView];

    UIImageView *avatarImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"headplace"]];
    avatarImageView.translatesAutoresizingMaskIntoConstraints = NO;
    avatarImageView.layer.cornerRadius = 22.0;
    avatarImageView.layer.masksToBounds = YES;
    avatarImageView.userInteractionEnabled = YES;
    [contentView addSubview:avatarImageView];

    UIButton *avatarButton = [UIButton buttonWithType:UIButtonTypeCustom];
    avatarButton.translatesAutoresizingMaskIntoConstraints = NO;
    [avatarButton addTarget:self action:@selector(yk_avatarButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [contentView addSubview:avatarButton];

    UILabel *nameLabel = [[UILabel alloc] init];
    nameLabel.translatesAutoresizingMaskIntoConstraints = NO;
    nameLabel.text = self.userName;
    nameLabel.textColor = UIColor.whiteColor;
    nameLabel.font = [UIFont systemFontOfSize:16.0 weight:UIFontWeightBold];
    [contentView addSubview:nameLabel];

    UILabel *subNameLabel = [[UILabel alloc] init];
    subNameLabel.translatesAutoresizingMaskIntoConstraints = NO;
    subNameLabel.text = self.userName;
    subNameLabel.textColor = [UIColor colorWithWhite:1.0 alpha:0.86];
    subNameLabel.font = [UIFont systemFontOfSize:13.0 weight:UIFontWeightRegular];
    [contentView addSubview:subNameLabel];

    UIButton *viewItemsTopButton = [UIButton buttonWithType:UIButtonTypeCustom];
    viewItemsTopButton.translatesAutoresizingMaskIntoConstraints = NO;
    viewItemsTopButton.layer.cornerRadius = 17.0;
    viewItemsTopButton.layer.borderColor = UIColor.whiteColor.CGColor;
    viewItemsTopButton.layer.borderWidth = 1.5;
    [viewItemsTopButton setTitle:@"View Items" forState:UIControlStateNormal];
    [viewItemsTopButton setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    viewItemsTopButton.titleLabel.font = [UIFont systemFontOfSize:13.0 weight:UIFontWeightBold];
    [viewItemsTopButton addTarget:self action:@selector(yk_viewItemsButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:viewItemsTopButton];

    YKFindDetailPhotoView *photoView = [[YKFindDetailPhotoView alloc] initWithFrame:CGRectZero];
    photoView.translatesAutoresizingMaskIntoConstraints = NO;
    [contentView addSubview:photoView];

    UIButton *moreButton = [UIButton buttonWithType:UIButtonTypeCustom];
    moreButton.translatesAutoresizingMaskIntoConstraints = NO;
    [moreButton setImage:[[UIImage imageNamed:@"detail_more_button"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] forState:UIControlStateNormal];
    [contentView addSubview:moreButton];

    UILabel *descriptionLabel = [[UILabel alloc] init];
    descriptionLabel.translatesAutoresizingMaskIntoConstraints = NO;
    descriptionLabel.numberOfLines = 0;
    descriptionLabel.text = @"Just created a new Y2K-inspired look and I'm obsessed. From the statement accessories to the dreamy colors, every piece brings back the early 2000s energy. Can't wait to see how you style your own Y2K outfits.";
    descriptionLabel.textColor = [UIColor colorWithWhite:1.0 alpha:0.92];
    descriptionLabel.font = [UIFont systemFontOfSize:13.0 weight:UIFontWeightRegular];
    [contentView addSubview:descriptionLabel];

    UIStackView *statsStackView = [[UIStackView alloc] init];
    statsStackView.translatesAutoresizingMaskIntoConstraints = NO;
    statsStackView.axis = UILayoutConstraintAxisHorizontal;
    statsStackView.alignment = UIStackViewAlignmentCenter;
    statsStackView.spacing = 16.0;
    [contentView addSubview:statsStackView];

    [statsStackView addArrangedSubview:[self yk_statViewWithImageName:@"detail_like_star" title:@"888 Likes"]];
    [statsStackView addArrangedSubview:[self yk_commentStatButton]];
    [self yk_setupCommentPanelView];
    [self yk_setupSpendDialogView];
    [self.view bringSubviewToFront:viewItemsTopButton];
    [self.view bringSubviewToFront:backButton];

    UILayoutGuide *safeGuide = self.view.safeAreaLayoutGuide;
    [NSLayoutConstraint activateConstraints:@[
        [scrollView.topAnchor constraintEqualToAnchor:safeGuide.topAnchor],
        [scrollView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [scrollView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [scrollView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],

        [contentView.topAnchor constraintEqualToAnchor:scrollView.contentLayoutGuide.topAnchor],
        [contentView.leadingAnchor constraintEqualToAnchor:scrollView.contentLayoutGuide.leadingAnchor],
        [contentView.trailingAnchor constraintEqualToAnchor:scrollView.contentLayoutGuide.trailingAnchor],
        [contentView.bottomAnchor constraintEqualToAnchor:scrollView.contentLayoutGuide.bottomAnchor],
        [contentView.widthAnchor constraintEqualToAnchor:scrollView.frameLayoutGuide.widthAnchor],

        [viewItemsTopButton.topAnchor constraintEqualToAnchor:safeGuide.topAnchor constant:8.0],
        [viewItemsTopButton.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-20.0],
        [viewItemsTopButton.widthAnchor constraintEqualToConstant:92.0],
        [viewItemsTopButton.heightAnchor constraintEqualToConstant:34.0],

        [avatarImageView.topAnchor constraintEqualToAnchor:contentView.topAnchor constant:72.0],
        [avatarImageView.leadingAnchor constraintEqualToAnchor:contentView.leadingAnchor constant:24.0],
        [avatarImageView.widthAnchor constraintEqualToConstant:44.0],
        [avatarImageView.heightAnchor constraintEqualToConstant:44.0],

        [avatarButton.topAnchor constraintEqualToAnchor:avatarImageView.topAnchor],
        [avatarButton.leadingAnchor constraintEqualToAnchor:avatarImageView.leadingAnchor],
        [avatarButton.trailingAnchor constraintEqualToAnchor:subNameLabel.trailingAnchor constant:8.0],
        [avatarButton.bottomAnchor constraintEqualToAnchor:avatarImageView.bottomAnchor],

        [nameLabel.leadingAnchor constraintEqualToAnchor:avatarImageView.trailingAnchor constant:10.0],
        [nameLabel.topAnchor constraintEqualToAnchor:avatarImageView.topAnchor constant:2.0],

        [subNameLabel.leadingAnchor constraintEqualToAnchor:nameLabel.leadingAnchor],
        [subNameLabel.topAnchor constraintEqualToAnchor:nameLabel.bottomAnchor constant:2.0],

        [moreButton.centerYAnchor constraintEqualToAnchor:avatarImageView.centerYAnchor],
        [moreButton.trailingAnchor constraintEqualToAnchor:contentView.trailingAnchor constant:-24.0],
        [moreButton.widthAnchor constraintEqualToConstant:36.0],
        [moreButton.heightAnchor constraintEqualToConstant:36.0],

        [photoView.topAnchor constraintEqualToAnchor:avatarImageView.bottomAnchor constant:18.0],
        [photoView.leadingAnchor constraintEqualToAnchor:contentView.leadingAnchor constant:24.0],
        [photoView.trailingAnchor constraintEqualToAnchor:contentView.trailingAnchor constant:-24.0],
        [photoView.heightAnchor constraintEqualToAnchor:photoView.widthAnchor multiplier:1.23],

        [descriptionLabel.topAnchor constraintEqualToAnchor:photoView.bottomAnchor constant:16.0],
        [descriptionLabel.leadingAnchor constraintEqualToAnchor:photoView.leadingAnchor],
        [descriptionLabel.trailingAnchor constraintEqualToAnchor:photoView.trailingAnchor],

        [statsStackView.topAnchor constraintEqualToAnchor:descriptionLabel.bottomAnchor constant:16.0],
        [statsStackView.leadingAnchor constraintEqualToAnchor:photoView.leadingAnchor],
        [statsStackView.heightAnchor constraintEqualToConstant:20.0],
        [statsStackView.bottomAnchor constraintEqualToAnchor:contentView.bottomAnchor constant:-40.0]
    ]];
}

- (UIView *)yk_statViewWithImageName:(NSString *)imageName title:(NSString *)title {
    UIStackView *stackView = [[UIStackView alloc] init];
    stackView.translatesAutoresizingMaskIntoConstraints = NO;
    stackView.axis = UILayoutConstraintAxisHorizontal;
    stackView.alignment = UIStackViewAlignmentCenter;
    stackView.spacing = 5.0;

    UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:imageName]];
    imageView.translatesAutoresizingMaskIntoConstraints = NO;
    imageView.contentMode = UIViewContentModeScaleAspectFit;
    [stackView addArrangedSubview:imageView];

    UILabel *label = [[UILabel alloc] init];
    label.text = title;
    label.textColor = [UIColor colorWithWhite:1.0 alpha:0.88];
    label.font = [UIFont systemFontOfSize:12.0 weight:UIFontWeightRegular];
    [stackView addArrangedSubview:label];

    [NSLayoutConstraint activateConstraints:@[
        [imageView.widthAnchor constraintEqualToConstant:16.0],
        [imageView.heightAnchor constraintEqualToConstant:16.0]
    ]];

    return stackView;
}

- (UIButton *)yk_commentStatButton {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.translatesAutoresizingMaskIntoConstraints = NO;
    [button addTarget:self action:@selector(yk_commentButtonTapped:) forControlEvents:UIControlEventTouchUpInside];

    UIStackView *stackView = [[UIStackView alloc] init];
    stackView.translatesAutoresizingMaskIntoConstraints = NO;
    stackView.axis = UILayoutConstraintAxisHorizontal;
    stackView.alignment = UIStackViewAlignmentCenter;
    stackView.spacing = 5.0;
    stackView.userInteractionEnabled = NO;
    [button addSubview:stackView];

    UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"detail_comment_icon"]];
    imageView.translatesAutoresizingMaskIntoConstraints = NO;
    imageView.contentMode = UIViewContentModeScaleAspectFit;
    [stackView addArrangedSubview:imageView];

    UILabel *label = [[UILabel alloc] init];
    label.text = @"777 Comments";
    label.textColor = [UIColor colorWithWhite:1.0 alpha:0.88];
    label.font = [UIFont systemFontOfSize:12.0 weight:UIFontWeightRegular];
    [stackView addArrangedSubview:label];

    [NSLayoutConstraint activateConstraints:@[
        [stackView.topAnchor constraintEqualToAnchor:button.topAnchor],
        [stackView.leadingAnchor constraintEqualToAnchor:button.leadingAnchor],
        [stackView.trailingAnchor constraintEqualToAnchor:button.trailingAnchor],
        [stackView.bottomAnchor constraintEqualToAnchor:button.bottomAnchor],
        [imageView.widthAnchor constraintEqualToConstant:16.0],
        [imageView.heightAnchor constraintEqualToConstant:16.0]
    ]];

    return button;
}

- (void)yk_setupCommentPanelView {
    UIView *panelView = [[UIView alloc] init];
    panelView.translatesAutoresizingMaskIntoConstraints = NO;
    panelView.hidden = YES;
    panelView.backgroundColor = [UIColor colorWithRed:0.88 green:0.31 blue:0.93 alpha:0.96];
    panelView.layer.cornerRadius = 18.0;
    panelView.layer.borderColor = UIColor.whiteColor.CGColor;
    panelView.layer.borderWidth = 1.4;
    panelView.layer.maskedCorners = kCALayerMinXMinYCorner | kCALayerMaxXMinYCorner;
    [self.view addSubview:panelView];
    self.commentPanelView = panelView;

    UIStackView *commentsStackView = [[UIStackView alloc] init];
    commentsStackView.translatesAutoresizingMaskIntoConstraints = NO;
    commentsStackView.axis = UILayoutConstraintAxisVertical;
    commentsStackView.spacing = 10.0;
    [panelView addSubview:commentsStackView];

    [commentsStackView addArrangedSubview:[self yk_commentRowWithName:@"Jasper"
                                                                  text:@"The video content is great! Keep going!The video content is great! Keep going!"
                                                              moreDots:YES]];
    [commentsStackView addArrangedSubview:[self yk_commentSeparatorView]];
    [commentsStackView addArrangedSubview:[self yk_commentRowWithName:@"Rowan"
                                                                  text:@"The video content is great! Keep going!"
                                                              moreDots:NO]];
    [commentsStackView addArrangedSubview:[self yk_commentSeparatorView]];
    [commentsStackView addArrangedSubview:[self yk_commentRowWithName:@"Sophia"
                                                                  text:@"The video content is great! Keep going!"
                                                              moreDots:YES]];

    UIView *inputFieldView = [[UIView alloc] init];
    inputFieldView.translatesAutoresizingMaskIntoConstraints = NO;
    inputFieldView.backgroundColor = UIColor.whiteColor;
    inputFieldView.layer.cornerRadius = 22.0;
    [panelView addSubview:inputFieldView];

    UITextField *textField = [[UITextField alloc] init];
    textField.translatesAutoresizingMaskIntoConstraints = NO;
    textField.placeholder = @"Say something";
    textField.textColor = UIColor.blackColor;
    textField.font = [UIFont systemFontOfSize:15.0 weight:UIFontWeightRegular];
    [inputFieldView addSubview:textField];

    UIButton *sendButton = [UIButton buttonWithType:UIButtonTypeCustom];
    sendButton.translatesAutoresizingMaskIntoConstraints = NO;
    [sendButton setImage:[[UIImage imageNamed:@"messend"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] forState:UIControlStateNormal];
    [inputFieldView addSubview:sendButton];

    [NSLayoutConstraint activateConstraints:@[
        [panelView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [panelView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [panelView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
        [panelView.heightAnchor constraintEqualToConstant:323.0],

        [commentsStackView.topAnchor constraintEqualToAnchor:panelView.topAnchor constant:18.0],
        [commentsStackView.leadingAnchor constraintEqualToAnchor:panelView.leadingAnchor constant:20.0],
        [commentsStackView.trailingAnchor constraintEqualToAnchor:panelView.trailingAnchor constant:-20.0],

        [inputFieldView.leadingAnchor constraintEqualToAnchor:panelView.leadingAnchor constant:20.0],
        [inputFieldView.trailingAnchor constraintEqualToAnchor:panelView.trailingAnchor constant:-20.0],
        [inputFieldView.bottomAnchor constraintEqualToAnchor:panelView.safeAreaLayoutGuide.bottomAnchor constant:-10.0],
        [inputFieldView.heightAnchor constraintEqualToConstant:44.0],

        [textField.centerYAnchor constraintEqualToAnchor:inputFieldView.centerYAnchor],
        [textField.leadingAnchor constraintEqualToAnchor:inputFieldView.leadingAnchor constant:14.0],
        [textField.trailingAnchor constraintEqualToAnchor:sendButton.leadingAnchor constant:-10.0],

        [sendButton.centerYAnchor constraintEqualToAnchor:inputFieldView.centerYAnchor],
        [sendButton.trailingAnchor constraintEqualToAnchor:inputFieldView.trailingAnchor constant:-5.0],
        [sendButton.widthAnchor constraintEqualToConstant:38.0],
        [sendButton.heightAnchor constraintEqualToConstant:38.0]
    ]];
}

- (void)yk_setupSpendDialogView {
    UIView *overlayView = [[UIView alloc] init];
    overlayView.translatesAutoresizingMaskIntoConstraints = NO;
    overlayView.hidden = YES;
    overlayView.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.58];
    [self.view addSubview:overlayView];
    self.spendDialogOverlayView = overlayView;

    UIImageView *dialogImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"enough"]];
    dialogImageView.translatesAutoresizingMaskIntoConstraints = NO;
    dialogImageView.contentMode = UIViewContentModeScaleAspectFit;
    dialogImageView.userInteractionEnabled = YES;
    [overlayView addSubview:dialogImageView];

    UIButton *cancelButton = [UIButton buttonWithType:UIButtonTypeCustom];
    cancelButton.translatesAutoresizingMaskIntoConstraints = NO;
    [cancelButton addTarget:self action:@selector(yk_cancelSpendDialog:) forControlEvents:UIControlEventTouchUpInside];
    [dialogImageView addSubview:cancelButton];

    UIButton *sureButton = [UIButton buttonWithType:UIButtonTypeCustom];
    sureButton.translatesAutoresizingMaskIntoConstraints = NO;
    [sureButton addTarget:self action:@selector(yk_confirmSpendDialog:) forControlEvents:UIControlEventTouchUpInside];
    [dialogImageView addSubview:sureButton];

    [NSLayoutConstraint activateConstraints:@[
        [overlayView.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [overlayView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [overlayView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [overlayView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],

        [dialogImageView.centerXAnchor constraintEqualToAnchor:overlayView.centerXAnchor],
        [dialogImageView.centerYAnchor constraintEqualToAnchor:overlayView.centerYAnchor constant:-6.0],
        [dialogImageView.widthAnchor constraintEqualToConstant:309.0],
        [dialogImageView.heightAnchor constraintEqualToConstant:241.0],

        [cancelButton.leadingAnchor constraintEqualToAnchor:dialogImageView.leadingAnchor constant:50.0],
        [cancelButton.bottomAnchor constraintEqualToAnchor:dialogImageView.bottomAnchor constant:-32.0],
        [cancelButton.widthAnchor constraintEqualToConstant:92.0],
        [cancelButton.heightAnchor constraintEqualToConstant:31.0],

        [sureButton.trailingAnchor constraintEqualToAnchor:dialogImageView.trailingAnchor constant:-38.0],
        [sureButton.bottomAnchor constraintEqualToAnchor:dialogImageView.bottomAnchor constant:-32.0],
        [sureButton.widthAnchor constraintEqualToConstant:96.0],
        [sureButton.heightAnchor constraintEqualToConstant:31.0]
    ]];
}

- (UIView *)yk_commentRowWithName:(NSString *)name text:(NSString *)text moreDots:(BOOL)moreDots {
    UIView *rowView = [[UIView alloc] init];
    rowView.translatesAutoresizingMaskIntoConstraints = NO;

    UIImageView *avatarImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"headplace"]];
    avatarImageView.translatesAutoresizingMaskIntoConstraints = NO;
    avatarImageView.layer.cornerRadius = 15.0;
    avatarImageView.layer.masksToBounds = YES;
    [rowView addSubview:avatarImageView];

    UILabel *nameLabel = [[UILabel alloc] init];
    nameLabel.translatesAutoresizingMaskIntoConstraints = NO;
    nameLabel.text = name;
    nameLabel.textColor = UIColor.whiteColor;
    nameLabel.font = [UIFont systemFontOfSize:16.0 weight:UIFontWeightBold];
    [rowView addSubview:nameLabel];

    UILabel *textLabel = [[UILabel alloc] init];
    textLabel.translatesAutoresizingMaskIntoConstraints = NO;
    textLabel.numberOfLines = 0;
    textLabel.text = text;
    textLabel.textColor = [UIColor colorWithWhite:1.0 alpha:0.82];
    textLabel.font = [UIFont systemFontOfSize:13.0 weight:UIFontWeightRegular];
    [rowView addSubview:textLabel];

    if (moreDots) {
        UIButton *moreButton = [UIButton buttonWithType:UIButtonTypeCustom];
        moreButton.translatesAutoresizingMaskIntoConstraints = NO;
        [moreButton setImage:[[UIImage imageNamed:@"detail_more_dots"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] forState:UIControlStateNormal];
        [rowView addSubview:moreButton];
        [NSLayoutConstraint activateConstraints:@[
            [moreButton.centerYAnchor constraintEqualToAnchor:nameLabel.centerYAnchor],
            [moreButton.trailingAnchor constraintEqualToAnchor:rowView.trailingAnchor],
            [moreButton.widthAnchor constraintEqualToConstant:32.0],
            [moreButton.heightAnchor constraintEqualToConstant:22.0]
        ]];
    }

    [NSLayoutConstraint activateConstraints:@[
        [rowView.heightAnchor constraintEqualToConstant:62.0],

        [avatarImageView.topAnchor constraintEqualToAnchor:rowView.topAnchor],
        [avatarImageView.leadingAnchor constraintEqualToAnchor:rowView.leadingAnchor],
        [avatarImageView.widthAnchor constraintEqualToConstant:30.0],
        [avatarImageView.heightAnchor constraintEqualToConstant:30.0],

        [nameLabel.topAnchor constraintEqualToAnchor:rowView.topAnchor constant:2.0],
        [nameLabel.leadingAnchor constraintEqualToAnchor:avatarImageView.trailingAnchor constant:10.0],

        [textLabel.topAnchor constraintEqualToAnchor:nameLabel.bottomAnchor constant:8.0],
        [textLabel.leadingAnchor constraintEqualToAnchor:rowView.leadingAnchor],
        [textLabel.trailingAnchor constraintEqualToAnchor:rowView.trailingAnchor constant:-4.0]
    ]];

    return rowView;
}

- (UIView *)yk_commentSeparatorView {
    UIView *separatorView = [[UIView alloc] init];
    separatorView.translatesAutoresizingMaskIntoConstraints = NO;
    separatorView.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.18];
    [NSLayoutConstraint activateConstraints:@[
        [separatorView.heightAnchor constraintEqualToConstant:1.0]
    ]];
    return separatorView;
}

- (void)yk_commentButtonTapped:(UIButton *)sender {
    self.commentPanelView.hidden = NO;
    self.commentPanelView.alpha = 0.0;
    self.commentPanelView.transform = CGAffineTransformMakeTranslation(0.0, 28.0);
    [self.view bringSubviewToFront:self.commentPanelView];

    [UIView animateWithDuration:0.22
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
        self.commentPanelView.alpha = 1.0;
        self.commentPanelView.transform = CGAffineTransformIdentity;
    } completion:nil];
}

- (void)yk_viewItemsButtonTapped:(UIButton *)sender {
    self.spendDialogOverlayView.hidden = NO;
    self.spendDialogOverlayView.alpha = 0.0;
    [self.view bringSubviewToFront:self.spendDialogOverlayView];

    [UIView animateWithDuration:0.18
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
        self.spendDialogOverlayView.alpha = 1.0;
    } completion:nil];
}

- (void)yk_cancelSpendDialog:(UIButton *)sender {
    [UIView animateWithDuration:0.16
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^{
        self.spendDialogOverlayView.alpha = 0.0;
    } completion:^(BOOL finished) {
        self.spendDialogOverlayView.hidden = YES;
    }];
}

- (void)yk_confirmSpendDialog:(UIButton *)sender {
    self.spendDialogOverlayView.hidden = YES;
    YKFindItemsViewController *itemsViewController = [[YKFindItemsViewController alloc] init];
    [self.navigationController pushViewController:itemsViewController animated:YES];
}

- (void)yk_avatarButtonTapped:(UIButton *)sender {
    YKFindUserProfileViewController *profileViewController = [[YKFindUserProfileViewController alloc] initWithUserName:self.userName];
    [self.navigationController pushViewController:profileViewController animated:YES];
}

@end
