//
//  YKInboxViewController.m
//  Yoka
//

#import "YKInboxViewController.h"
#import "YKThreadViewController.h"
#import "YKWhisperVault.h"
#import "YKShadeRoster.h"
#import "../LoginandReClass/YKAccountVault.h"
#import "../LoginandReClass/YKBondLedger.h"
#import "../LoginandReClass/YKPersonaCatalog.h"
#import "../../BaseClass/YKCenterToast.h"
#import "../../BaseClass/YKEmptyStateView.h"
#import "../../BaseClass/YKSigilForge.h"

@interface YKInboxRowCell : UITableViewCell

- (void)configureWithName:(NSString *)name
                  preview:(NSString *)preview
                timeLabel:(NSString *)timeLabel
               unreadText:(NSString *)unreadText
                   avatar:(UIImage *)avatar;

@end

@interface YKInboxRowCell ()

@property (nonatomic, strong) UIImageView *avatarImageView;
@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) UILabel *previewLabel;
@property (nonatomic, strong) UILabel *timeLabel;
@property (nonatomic, strong) UILabel *badgeLabel;

@end

@implementation YKInboxRowCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self yk_setupViews];
    }
    return self;
}

- (void)yk_setupViews {
    self.backgroundColor = UIColor.clearColor;
    self.contentView.backgroundColor = UIColor.clearColor;
    self.selectionStyle = UITableViewCellSelectionStyleNone;

    UIImageView *avatarImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"headplace"]];
    avatarImageView.translatesAutoresizingMaskIntoConstraints = NO;
    avatarImageView.contentMode = UIViewContentModeScaleAspectFill;
    avatarImageView.layer.cornerRadius = 25.0;
    avatarImageView.layer.masksToBounds = YES;
    [self.contentView addSubview:avatarImageView];
    self.avatarImageView = avatarImageView;

    UILabel *nameLabel = [[UILabel alloc] init];
    nameLabel.translatesAutoresizingMaskIntoConstraints = NO;
    nameLabel.textColor = UIColor.whiteColor;
    nameLabel.font = [UIFont systemFontOfSize:19.0 weight:UIFontWeightBold];
    [self.contentView addSubview:nameLabel];
    self.nameLabel = nameLabel;

    UILabel *previewLabel = [[UILabel alloc] init];
    previewLabel.translatesAutoresizingMaskIntoConstraints = NO;
    previewLabel.textColor = [UIColor colorWithWhite:1.0 alpha:0.68];
    previewLabel.font = [UIFont systemFontOfSize:12.0 weight:UIFontWeightRegular];
    previewLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    [self.contentView addSubview:previewLabel];
    self.previewLabel = previewLabel;

    UILabel *timeLabel = [[UILabel alloc] init];
    timeLabel.translatesAutoresizingMaskIntoConstraints = NO;
    timeLabel.textColor = [UIColor colorWithWhite:1.0 alpha:0.70];
    timeLabel.font = [UIFont systemFontOfSize:12.0 weight:UIFontWeightRegular];
    [self.contentView addSubview:timeLabel];
    self.timeLabel = timeLabel;

    UILabel *badgeLabel = [[UILabel alloc] init];
    badgeLabel.translatesAutoresizingMaskIntoConstraints = NO;
    badgeLabel.textAlignment = NSTextAlignmentCenter;
    badgeLabel.textColor = UIColor.whiteColor;
    badgeLabel.backgroundColor = [UIColor colorWithRed:1.0 green:0.52 blue:0.10 alpha:1.0];
    badgeLabel.font = [UIFont systemFontOfSize:11.0 weight:UIFontWeightBold];
    badgeLabel.layer.cornerRadius = 9.0;
    badgeLabel.layer.masksToBounds = YES;
    [self.contentView addSubview:badgeLabel];
    self.badgeLabel = badgeLabel;

    [NSLayoutConstraint activateConstraints:@[
        [avatarImageView.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:22.0],
        [avatarImageView.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],
        [avatarImageView.widthAnchor constraintEqualToConstant:50.0],
        [avatarImageView.heightAnchor constraintEqualToConstant:50.0],

        [nameLabel.leadingAnchor constraintEqualToAnchor:avatarImageView.trailingAnchor constant:18.0],
        [nameLabel.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:7.0],
        [nameLabel.trailingAnchor constraintLessThanOrEqualToAnchor:timeLabel.leadingAnchor constant:-12.0],

        [previewLabel.leadingAnchor constraintEqualToAnchor:nameLabel.leadingAnchor],
        [previewLabel.topAnchor constraintEqualToAnchor:nameLabel.bottomAnchor constant:7.0],
        [previewLabel.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-88.0],

        [timeLabel.topAnchor constraintEqualToAnchor:nameLabel.topAnchor constant:2.0],
        [timeLabel.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-24.0],

        [badgeLabel.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-28.0],
        [badgeLabel.centerYAnchor constraintEqualToAnchor:previewLabel.centerYAnchor],
        [badgeLabel.widthAnchor constraintGreaterThanOrEqualToConstant:18.0],
        [badgeLabel.heightAnchor constraintEqualToConstant:18.0]
    ]];
}

- (void)prepareForReuse {
    [super prepareForReuse];
    self.badgeLabel.hidden = YES;
    self.avatarImageView.image = [UIImage imageNamed:@"headplace"];
}

- (void)configureWithName:(NSString *)name
                  preview:(NSString *)preview
                timeLabel:(NSString *)timeLabel
               unreadText:(NSString *)unreadText
                   avatar:(UIImage *)avatar {
    self.nameLabel.text = name;
    self.previewLabel.text = preview;
    self.timeLabel.text = timeLabel;
    self.badgeLabel.text = unreadText;
    self.badgeLabel.hidden = unreadText.length == 0;
    if (avatar) {
        self.avatarImageView.image = [avatar imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    }
}

@end

@interface YKInboxViewController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) YKEmptyStateView *yk_emptyView;
@property (nonatomic, copy) NSArray<NSDictionary<NSString *, id> *> *messages;

@end

@implementation YKInboxViewController

- (void)yk_configurePage {
    [super yk_configurePage];
    [self yk_setupHeaderView];
    [self yk_setupTableView];
    [self yk_reloadInbox];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(yk_reloadInbox)
                                                 name:YokaWhisperLinesDidShiftNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(yk_reloadInbox)
                                                 name:YokaShadeRosterDidShiftNotification
                                               object:nil];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self yk_reloadInbox];
}

- (NSString *)yk_ownerKey {
    YKAccountVault *vault = [YKAccountVault sharedVault];
    if ([YKAccountVault yk_isReviewMailbox:vault.yk_activeMailbox ?: @""]) {
        return [YKPersonaCatalog yk_reviewPersonaId];
    }
    NSDictionary *dossier = [vault yk_dossierForActiveMailbox];
    NSString *personaId = dossier[@"personaId"];
    if ([personaId isKindOfClass:NSString.class] && personaId.length > 0) {
        return personaId;
    }
    return vault.yk_activeMailbox ?: @"guest";
}

- (void)yk_setupHeaderView {
    UIImageView *titleImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"inbox_title"]];
    titleImageView.translatesAutoresizingMaskIntoConstraints = NO;
    titleImageView.contentMode = UIViewContentModeScaleAspectFit;
    [self.view addSubview:titleImageView];

    [NSLayoutConstraint activateConstraints:@[
        [titleImageView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:22.0],
        [titleImageView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:24.0],
        [titleImageView.widthAnchor constraintEqualToConstant:107.0],
        [titleImageView.heightAnchor constraintEqualToConstant:30.0]
    ]];
}

- (void)yk_setupTableView {
    UITableView *tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    tableView.translatesAutoresizingMaskIntoConstraints = NO;
    tableView.backgroundColor = UIColor.clearColor;
    tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    tableView.showsVerticalScrollIndicator = NO;
    tableView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    tableView.rowHeight = 72.0;
    tableView.dataSource = self;
    tableView.delegate = self;
    [tableView registerClass:YKInboxRowCell.class forCellReuseIdentifier:@"YKInboxRowCell"];
    [self.view addSubview:tableView];
    self.tableView = tableView;

    [NSLayoutConstraint activateConstraints:@[
        [tableView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:76.0],
        [tableView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [tableView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [tableView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor constant:-92.0]
    ]];

    self.yk_emptyView = [YKEmptyStateView yk_viewEmbeddedIn:self.view
                                                relativeTo:self.view.safeAreaLayoutGuide
                                            centerYOffset:-20.0];
}

- (void)yk_reloadInbox {
    NSString *ownerKey = [self yk_ownerKey];
    [[YKBondLedger sharedLedger] yk_primeLinksForOwnerKey:ownerKey];
    [[YKWhisperVault sharedVault] yk_ensureReviewLinesForOwnerKey:ownerKey];

    NSArray<NSString *> *mutualIds = [[YKBondLedger sharedLedger] yk_twinIdsForOwnerKey:ownerKey];
    NSMutableArray<NSDictionary *> *rows = [NSMutableArray array];
    for (NSString *peerId in mutualIds) {
        if ([[YKShadeRoster sharedRoster] yk_ownerKey:ownerKey hasShadedId:peerId]) {
            continue;
        }
        NSDictionary *persona = [YKPersonaCatalog yk_personaWithId:peerId];
        NSDictionary *preview = [[YKWhisperVault sharedVault] yk_previewForOwnerKey:ownerKey peerId:peerId];
        [rows addObject:@{
            @"personaId": peerId,
            @"name": persona[@"name"] ?: peerId,
            @"preview": preview[@"preview"] ?: @"",
            @"timeLabel": preview[@"timeLabel"] ?: @"",
            @"stamp": preview[@"stamp"] ?: @0,
            @"badge": @""
        }];
    }
    [rows sortUsingComparator:^NSComparisonResult(NSDictionary *a, NSDictionary *b) {
        return [b[@"stamp"] compare:a[@"stamp"]];
    }];
    self.messages = rows;
    BOOL empty = self.messages.count == 0;
    self.yk_emptyView.hidden = !empty;
    self.tableView.hidden = empty;
    [self.tableView reloadData];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.messages.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    YKInboxRowCell *cell = [tableView dequeueReusableCellWithIdentifier:@"YKInboxRowCell" forIndexPath:indexPath];
    NSDictionary *message = self.messages[indexPath.row];
    UIImage *avatar = [YKPersonaCatalog yk_avatarImageForPersonaId:message[@"personaId"]];
    [cell configureWithName:message[@"name"]
                    preview:message[@"preview"]
                  timeLabel:message[@"timeLabel"]
                 unreadText:message[@"badge"]
                     avatar:avatar];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *message = self.messages[indexPath.row];
    NSString *peerId = message[@"personaId"];
    NSString *ownerKey = [self yk_ownerKey];
    if (![[YKBondLedger sharedLedger] yk_ownerKey:ownerKey isTwinWith:peerId]) {
        [YKCenterToast yk_showNotice:[YKSigilForge yk_unveil:@"tHJ77R5VpDfk4eMaeqkiQbcZjEnFkZFfXJJfcX1bmXQ="] inView:self.view];
        return;
    }
    YKThreadViewController *threadVC = [[YKThreadViewController alloc] initWithPersonaId:peerId];
    [self.navigationController pushViewController:threadVC animated:YES];
}

@end
