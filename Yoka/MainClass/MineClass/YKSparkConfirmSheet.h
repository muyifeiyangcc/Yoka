//
//  YKSparkConfirmSheet.h
//  Yoka
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// Pixel-style purchase confirm (Cancel / Sure), matching enough / logout sheets.
@interface YKSparkConfirmSheet : NSObject

+ (void)yk_presentInView:(UIView *)hostView
                sparkQty:(NSInteger)sparkQty
                   price:(NSString *)price
                  cancel:(void (^ _Nullable)(void))cancel
                    sure:(void (^ _Nullable)(void))sure;

@end

NS_ASSUME_NONNULL_END
