//
//  YKBondListViewController.m
//  Yoka
//

#import "YKBondListViewController.h"
#import "../LoginandReClass/YKAccountVault.h"
#import "../LoginandReClass/YKBondLedger.h"
#import "../LoginandReClass/YKPersonaCatalog.h"
#import "../RelayClass/YKThreadViewController.h"
#import "../RelayClass/YKShadeRoster.h"
#import "../../BaseClass/YKSigilForge.h"

static NSString * const kYKBondListCellId = @"YKBondListCell";

@interface YKBondListCell : UITableViewCell
@property (nonatomic, strong) UIImageView *yk_avatarView;
@property (nonatomic, strong) UILabel *yk_nameLabel;
@property (nonatomic, strong) UIButton *yk_actionButton;
@property (nonatomic, copy) void (^yk_actionHandler)(void);
- (void)yk_configureName:(NSString *)name
                  avatar:(UIImage *)avatar
             actionTitle:(NSString *)title
                  filled:(BOOL)filled;
@end

@implementation YKBondListCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.backgroundColor = UIColor.clearColor;
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.contentView.backgroundColor = UIColor.clearColor;

        UIImageView *avatar = [[UIImageView alloc] init];
        avatar.translatesAutoresizingMaskIntoConstraints = NO;
        avatar.contentMode = UIViewContentModeScaleAspectFill;
        avatar.layer.cornerRadius = 22.0;
        avatar.layer.masksToBounds = YES;
        [self.contentView addSubview:avatar];
        self.yk_avatarView = avatar;

        UILabel *name = [[UILabel alloc] init];
        name.translatesAutoresizingMaskIntoConstraints = NO;
        name.textColor = UIColor.whiteColor;
        name.font = [UIFont systemFontOfSize:16.0 weight:UIFontWeightSemibold];
        [self.contentView addSubview:name];
        self.yk_nameLabel = name;

        UIButton *action = [UIButton buttonWithType:UIButtonTypeCustom];
        action.translatesAutoresizingMaskIntoConstraints = NO;
        action.titleLabel.font = [UIFont systemFontOfSize:14.0 weight:UIFontWeightMedium];
        action.layer.cornerRadius = 14.0;
        action.layer.borderWidth = 1.5;
        action.contentEdgeInsets = UIEdgeInsetsMake(0.0, 14.0, 0.0, 14.0);
        [action addTarget:self action:@selector(yk_actionTapped) forControlEvents:UIControlEventTouchUpInside];
        [self.contentView addSubview:action];
        self.yk_actionButton = action;

        [NSLayoutConstraint activateConstraints:@[
            [avatar.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:24.0],
            [avatar.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],
            [avatar.widthAnchor constraintEqualToConstant:44.0],
            [avatar.heightAnchor constraintEqualToConstant:44.0],

            [action.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-24.0],
            [action.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],
            [action.heightAnchor constraintEqualToConstant:28.0],
            [action.widthAnchor constraintGreaterThanOrEqualToConstant:88.0],

            [name.leadingAnchor constraintEqualToAnchor:avatar.trailingAnchor constant:14.0],
            [name.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],
            [name.trailingAnchor constraintLessThanOrEqualToAnchor:action.leadingAnchor constant:-12.0]
        ]];
    }
    return self;
}

- (void)yk_configureName:(NSString *)name
                  avatar:(UIImage *)avatar
             actionTitle:(NSString *)title
                  filled:(BOOL)filled {
    self.yk_nameLabel.text = name;
    self.yk_avatarView.image = [avatar imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    [self.yk_actionButton setTitle:title forState:UIControlStateNormal];
    if (filled) {
        self.yk_actionButton.backgroundColor = UIColor.whiteColor;
        self.yk_actionButton.layer.borderColor = UIColor.whiteColor.CGColor;
        [self.yk_actionButton setTitleColor:[UIColor colorWithRed:0.75 green:0.20 blue:0.90 alpha:1.0]
                                   forState:UIControlStateNormal];
    } else {
        self.yk_actionButton.backgroundColor = UIColor.clearColor;
        self.yk_actionButton.layer.borderColor = UIColor.whiteColor.CGColor;
        [self.yk_actionButton setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    }
}

- (void)yk_actionTapped {
    if (self.yk_actionHandler) {
        self.yk_actionHandler();
    }
}

@end

@interface YKBondListViewController () <UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, assign) YKBondListKind yk_kind;
@property (nonatomic, strong) UITableView *yk_tableView;
@property (nonatomic, strong) UIView *yk_emptyView;
@property (nonatomic, copy) NSArray<NSString *> *yk_personaIds;
@property (nonatomic, strong) UIView *yk_twinHintOverlay;
@property (nonatomic, strong) UIImageView *yk_twinHintDialog;
@property (nonatomic, strong) NSLayoutConstraint *yk_twinHintWidth;
@property (nonatomic, strong) NSLayoutConstraint *yk_twinHintHeight;
@property (nonatomic, strong) NSLayoutConstraint *yk_mutualCancelLeading;
@property (nonatomic, strong) NSLayoutConstraint *yk_mutualCancelBottom;
@property (nonatomic, strong) NSLayoutConstraint *yk_mutualCancelWidth;
@property (nonatomic, strong) NSLayoutConstraint *yk_mutualCancelHeight;
@property (nonatomic, strong) NSLayoutConstraint *yk_mutualSureTrailing;
@property (nonatomic, strong) NSLayoutConstraint *yk_mutualSureBottom;
@property (nonatomic, strong) NSLayoutConstraint *yk_mutualSureWidth;
@property (nonatomic, strong) NSLayoutConstraint *yk_mutualSureHeight;
@end

@implementation YKBondListViewController

- (instancetype)initWithKind:(YKBondListKind)kind {
    self = [super init];
    if (self) {
        _yk_kind = kind;
    }
    return self;
}

- (void)yk_configurePage {
    [super yk_configurePage];
    [self yk_setupTable];
    [self yk_setupEmptyState];
    [self yk_setupChrome];
    [self yk_setupMutualTipOverlay];
    [self yk_reloadRows];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    if (self.yk_twinHintOverlay) {
        [self yk_updateMutualTipHitRects];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self yk_reloadRows];
}

- (NSString *)yk_ownerKey {
    YKAccountVault *vault = [YKAccountVault sharedVault];
    if ([YKAccountVault yk_isReviewMailbox:vault.yk_activeMailbox ?: @""]) {
        return [YKPersonaCatalog yk_reviewPersonaId];
    }
    return vault.yk_activeMailbox.length > 0 ? vault.yk_activeMailbox : @"guest";
}

- (void)yk_setupChrome {
    UIButton *backButton = [self yk_addBackButton];

    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    titleLabel.text = (self.yk_kind == YKBondListKindInbound) ? [YKSigilForge yk_unveil:@"zp3IYTxq3Gjb3hnCBF06xA=="] : [YKSigilForge yk_unveil:@"mQ3A5aWGAwIw5fwUx6iQZw=="];
    titleLabel.textColor = UIColor.whiteColor;
    titleLabel.font = [UIFont fontWithName:@"Limelight" size:22.0] ?: [UIFont systemFontOfSize:22.0 weight:UIFontWeightBold];
    [self.view addSubview:titleLabel];

    [NSLayoutConstraint activateConstraints:@[
        [titleLabel.centerYAnchor constraintEqualToAnchor:backButton.centerYAnchor],
        [titleLabel.leadingAnchor constraintEqualToAnchor:backButton.trailingAnchor constant:2.0],
        [titleLabel.trailingAnchor constraintLessThanOrEqualToAnchor:self.view.trailingAnchor constant:-20.0]
    ]];
}

- (void)yk_setupEmptyState {
    UIView *emptyView = [[UIView alloc] init];
    emptyView.translatesAutoresizingMaskIntoConstraints = NO;
    emptyView.hidden = YES;
    [self.view addSubview:emptyView];
    self.yk_emptyView = emptyView;

    UIImageView *iconView = [[UIImageView alloc] initWithImage:[[UIImage imageNamed:@"empty_data"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]];
    iconView.translatesAutoresizingMaskIntoConstraints = NO;
    iconView.contentMode = UIViewContentModeScaleAspectFit;
    [emptyView addSubview:iconView];

    UILabel *hintLabel = [[UILabel alloc] init];
    hintLabel.translatesAutoresizingMaskIntoConstraints = NO;
    hintLabel.text = @"No data.";
    hintLabel.textColor = UIColor.whiteColor;
    hintLabel.textAlignment = NSTextAlignmentCenter;
    hintLabel.font = [UIFont systemFontOfSize:16.0 weight:UIFontWeightRegular];
    [emptyView addSubview:hintLabel];

    [NSLayoutConstraint activateConstraints:@[
        [emptyView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [emptyView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [emptyView.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor constant:-24.0],

        [iconView.topAnchor constraintEqualToAnchor:emptyView.topAnchor],
        [iconView.centerXAnchor constraintEqualToAnchor:emptyView.centerXAnchor],
        [iconView.widthAnchor constraintEqualToConstant:148.0],
        [iconView.heightAnchor constraintEqualToConstant:100.0],

        [hintLabel.topAnchor constraintEqualToAnchor:iconView.bottomAnchor constant:18.0],
        [hintLabel.leadingAnchor constraintEqualToAnchor:emptyView.leadingAnchor constant:24.0],
        [hintLabel.trailingAnchor constraintEqualToAnchor:emptyView.trailingAnchor constant:-24.0],
        [hintLabel.bottomAnchor constraintEqualToAnchor:emptyView.bottomAnchor]
    ]];
}

- (void)yk_setupTable {
    UITableView *tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    tableView.translatesAutoresizingMaskIntoConstraints = NO;
    tableView.backgroundColor = UIColor.clearColor;
    tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    tableView.showsVerticalScrollIndicator = NO;
    tableView.dataSource = self;
    tableView.delegate = self;
    tableView.rowHeight = 72.0;
    tableView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    [tableView registerClass:YKBondListCell.class forCellReuseIdentifier:kYKBondListCellId];
    [self.view addSubview:tableView];
    self.yk_tableView = tableView;

    [NSLayoutConstraint activateConstraints:@[
        [tableView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:56.0],
        [tableView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [tableView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [tableView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor]
    ]];
}

- (void)yk_reloadRows {
    NSString *owner = [self yk_ownerKey];
    [[YKBondLedger sharedLedger] yk_primeLinksForOwnerKey:owner];
    NSArray *raw = (self.yk_kind == YKBondListKindInbound)
        ? [[YKBondLedger sharedLedger] yk_inboundIdsForOwnerKey:owner]
        : [[YKBondLedger sharedLedger] yk_outboundIdsForOwnerKey:owner];

    NSMutableArray *filtered = [NSMutableArray array];
    for (NSString *personaId in raw) {
        if ([[YKShadeRoster sharedRoster] yk_ownerKey:owner hasShadedId:personaId]) {
            continue;
        }
        [filtered addObject:personaId];
    }
    self.yk_personaIds = filtered;
    BOOL empty = self.yk_personaIds.count == 0;
    self.yk_emptyView.hidden = !empty;
    self.yk_tableView.hidden = empty;
    [self.yk_tableView reloadData];
}

#pragma mark - Table

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return (NSInteger)self.yk_personaIds.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    YKBondListCell *cell = [tableView dequeueReusableCellWithIdentifier:kYKBondListCellId forIndexPath:indexPath];
    NSString *personaId = self.yk_personaIds[indexPath.row];
    NSDictionary *persona = [YKPersonaCatalog yk_personaWithId:personaId];
    UIImage *avatar = [YKPersonaCatalog yk_avatarImageForPersonaId:personaId] ?: [UIImage imageNamed:@"headplace"];
    NSString *owner = [self yk_ownerKey];
    BOOL linked = [[YKBondLedger sharedLedger] yk_ownerKey:owner isLinkedTo:personaId];

    NSString *title;
    BOOL filled;
    if (self.yk_kind == YKBondListKindOutbound) {
        title = [YKSigilForge yk_unveil:@"TS+hCnu1QPAtWym+i+DnWQ=="];
        filled = YES;
    } else {
        title = linked ? [YKSigilForge yk_unveil:@"TS+hCnu1QPAtWym+i+DnWQ=="] : [YKSigilForge yk_unveil:@"XloucoaA2i7z2gsuWyglLg=="];
        filled = linked;
    }
    [cell yk_configureName:persona[@"name"] ?: personaId avatar:avatar actionTitle:title filled:filled];

    __weak typeof(self) weakSelf = self;
    cell.yk_actionHandler = ^{
        [weakSelf yk_handleActionForPersonaId:personaId];
    };
    return cell;
}

- (void)yk_handleActionForPersonaId:(NSString *)personaId {
    NSString *owner = [self yk_ownerKey];
    YKBondLedger *ledger = [YKBondLedger sharedLedger];
    if (self.yk_kind == YKBondListKindOutbound) {
        [ledger yk_ownerKey:owner setLink:personaId on:NO];
        [self yk_reloadRows];
        return;
    }

    // Inbound: link back; already linked toggles off.
    BOOL linked = [ledger yk_ownerKey:owner isLinkedTo:personaId];
    [ledger yk_ownerKey:owner setLink:personaId on:!linked];
    [self yk_reloadRows];
}

#pragma mark - Twin hint (Following)

/// `mutual_link_tip` — design @3x 927×723 → 309×241 pt.
- (void)yk_setupMutualTipOverlay {
    UIView *overlay = [[UIView alloc] init];
    overlay.translatesAutoresizingMaskIntoConstraints = NO;
    overlay.hidden = YES;
    overlay.alpha = 0.0;
    overlay.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.55];
    [self.view addSubview:overlay];
    self.yk_twinHintOverlay = overlay;

    UIImageView *dialog = [[UIImageView alloc] initWithImage:[[UIImage imageNamed:@"mutual_link_tip"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]];
    dialog.translatesAutoresizingMaskIntoConstraints = NO;
    dialog.contentMode = UIViewContentModeScaleAspectFit;
    dialog.userInteractionEnabled = YES;
    [overlay addSubview:dialog];
    self.yk_twinHintDialog = dialog;

    UIButton *cancelHit = [UIButton buttonWithType:UIButtonTypeCustom];
    cancelHit.translatesAutoresizingMaskIntoConstraints = NO;
    cancelHit.accessibilityLabel = @"Cancel";
    [cancelHit addTarget:self action:@selector(yk_dismissTwinHint) forControlEvents:UIControlEventTouchUpInside];
    [dialog addSubview:cancelHit];

    UIButton *sureHit = [UIButton buttonWithType:UIButtonTypeCustom];
    sureHit.translatesAutoresizingMaskIntoConstraints = NO;
    sureHit.accessibilityLabel = @"Sure";
    [sureHit addTarget:self action:@selector(yk_dismissTwinHint) forControlEvents:UIControlEventTouchUpInside];
    [dialog addSubview:sureHit];

    self.yk_twinHintWidth = [dialog.widthAnchor constraintEqualToConstant:309.0];
    self.yk_twinHintHeight = [dialog.heightAnchor constraintEqualToConstant:241.0];
    self.yk_mutualCancelLeading = [cancelHit.leadingAnchor constraintEqualToAnchor:dialog.leadingAnchor constant:50.0];
    self.yk_mutualCancelBottom = [cancelHit.bottomAnchor constraintEqualToAnchor:dialog.bottomAnchor constant:-33.0];
    self.yk_mutualCancelWidth = [cancelHit.widthAnchor constraintEqualToConstant:100.0];
    self.yk_mutualCancelHeight = [cancelHit.heightAnchor constraintEqualToConstant:32.0];
    self.yk_mutualSureTrailing = [sureHit.trailingAnchor constraintEqualToAnchor:dialog.trailingAnchor constant:-36.0];
    self.yk_mutualSureBottom = [sureHit.bottomAnchor constraintEqualToAnchor:dialog.bottomAnchor constant:-33.0];
    self.yk_mutualSureWidth = [sureHit.widthAnchor constraintEqualToConstant:100.0];
    self.yk_mutualSureHeight = [sureHit.heightAnchor constraintEqualToConstant:32.0];

    [NSLayoutConstraint activateConstraints:@[
        [overlay.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [overlay.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [overlay.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [overlay.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],

        [dialog.centerXAnchor constraintEqualToAnchor:overlay.centerXAnchor],
        [dialog.centerYAnchor constraintEqualToAnchor:overlay.centerYAnchor constant:-6.0],
        self.yk_twinHintWidth,
        self.yk_twinHintHeight,

        self.yk_mutualCancelLeading,
        self.yk_mutualCancelBottom,
        self.yk_mutualCancelWidth,
        self.yk_mutualCancelHeight,

        self.yk_mutualSureTrailing,
        self.yk_mutualSureBottom,
        self.yk_mutualSureWidth,
        self.yk_mutualSureHeight
    ]];
}

/// Scales dialog + Cancel/Sure hit zones with screen width (base 309×241).
- (void)yk_updateMutualTipHitRects {
    CGFloat screenW = CGRectGetWidth(self.view.bounds);
    if (screenW <= 1.0) {
        return;
    }
    CGFloat dialogW = MIN(309.0, screenW - 48.0);
    CGFloat scale = dialogW / 309.0;
    self.yk_twinHintWidth.constant = dialogW;
    self.yk_twinHintHeight.constant = 241.0 * scale;
    // Cancel ≈ leading 50 / bottom 33 / 100×32；Sure ≈ trailing 36 / bottom 33 / 100×32
    self.yk_mutualCancelLeading.constant = 50.0 * scale;
    self.yk_mutualCancelBottom.constant = -33.0 * scale;
    self.yk_mutualCancelWidth.constant = 100.0 * scale;
    self.yk_mutualCancelHeight.constant = 32.0 * scale;
    self.yk_mutualSureTrailing.constant = -36.0 * scale;
    self.yk_mutualSureBottom.constant = -33.0 * scale;
    self.yk_mutualSureWidth.constant = 100.0 * scale;
    self.yk_mutualSureHeight.constant = 32.0 * scale;
}

- (void)yk_presentTwinHint {
    [self yk_updateMutualTipHitRects];
    self.yk_twinHintOverlay.hidden = NO;
    [self.view bringSubviewToFront:self.yk_twinHintOverlay];
    [UIView animateWithDuration:0.2 animations:^{
        self.yk_twinHintOverlay.alpha = 1.0;
    }];
}

- (void)yk_dismissTwinHint {
    [UIView animateWithDuration:0.18 animations:^{
        self.yk_twinHintOverlay.alpha = 0.0;
    } completion:^(BOOL finished) {
        self.yk_twinHintOverlay.hidden = YES;
    }];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row < 0 || indexPath.row >= (NSInteger)self.yk_personaIds.count) {
        return;
    }
    NSString *personaId = self.yk_personaIds[indexPath.row];
    NSString *owner = [self yk_ownerKey];
    BOOL mutual = [[YKBondLedger sharedLedger] yk_ownerKey:owner isTwinWith:personaId];

    // Followers / Following: chat only when mutual; otherwise show tip asset.
    if (!mutual) {
        [self yk_presentTwinHint];
        return;
    }
    YKThreadViewController *chat = [[YKThreadViewController alloc] initWithPersonaId:personaId];
    [self.navigationController pushViewController:chat animated:YES];
}

@end
