//
//  YKEmptyStateView.h
//  Yoka
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// Shared nodata empty state: `empty_data` + "No data."
@interface YKEmptyStateView : UIView

/// Builds content only — caller owns positioning constraints.
- (instancetype)init;

/// Convenience: pin leading/trailing + centerY in `host`.
+ (instancetype)yk_viewEmbeddedIn:(UIView *)host
                     relativeTo:(nullable UILayoutGuide *)guide
                     centerYOffset:(CGFloat)offset;

@end

NS_ASSUME_NONNULL_END
