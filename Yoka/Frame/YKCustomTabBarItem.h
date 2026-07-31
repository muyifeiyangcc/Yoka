//
//  YKCustomTabBarItem.h
//  Yoka
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface YKCustomTabBarItem : UIControl

- (instancetype)initWithNormalImageName:(NSString *)normalImageName
                      selectedImageName:(NSString *)selectedImageName
                     accessibilityTitle:(NSString *)accessibilityTitle NS_DESIGNATED_INITIALIZER;

- (instancetype)initWithFrame:(CGRect)frame NS_UNAVAILABLE;
- (instancetype)initWithCoder:(NSCoder *)coder NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
