//
//  YKReportShadeSheet.h
//  Yoka
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// Pixel Report / Block / Cancel sheet (assets: report_button, shade_button, cancel_button @ 215×49).
/// Always centered on screen and presented above the tab bar (window-level).
@interface YKReportShadeSheet : NSObject

+ (void)yk_presentInView:(UIView *)hostView
                  report:(void (^)(void))reportHandler
                   block:(void (^)(void))blockHandler;

@end

NS_ASSUME_NONNULL_END
