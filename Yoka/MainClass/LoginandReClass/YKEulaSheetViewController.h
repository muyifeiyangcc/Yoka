//
//  YKEulaSheetViewController.h
//  Yoka
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface YKEulaSheetViewController : UIViewController

/// Presents the EULA sheet. On Agree, persists acceptance then calls completion with YES.
/// On Cancel / dismiss without agree, completion is called with NO (if provided).
+ (void)yk_presentFromViewController:(UIViewController *)presenter
                          completion:(void (^ _Nullable)(BOOL accepted))completion;

@end

NS_ASSUME_NONNULL_END
