//
//  YKBaseViewController.h
//  Yoka
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface YKBaseViewController : UIViewController

@property (nonatomic, strong, readonly) UIImageView *backgroundImageView;

- (void)yk_configurePage;
- (UIButton *)yk_addBackButton;
- (UIButton *)yk_addBackButtonWithTitle:(nullable NSString *)title;
- (void)yk_backButtonTapped:(UIButton *)sender;

@end

NS_ASSUME_NONNULL_END
