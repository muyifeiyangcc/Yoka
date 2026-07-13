//
//  YKMessageViewController.m
//  Yoka
//

#import "YKMessageViewController.h"
#import "YKChatViewController.h"

@interface YKMessageCell : UITableViewCell

- (void)configureWithName:(NSString *)name preview:(NSString *)preview unreadText:(NSString *)unreadText tintColor:(UIColor *)tintColor;

@end

@interface YKMessageCell ()

@property (nonatomic, strong) UIImageView *avatarImageView;
@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) UILabel *previewLabel;
@property (nonatomic, strong) UILabel *timeLabel;
@property (nonatomic, strong) UILabel *badgeLabel;

@end

@implementation YKMessageCell

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
    timeLabel.text = @"1 m ago";
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
    self.badgeLabel.hidden = NO;
    self.avatarImageView.backgroundColor = UIColor.clearColor;
}

- (void)configureWithName:(NSString *)name preview:(NSString *)preview unreadText:(NSString *)unreadText tintColor:(UIColor *)tintColor {
    self.nameLabel.text = name;
    self.previewLabel.text = preview;
    self.badgeLabel.text = unreadText;
    self.badgeLabel.hidden = unreadText.length == 0;
    self.avatarImageView.backgroundColor = tintColor;
}

@end

@interface YKMessageViewController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, copy) NSArray<NSDictionary<NSString *, id> *> *messages;

@end

@implementation YKMessageViewController

- (void)yk_configurePage {
    [super yk_configurePage];

    self.messages = [self yk_makeMessages];
    [self yk_setupHeaderView];
    [self yk_setupTableView];
}

- (void)yk_setupHeaderView {
    UIImageView *backImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"nav_back"]];
    backImageView.translatesAutoresizingMaskIntoConstraints = NO;
    backImageView.contentMode = UIViewContentModeScaleAspectFit;
    [self.view addSubview:backImageView];

    UIImageView *titleImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Messegeleft"]];
    titleImageView.translatesAutoresizingMaskIntoConstraints = NO;
    titleImageView.contentMode = UIViewContentModeScaleAspectFit;
    [self.view addSubview:titleImageView];

    [NSLayoutConstraint activateConstraints:@[
        [backImageView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:25.0],
        [backImageView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:24.0],
        [backImageView.widthAnchor constraintEqualToConstant:22.0],
        [backImageView.heightAnchor constraintEqualToConstant:22.0],

        [titleImageView.centerYAnchor constraintEqualToAnchor:backImageView.centerYAnchor],
        [titleImageView.leadingAnchor constraintEqualToAnchor:backImageView.trailingAnchor constant:10.0],
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
    [tableView registerClass:YKMessageCell.class forCellReuseIdentifier:@"YKMessageCell"];
    [self.view addSubview:tableView];
    self.tableView = tableView;

    [NSLayoutConstraint activateConstraints:@[
        [tableView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:76.0],
        [tableView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [tableView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [tableView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor constant:-92.0]
    ]];
}

- (NSArray<NSDictionary<NSString *, id> *> *)yk_makeMessages {
    NSArray<NSString *> *names = @[@"Freya", @"Stellan", @"Lumi", @"Bodhi", @"Alina"];
    NSArray<NSString *> *badges = @[@"", @"3", @"3", @"3", @"3"];
    NSArray<UIColor *> *colors = @[
        [UIColor colorWithRed:0.56 green:0.33 blue:0.32 alpha:1.0],
        [UIColor colorWithRed:0.24 green:0.21 blue:0.16 alpha:1.0],
        [UIColor colorWithRed:0.86 green:0.39 blue:0.42 alpha:1.0],
        [UIColor colorWithRed:0.20 green:0.26 blue:0.28 alpha:1.0],
        [UIColor colorWithRed:0.78 green:0.64 blue:0.74 alpha:1.0]
    ];

    NSMutableArray<NSDictionary<NSString *, id> *> *messages = [NSMutableArray arrayWithCapacity:names.count];
    for (NSInteger index = 0; index < names.count; index++) {
        [messages addObject:@{
            @"name": names[index],
            @"preview": @"I love your style! Can you gi...",
            @"badge": badges[index],
            @"color": colors[index]
        }];
    }
    return messages;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.messages.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    YKMessageCell *cell = [tableView dequeueReusableCellWithIdentifier:@"YKMessageCell" forIndexPath:indexPath];
    NSDictionary<NSString *, id> *message = self.messages[indexPath.row];
    [cell configureWithName:message[@"name"] preview:message[@"preview"] unreadText:message[@"badge"] tintColor:message[@"color"]];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary<NSString *, id> *message = self.messages[indexPath.row];
    YKChatViewController *chatViewController = [[YKChatViewController alloc] initWithUserName:message[@"name"]
                                                                                    tintColor:message[@"color"]];
    [self.navigationController pushViewController:chatViewController animated:YES];
}

@end
