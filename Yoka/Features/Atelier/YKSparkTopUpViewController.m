//
//  YKSparkTopUpViewController.m
//  Yoka
//

#import "YKSparkTopUpViewController.h"
#import "YKSparkConfirmSheet.h"
#import "YKSparkCoffer.h"
#import "YKSparkBooth.h"
#import "YKRosterVault.h"
#import "YKPersonaCatalog.h"
#import "YKCenterToast.h"
#import "YKCipherLoom.h"

@interface YKSparkTopUpViewController ()

@property (nonatomic, strong) UILabel *yk_tallyValueLabel;
@property (nonatomic, copy) NSArray<NSDictionary *> *yk_packages;

@end

@implementation YKSparkTopUpViewController

- (void)yk_configurePage {
    [super yk_configurePage];
    self.yk_packages = [YKSparkBooth yk_catalog];
    [self yk_setupViews];
    [self yk_refreshBalance];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self yk_refreshBalance];
}

- (NSString *)yk_ownerKey {
    YKRosterVault *vault = [YKRosterVault sharedRoster];
    if ([YKRosterVault yk_isReviewMailbox:vault.yk_activeMailbox ?: @""]) {
        return [YKPersonaCatalog yk_reviewPersonaId];
    }
    return vault.yk_activeMailbox.length > 0 ? vault.yk_activeMailbox : @"guest";
}

- (void)yk_refreshBalance {
    NSInteger sparkQty = [[YKSparkCoffer sharedCoffer] yk_tallyForOwnerKey:[self yk_ownerKey]];
    self.yk_tallyValueLabel.text = [NSString stringWithFormat:@"%ld", (long)sparkQty];
}

- (void)yk_setupViews {
    UIButton *backButton = [self yk_addBackButton];

    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    titleLabel.text = [YKCipherLoom yk_unfurl:@"0rRTc5Xifg5v7G59kIjlYw=="];
    titleLabel.textColor = UIColor.whiteColor;
    titleLabel.font = [UIFont fontWithName:@"Limelight" size:24.0] ?: [UIFont systemFontOfSize:24.0 weight:UIFontWeightBold];
    [self.view addSubview:titleLabel];

    UIScrollView *scrollView = [[UIScrollView alloc] init];
    scrollView.translatesAutoresizingMaskIntoConstraints = NO;
    scrollView.showsVerticalScrollIndicator = NO;
    scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    [self.view addSubview:scrollView];

    UIView *contentView = [[UIView alloc] init];
    contentView.translatesAutoresizingMaskIntoConstraints = NO;
    [scrollView addSubview:contentView];

    UIImageView *balanceBanner = [[UIImageView alloc] initWithImage:[[UIImage imageNamed:@"mine_balance_banner"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]];
    balanceBanner.translatesAutoresizingMaskIntoConstraints = NO;
    balanceBanner.contentMode = UIViewContentModeScaleAspectFit;
    [contentView addSubview:balanceBanner];

    UILabel *tallyValueLabel = [[UILabel alloc] init];
    tallyValueLabel.translatesAutoresizingMaskIntoConstraints = NO;
    tallyValueLabel.text = @"0";
    tallyValueLabel.textColor = UIColor.whiteColor;
    tallyValueLabel.font = [UIFont fontWithName:@"Limelight" size:34.0] ?: [UIFont systemFontOfSize:34.0 weight:UIFontWeightBold];
    [balanceBanner addSubview:tallyValueLabel];
    self.yk_tallyValueLabel = tallyValueLabel;

    UILabel *balanceTitleLabel = [[UILabel alloc] init];
    balanceTitleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    balanceTitleLabel.text = @"Balance";
    balanceTitleLabel.textColor = UIColor.whiteColor;
    balanceTitleLabel.font = [UIFont systemFontOfSize:15.0 weight:UIFontWeightRegular];
    [balanceBanner addSubview:balanceTitleLabel];

    UIView *gridView = [[UIView alloc] init];
    gridView.translatesAutoresizingMaskIntoConstraints = NO;
    [contentView addSubview:gridView];

    NSMutableArray<UIView *> *cards = [NSMutableArray arrayWithCapacity:self.yk_packages.count];
    for (NSInteger index = 0; index < (NSInteger)self.yk_packages.count; index++) {
        UIView *card = [self yk_packageCardWithInfo:self.yk_packages[index] tag:index];
        [gridView addSubview:card];
        [cards addObject:card];
    }

    [NSLayoutConstraint activateConstraints:@[
        [titleLabel.centerYAnchor constraintEqualToAnchor:backButton.centerYAnchor],
        [titleLabel.leadingAnchor constraintEqualToAnchor:backButton.trailingAnchor constant:2.0],

        [scrollView.topAnchor constraintEqualToAnchor:backButton.bottomAnchor constant:8.0],
        [scrollView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [scrollView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [scrollView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],

        [contentView.topAnchor constraintEqualToAnchor:scrollView.contentLayoutGuide.topAnchor],
        [contentView.leadingAnchor constraintEqualToAnchor:scrollView.contentLayoutGuide.leadingAnchor],
        [contentView.trailingAnchor constraintEqualToAnchor:scrollView.contentLayoutGuide.trailingAnchor],
        [contentView.bottomAnchor constraintEqualToAnchor:scrollView.contentLayoutGuide.bottomAnchor],
        [contentView.widthAnchor constraintEqualToAnchor:scrollView.frameLayoutGuide.widthAnchor],

        [balanceBanner.topAnchor constraintEqualToAnchor:contentView.topAnchor constant:10.0],
        [balanceBanner.leadingAnchor constraintEqualToAnchor:contentView.leadingAnchor constant:20.0],
        [balanceBanner.trailingAnchor constraintEqualToAnchor:contentView.trailingAnchor constant:-20.0],
        [balanceBanner.heightAnchor constraintEqualToAnchor:balanceBanner.widthAnchor multiplier:258.0 / 969.0],

        [tallyValueLabel.leadingAnchor constraintEqualToAnchor:balanceBanner.leadingAnchor constant:40.0],
        [tallyValueLabel.topAnchor constraintEqualToAnchor:balanceBanner.topAnchor constant:18.0],
        [balanceTitleLabel.leadingAnchor constraintEqualToAnchor:tallyValueLabel.leadingAnchor],
        [balanceTitleLabel.topAnchor constraintEqualToAnchor:tallyValueLabel.bottomAnchor constant:-2.0],

        [gridView.topAnchor constraintEqualToAnchor:balanceBanner.bottomAnchor constant:18.0],
        [gridView.leadingAnchor constraintEqualToAnchor:contentView.leadingAnchor constant:20.0],
        [gridView.trailingAnchor constraintEqualToAnchor:contentView.trailingAnchor constant:-20.0],
        [gridView.bottomAnchor constraintEqualToAnchor:contentView.bottomAnchor constant:-28.0]
    ]];

    // 2-column grid: 5 rows × 2.
    UIView *prevLeft = nil;
    UIView *prevRight = nil;
    for (NSInteger index = 0; index < (NSInteger)cards.count; index++) {
        UIView *card = cards[index];
        BOOL isLeft = (index % 2 == 0);
        NSMutableArray *rowConstraints = [NSMutableArray array];
        [rowConstraints addObject:[card.widthAnchor constraintEqualToAnchor:gridView.widthAnchor multiplier:0.5 constant:-7.0]];
        [rowConstraints addObject:[card.heightAnchor constraintEqualToConstant:124.0]];
        if (isLeft) {
            [rowConstraints addObject:[card.leadingAnchor constraintEqualToAnchor:gridView.leadingAnchor]];
            if (prevLeft) {
                [rowConstraints addObject:[card.topAnchor constraintEqualToAnchor:prevLeft.bottomAnchor constant:12.0]];
            } else {
                [rowConstraints addObject:[card.topAnchor constraintEqualToAnchor:gridView.topAnchor]];
            }
            prevLeft = card;
        } else {
            [rowConstraints addObject:[card.trailingAnchor constraintEqualToAnchor:gridView.trailingAnchor]];
            if (prevRight) {
                [rowConstraints addObject:[card.topAnchor constraintEqualToAnchor:prevRight.bottomAnchor constant:12.0]];
            } else {
                [rowConstraints addObject:[card.topAnchor constraintEqualToAnchor:gridView.topAnchor]];
            }
            prevRight = card;
        }
        if (index == (NSInteger)cards.count - 1) {
            [rowConstraints addObject:[card.bottomAnchor constraintEqualToAnchor:gridView.bottomAnchor]];
        } else if (index == (NSInteger)cards.count - 2 && isLeft) {
            [rowConstraints addObject:[card.bottomAnchor constraintEqualToAnchor:gridView.bottomAnchor]];
        }
        [NSLayoutConstraint activateConstraints:rowConstraints];
    }
}

- (UIView *)yk_packageCardWithInfo:(NSDictionary *)info tag:(NSInteger)tag {
    UIView *card = [[UIView alloc] init];
    card.translatesAutoresizingMaskIntoConstraints = NO;
    card.backgroundColor = [UIColor colorWithRed:0xDD / 255.0 green:0x63 / 255.0 blue:0xFF / 255.0 alpha:1.0];
    card.layer.cornerRadius = 0.0;
    card.layer.borderWidth = 4.0;
    card.layer.borderColor = UIColor.whiteColor.CGColor;
    card.clipsToBounds = YES;

    // Column centered in the item; children centered so left/right gaps match.
    UIStackView *contentColumn = [[UIStackView alloc] init];
    contentColumn.translatesAutoresizingMaskIntoConstraints = NO;
    contentColumn.axis = UILayoutConstraintAxisVertical;
    contentColumn.alignment = UIStackViewAlignmentCenter;
    contentColumn.spacing = 14.0;
    contentColumn.userInteractionEnabled = NO;
    [card addSubview:contentColumn];

    UIStackView *sparkRow = [[UIStackView alloc] init];
    sparkRow.axis = UILayoutConstraintAxisHorizontal;
    sparkRow.alignment = UIStackViewAlignmentCenter;
    sparkRow.spacing = 8.0;
    [contentColumn addArrangedSubview:sparkRow];

    UIImageView *sparkIcon = [[UIImageView alloc] initWithImage:[[UIImage imageNamed:@"spark_icon_small"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]];
    sparkIcon.translatesAutoresizingMaskIntoConstraints = NO;
    sparkIcon.contentMode = UIViewContentModeScaleAspectFit;
    [sparkRow addArrangedSubview:sparkIcon];

    UILabel *sparkLabel = [[UILabel alloc] init];
    sparkLabel.text = [NSString stringWithFormat:@"%@", info[@"sparkQty"] ?: @0];
    sparkLabel.textColor = UIColor.whiteColor;
    sparkLabel.font = [UIFont systemFontOfSize:18.0 weight:UIFontWeightBold];
    sparkLabel.textAlignment = NSTextAlignmentLeft;
    [sparkRow addArrangedSubview:sparkLabel];

    UIView *priceBox = [[UIView alloc] init];
    priceBox.translatesAutoresizingMaskIntoConstraints = NO;
    priceBox.layer.cornerRadius = 0.0;
    priceBox.layer.borderWidth = 2.0;
    priceBox.layer.borderColor = UIColor.whiteColor.CGColor;
    [priceBox setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
    [contentColumn addArrangedSubview:priceBox];

    UILabel *priceLabel = [[UILabel alloc] init];
    priceLabel.translatesAutoresizingMaskIntoConstraints = NO;
    priceLabel.text = info[@"price"] ?: @"$ 0.99";
    priceLabel.textColor = UIColor.whiteColor;
    priceLabel.font = [UIFont systemFontOfSize:14.0 weight:UIFontWeightSemibold];
    priceLabel.textAlignment = NSTextAlignmentCenter;
    [priceBox addSubview:priceLabel];

    UIButton *hit = [UIButton buttonWithType:UIButtonTypeCustom];
    hit.translatesAutoresizingMaskIntoConstraints = NO;
    hit.tag = tag;
    [hit addTarget:self action:@selector(yk_packageTapped:) forControlEvents:UIControlEventTouchUpInside];
    [card addSubview:hit];

    [NSLayoutConstraint activateConstraints:@[
        [sparkIcon.widthAnchor constraintEqualToConstant:38.0],
        [sparkIcon.heightAnchor constraintEqualToConstant:36.0],

        [priceLabel.centerYAnchor constraintEqualToAnchor:priceBox.centerYAnchor],
        [priceLabel.leadingAnchor constraintEqualToAnchor:priceBox.leadingAnchor constant:12.0],
        [priceLabel.trailingAnchor constraintEqualToAnchor:priceBox.trailingAnchor constant:-12.0],
        [priceBox.heightAnchor constraintEqualToConstant:30.0],

        [contentColumn.centerXAnchor constraintEqualToAnchor:card.centerXAnchor],
        [contentColumn.centerYAnchor constraintEqualToAnchor:card.centerYAnchor],

        [hit.topAnchor constraintEqualToAnchor:card.topAnchor],
        [hit.leadingAnchor constraintEqualToAnchor:card.leadingAnchor],
        [hit.trailingAnchor constraintEqualToAnchor:card.trailingAnchor],
        [hit.bottomAnchor constraintEqualToAnchor:card.bottomAnchor]
    ]];
    return card;
}

- (void)yk_packageTapped:(UIButton *)sender {
    if (sender.tag < 0 || sender.tag >= (NSInteger)self.yk_packages.count) {
        return;
    }
    NSDictionary *info = self.yk_packages[sender.tag];
    NSString *productId = info[@"productId"];
    if (productId.length == 0) {
        return;
    }
    NSInteger sparkQty = [info[@"sparkQty"] integerValue];
    NSString *price = info[@"price"] ?: @"";
    __weak typeof(self) weakSelf = self;
    [YKSparkConfirmSheet yk_presentInView:self.view
                                        sparkQty:sparkQty
                                       price:price
                                      cancel:nil
                                        sure:^{
        [weakSelf yk_beginSkuClaim:productId];
    }];
}

- (void)yk_beginSkuClaim:(NSString *)productId {
    __weak typeof(self) weakSelf = self;
    [[YKSparkBooth sharedBooth] yk_claimSku:productId
                                   hostView:self.view
                                 completion:^(BOOL success, NSInteger sparkQty, NSError * _Nullable error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) {
            return;
        }
        if (success && sparkQty > 0) {
            [[YKSparkCoffer sharedCoffer] yk_ownerKey:[strongSelf yk_ownerKey] credit:sparkQty];
            [strongSelf yk_refreshBalance];
            [YKCenterToast yk_showNotice:[NSString stringWithFormat:@"+%ld", (long)sparkQty] inView:strongSelf.view];
            return;
        }
        if (error != nil) {
            NSString *msg = error.localizedDescription.length > 0 ? error.localizedDescription : [YKCipherLoom yk_unfurl:@"5Vs4kLbF63El4SwV9yncpg=="];
            [YKCenterToast yk_showNotice:msg inView:strongSelf.view];
        }
    }];
}

@end
