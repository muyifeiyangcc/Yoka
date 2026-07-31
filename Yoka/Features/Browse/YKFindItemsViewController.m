//
//  YKFindItemsViewController.m
//  Yoka
//

#import "YKFindItemsViewController.h"
#import "YKPublishLedger.h"

@interface YKFindItemCell : UITableViewCell

- (void)yk_configureWithItem:(NSDictionary *)item index:(NSInteger)index;

@end

@interface YKFindItemCell ()

@property (nonatomic, strong) UIView *containerView;
@property (nonatomic, strong) UIImageView *itemImageView;
@property (nonatomic, strong) UILabel *brandLabel;
@property (nonatomic, strong) UILabel *priceLabel;
@property (nonatomic, strong) UILabel *descriptionLabel;

@end

@implementation YKFindItemCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self yk_setupViews];
    }
    return self;
}

- (void)yk_setupViews {
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    self.backgroundColor = UIColor.clearColor;
    self.contentView.backgroundColor = UIColor.clearColor;

    UIView *containerView = [[UIView alloc] init];
    containerView.translatesAutoresizingMaskIntoConstraints = NO;
    containerView.layer.borderWidth = 2.0;
    [self.contentView addSubview:containerView];
    self.containerView = containerView;

    UIImageView *itemImageView = [[UIImageView alloc] init];
    itemImageView.translatesAutoresizingMaskIntoConstraints = NO;
    itemImageView.contentMode = UIViewContentModeScaleAspectFill;
    itemImageView.clipsToBounds = YES;
    itemImageView.backgroundColor = [UIColor colorWithWhite:0.88 alpha:1.0];
    itemImageView.layer.borderWidth = 1.0;
    [containerView addSubview:itemImageView];
    self.itemImageView = itemImageView;

    UILabel *brandLabel = [[UILabel alloc] init];
    brandLabel.translatesAutoresizingMaskIntoConstraints = NO;
    brandLabel.font = [UIFont systemFontOfSize:17.0 weight:UIFontWeightBold];
    [containerView addSubview:brandLabel];
    self.brandLabel = brandLabel;

    UILabel *priceLabel = [[UILabel alloc] init];
    priceLabel.translatesAutoresizingMaskIntoConstraints = NO;
    priceLabel.textColor = [UIColor colorWithRed:0.96 green:0.64 blue:0.22 alpha:1.0];
    priceLabel.font = [UIFont systemFontOfSize:16.0 weight:UIFontWeightBold];
    [containerView addSubview:priceLabel];
    self.priceLabel = priceLabel;

    UILabel *descriptionLabel = [[UILabel alloc] init];
    descriptionLabel.translatesAutoresizingMaskIntoConstraints = NO;
    descriptionLabel.numberOfLines = 0;
    descriptionLabel.font = [UIFont systemFontOfSize:11.0 weight:UIFontWeightRegular];
    [containerView addSubview:descriptionLabel];
    self.descriptionLabel = descriptionLabel;

    [NSLayoutConstraint activateConstraints:@[
        [containerView.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:10.0],
        [containerView.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:22.0],
        [containerView.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-22.0],
        [containerView.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor constant:-10.0],

        [itemImageView.leadingAnchor constraintEqualToAnchor:containerView.leadingAnchor constant:14.0],
        [itemImageView.topAnchor constraintEqualToAnchor:containerView.topAnchor constant:14.0],
        [itemImageView.widthAnchor constraintEqualToConstant:94.0],
        [itemImageView.heightAnchor constraintEqualToConstant:100.0],
        [itemImageView.bottomAnchor constraintLessThanOrEqualToAnchor:containerView.bottomAnchor constant:-14.0],

        [brandLabel.topAnchor constraintEqualToAnchor:itemImageView.topAnchor constant:5.0],
        [brandLabel.leadingAnchor constraintEqualToAnchor:itemImageView.trailingAnchor constant:12.0],
        [brandLabel.trailingAnchor constraintEqualToAnchor:containerView.trailingAnchor constant:-10.0],

        [priceLabel.topAnchor constraintEqualToAnchor:brandLabel.bottomAnchor constant:5.0],
        [priceLabel.leadingAnchor constraintEqualToAnchor:brandLabel.leadingAnchor],
        [priceLabel.trailingAnchor constraintEqualToAnchor:brandLabel.trailingAnchor],

        [descriptionLabel.topAnchor constraintEqualToAnchor:priceLabel.bottomAnchor constant:8.0],
        [descriptionLabel.leadingAnchor constraintEqualToAnchor:brandLabel.leadingAnchor],
        [descriptionLabel.trailingAnchor constraintEqualToAnchor:brandLabel.trailingAnchor],
        [descriptionLabel.bottomAnchor constraintEqualToAnchor:containerView.bottomAnchor constant:-14.0],
        [containerView.bottomAnchor constraintGreaterThanOrEqualToAnchor:itemImageView.bottomAnchor constant:14.0]
    ]];
}

- (void)yk_configureWithItem:(NSDictionary *)item index:(NSInteger)index {
    BOOL highlighted = index % 2 == 1;
    self.containerView.backgroundColor = highlighted ? [UIColor colorWithRed:0.90 green:0.31 blue:0.93 alpha:0.82] : UIColor.whiteColor;
    self.containerView.layer.borderColor = highlighted ? UIColor.whiteColor.CGColor : UIColor.blackColor.CGColor;
    UIColor *textColor = highlighted ? UIColor.whiteColor : UIColor.blackColor;
    self.brandLabel.textColor = textColor;
    self.descriptionLabel.textColor = highlighted ? [UIColor colorWithWhite:1.0 alpha:0.84] : [UIColor colorWithWhite:0.0 alpha:0.78];
    self.itemImageView.layer.borderColor = highlighted ? UIColor.whiteColor.CGColor : [UIColor colorWithWhite:0.75 alpha:1.0].CGColor;

    NSString *imageName = item[@"image"];
    UIImage *image = nil;
    if (imageName.length > 0) {
        image = [[UIImage imageNamed:imageName] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    }
    if (!image) {
        image = [[YKPublishLedger yk_goodsImageForItem:item] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    }
    self.itemImageView.image = image;

    NSString *brand = item[@"brand"] ?: @"";
    NSString *price = item[@"price"] ?: @"";
    NSString *desc = item[@"description"] ?: @"";
    self.brandLabel.text = [NSString stringWithFormat:@"Brand: %@", brand];
    self.priceLabel.text = [NSString stringWithFormat:@"Price: %@", price];
    self.descriptionLabel.text = desc;
}

@end

@interface YKFindItemsViewController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, copy) NSArray<NSDictionary *> *items;
@property (nonatomic, strong) UITableView *tableView;

@end

@implementation YKFindItemsViewController

- (instancetype)initWithItems:(NSArray<NSDictionary *> *)items {
    self = [super init];
    if (self) {
        _items = [items copy] ?: @[];
    }
    return self;
}

- (instancetype)init {
    return [self initWithItems:@[]];
}

- (void)yk_configurePage {
    [super yk_configurePage];
    [self yk_setupViews];
}

- (void)yk_setupViews {
    [self yk_addBackButton];

    UITableView *tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    tableView.translatesAutoresizingMaskIntoConstraints = NO;
    tableView.backgroundColor = UIColor.clearColor;
    tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    tableView.showsVerticalScrollIndicator = NO;
    tableView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    tableView.estimatedRowHeight = 160.0;
    tableView.rowHeight = UITableViewAutomaticDimension;
    tableView.dataSource = self;
    tableView.delegate = self;
    [tableView registerClass:YKFindItemCell.class forCellReuseIdentifier:@"YKFindItemCell"];
    [self.view addSubview:tableView];
    self.tableView = tableView;

    [NSLayoutConstraint activateConstraints:@[
        [tableView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:70.0],
        [tableView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [tableView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [tableView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor constant:-24.0]
    ]];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return (NSInteger)self.items.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    YKFindItemCell *cell = [tableView dequeueReusableCellWithIdentifier:@"YKFindItemCell" forIndexPath:indexPath];
    NSDictionary *item = (indexPath.row < (NSInteger)self.items.count) ? self.items[indexPath.row] : @{};
    [cell yk_configureWithItem:item index:indexPath.row];
    return cell;
}

@end
