//
//  YKSpinRingView.h
//  Yoka
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// Branded Yoka loading ring (magenta → purple). No caption — spinner only.
@interface YKSpinRingView : UIView

- (instancetype)initWithSide:(CGFloat)side;

- (void)yk_startSpinning;
- (void)yk_stopSpinning;

@end

NS_ASSUME_NONNULL_END
