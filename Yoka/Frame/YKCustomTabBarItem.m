//
//  YKCustomTabBarItem.m
//  Yoka
//

#import "YKCustomTabBarItem.h"

@interface YKCustomTabBarItem ()

@property (nonatomic, strong) UIImageView *iconImageView;
@property (nonatomic, strong) UIImage *normalImage;
@property (nonatomic, strong) UIImage *selectedImage;

@end

@implementation YKCustomTabBarItem

- (instancetype)initWithNormalImageName:(NSString *)normalImageName
                      selectedImageName:(NSString *)selectedImageName
                     accessibilityTitle:(NSString *)accessibilityTitle {
    self = [super initWithFrame:CGRectZero];
    if (self) {
        _normalImage = [[UIImage imageNamed:normalImageName] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
        _selectedImage = [[UIImage imageNamed:selectedImageName] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
        self.isAccessibilityElement = YES;
        self.accessibilityLabel = accessibilityTitle;
        self.accessibilityTraits = UIAccessibilityTraitButton;
        [self yk_setupViews];
        [self yk_updateSelectedState];
    }
    return self;
}

- (void)yk_setupViews {
    self.translatesAutoresizingMaskIntoConstraints = NO;
    self.layer.cornerRadius = 18.0;
    self.layer.masksToBounds = YES;

    UIImageView *iconImageView = [[UIImageView alloc] init];
    iconImageView.translatesAutoresizingMaskIntoConstraints = NO;
    iconImageView.contentMode = UIViewContentModeScaleAspectFit;
    iconImageView.userInteractionEnabled = NO;
    [self addSubview:iconImageView];
    self.iconImageView = iconImageView;

    [NSLayoutConstraint activateConstraints:@[
        [iconImageView.centerXAnchor constraintEqualToAnchor:self.centerXAnchor],
        [iconImageView.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],
        [iconImageView.widthAnchor constraintEqualToConstant:36.0],
        [iconImageView.heightAnchor constraintEqualToConstant:36.0]
    ]];
}

- (void)setSelected:(BOOL)selected {
    [super setSelected:selected];
    [self yk_updateSelectedState];
}

- (void)yk_updateSelectedState {
    self.iconImageView.image = self.selected ? self.selectedImage : self.normalImage;
    self.backgroundColor = self.selected ? UIColor.whiteColor : [UIColor colorWithWhite:1.0 alpha:0.18];
    self.accessibilityTraits = self.selected ? (UIAccessibilityTraitButton | UIAccessibilityTraitSelected) : UIAccessibilityTraitButton;
}

@end
