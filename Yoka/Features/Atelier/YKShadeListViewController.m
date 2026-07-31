//
//  YKShadeListViewController.m
//  Yoka
//

#import "YKShadeListViewController.h"
#import "YKRosterVault.h"
#import "YKPersonaCatalog.h"
#import "YKShadeRoster.h"
#import "YKCenterToast.h"
#import "YKCipherLoom.h"

static NSString * const kYKShadeListCellId = @"YKShadeListCell";

@interface YKShadeListCell : UITableViewCell
@property (nonatomic, strong) UIImageView *yk_avatarView;
@property (nonatomic, strong) UILabel *yk_nameLabel;
@property (nonatomic, strong) UIButton *yk_removeButton;
@property (nonatomic, copy) void (^yk_removeHandler)(void);
- (void)yk_configureName:(NSString *)name avatar:(UIImage *)avatar;
@end

@implementation YKShadeListCell

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

        UIButton *remove = [UIButton buttonWithType:UIButtonTypeCustom];
        remove.translatesAutoresizingMaskIntoConstraints = NO;
        remove.backgroundColor = UIColor.whiteColor;
        remove.layer.cornerRadius = 14.0;
        remove.layer.borderWidth = 1.5;
        remove.layer.borderColor = UIColor.blackColor.CGColor;
        remove.titleLabel.font = [UIFont systemFontOfSize:14.0 weight:UIFontWeightMedium];
        [remove setTitle:@"Remove" forState:UIControlStateNormal];
        [remove setTitleColor:UIColor.blackColor forState:UIControlStateNormal];
        remove.contentEdgeInsets = UIEdgeInsetsMake(0.0, 14.0, 0.0, 14.0);
        [remove addTarget:self action:@selector(yk_removeTapped) forControlEvents:UIControlEventTouchUpInside];
        [self.contentView addSubview:remove];
        self.yk_removeButton = remove;

        [NSLayoutConstraint activateConstraints:@[
            [avatar.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:24.0],
            [avatar.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],
            [avatar.widthAnchor constraintEqualToConstant:44.0],
            [avatar.heightAnchor constraintEqualToConstant:44.0],

            [remove.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-24.0],
            [remove.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],
            [remove.heightAnchor constraintEqualToConstant:28.0],
            [remove.widthAnchor constraintGreaterThanOrEqualToConstant:88.0],

            [name.leadingAnchor constraintEqualToAnchor:avatar.trailingAnchor constant:14.0],
            [name.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],
            [name.trailingAnchor constraintLessThanOrEqualToAnchor:remove.leadingAnchor constant:-12.0]
        ]];
    }
    return self;
}

- (void)yk_configureName:(NSString *)name avatar:(UIImage *)avatar {
    self.yk_nameLabel.text = name;
    self.yk_avatarView.image = [avatar imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
}

- (void)yk_removeTapped {
    if (self.yk_removeHandler) {
        self.yk_removeHandler();
    }
}

@end

@interface YKShadeListViewController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) UITableView *yk_tableView;
@property (nonatomic, strong) UIView *yk_emptyView;
@property (nonatomic, copy) NSArray<NSString *> *yk_shadedIds;

@end

@implementation YKShadeListViewController

- (void)yk_configurePage {
    [super yk_configurePage];
    [self yk_setupTable];
    [self yk_setupEmptyState];
    [self yk_setupChrome];
    [self yk_reloadShadeList];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self yk_reloadShadeList];
}

- (void)yk_setupChrome {
    UIButton *backButton = [self yk_addBackButton];

    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    titleLabel.text = [YKCipherLoom yk_unfurl:@"97VL1hDna+zNOfXwJ4sORw=="];
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
    [tableView registerClass:YKShadeListCell.class forCellReuseIdentifier:kYKShadeListCellId];
    [self.view addSubview:tableView];
    self.yk_tableView = tableView;

    [NSLayoutConstraint activateConstraints:@[
        [tableView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:56.0],
        [tableView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [tableView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [tableView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor]
    ]];
}

- (NSString *)yk_ownerKey {
    YKRosterVault *vault = [YKRosterVault sharedRoster];
    if ([YKRosterVault yk_isReviewMailbox:vault.yk_activeMailbox ?: @""]) {
        return [YKPersonaCatalog yk_reviewPersonaId];
    }
    return vault.yk_activeMailbox.length > 0 ? vault.yk_activeMailbox : @"guest";
}

- (NSArray<NSString *> *)yk_loadBlockedIds {
    return [[YKShadeRoster sharedRoster] yk_shadedIdsForOwnerKey:[self yk_ownerKey]];
}

- (void)yk_reloadShadeList {
    self.yk_shadedIds = [self yk_loadBlockedIds];
    BOOL empty = self.yk_shadedIds.count == 0;
    self.yk_emptyView.hidden = !empty;
    self.yk_tableView.hidden = empty;
    [self.yk_tableView reloadData];
}

#pragma mark - UITableView

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return (NSInteger)self.yk_shadedIds.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    YKShadeListCell *cell = [tableView dequeueReusableCellWithIdentifier:kYKShadeListCellId forIndexPath:indexPath];
    NSString *personaId = self.yk_shadedIds[indexPath.row];
    NSDictionary *persona = [YKPersonaCatalog yk_personaWithId:personaId];
    UIImage *avatar = [YKPersonaCatalog yk_avatarImageForPersonaId:personaId] ?: [UIImage imageNamed:@"headplace"];
    [cell yk_configureName:persona[@"name"] ?: personaId avatar:avatar];

    __weak typeof(self) weakSelf = self;
    cell.yk_removeHandler = ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) {
            return;
        }
        [YKCenterToast yk_showLoadingInView:strongSelf.view performAfterDelay:0.3 work:^{
            [[YKShadeRoster sharedRoster] yk_ownerKey:[strongSelf yk_ownerKey] unshadeId:personaId];
            [strongSelf yk_reloadShadeList];
        }];
    };
    return cell;
}

@end
