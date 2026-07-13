//
//  YKCustomTabBarView.h
//  Yoka
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class YKCustomTabBarView;

@protocol YKCustomTabBarViewDelegate <NSObject>

- (void)customTabBarView:(YKCustomTabBarView *)tabBarView didSelectIndex:(NSInteger)index;
@optional
- (void)customTabBarViewDidTapPublish:(YKCustomTabBarView *)tabBarView;

@end

@interface YKCustomTabBarView : UIView

@property (nonatomic, weak, nullable) id<YKCustomTabBarViewDelegate> delegate;
@property (nonatomic, assign) NSInteger selectedIndex;

@end

NS_ASSUME_NONNULL_END
