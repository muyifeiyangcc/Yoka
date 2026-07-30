//
//  YKLegalDocViewController.h
//  Yoka
//

#import "YKAuthBaseViewController.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, YKLegalDocumentKind) {
    YKLegalDocumentKindTermsPact = 0,
    YKLegalDocumentKindPrivacyPolicy
};

/// Official site base (review / external links). App legal screens load bundled HTML.
FOUNDATION_EXPORT NSString * const YKOfficialSiteBaseURL;

@interface YKLegalDocViewController : YKAuthBaseViewController

/// Full page URL passed in when opening (e.g. …/users or …/privacy).
@property (nonatomic, copy) NSString *yk_protocolURL;

- (instancetype)initWithDocumentKind:(YKLegalDocumentKind)kind;

@end

NS_ASSUME_NONNULL_END
