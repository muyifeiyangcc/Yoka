//
//  YKLegalDocViewController.m
//  Yoka
//

#import "YKLegalDocViewController.h"
#import <WebKit/WebKit.h>

NSString * const YKOfficialSiteBaseURL = @"https://app.n3dwzr85.link/";

/// Keep white text / transparent page even if remote CSS changes.
static NSString * YKLegalThemeJavaScript(void) {
    return
    @"(function(){"
    "function paint(){"
    "var css='html,body,#app{background:transparent!important;background-color:rgba(0,0,0,0)!important;}"
    "body,body *,#app,#app *,html{color:#ffffff!important;-webkit-text-fill-color:#ffffff!important;"
    "background:transparent!important;background-color:transparent!important;"
    "text-shadow:0 1px 2px rgba(0,0,0,0.92),0 0 6px rgba(0,0,0,0.55)!important;}"
    "a,a *{color:#ffffff!important;-webkit-text-fill-color:#ffffff!important;}';"
    "var s=document.getElementById('yk-legal-theme');"
    "if(!s){s=document.createElement('style');s.id='yk-legal-theme';"
    "(document.head||document.documentElement).appendChild(s);}"
    "s.textContent=css;"
    "}"
    "paint();"
    "setTimeout(paint,80);setTimeout(paint,300);"
    "})();";
}

@interface YKLegalDocViewController () <WKNavigationDelegate>

@property (nonatomic, assign) YKLegalDocumentKind yk_documentKind;
@property (nonatomic, strong) WKWebView *yk_docView;
@property (nonatomic, strong) UIButton *yk_backButton;
@property (nonatomic, strong) UIView *yk_progressTrackView;
@property (nonatomic, strong) UIView *yk_progressFillView;
@property (nonatomic, strong) NSLayoutConstraint *yk_progressWidthConstraint;
@property (nonatomic, strong) UILabel *yk_titleLabel;

@end

@implementation YKLegalDocViewController

- (instancetype)initWithDocumentKind:(YKLegalDocumentKind)kind {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _yk_documentKind = kind;
        switch (kind) {
            case YKLegalDocumentKindPrivacyPolicy:
                _yk_protocolURL = [YKOfficialSiteBaseURL stringByAppendingString:@"privacy"];
                break;
            case YKLegalDocumentKindTermsPact:
            default:
                _yk_protocolURL = [YKOfficialSiteBaseURL stringByAppendingString:@"users"];
                break;
        }
    }
    return self;
}

- (void)dealloc {
    @try {
        [self.yk_docView removeObserver:self forKeyPath:@"estimatedProgress"];
    } @catch (__unused NSException *exception) {
    }
}

- (void)yk_configurePage {
    [super yk_configurePage];
    [self yk_setupChrome];
    [self yk_setupDocView];
    [self yk_loadDocument];
}

- (NSString *)yk_pageTitle {
    switch (self.yk_documentKind) {
        case YKLegalDocumentKindPrivacyPolicy:
            return @"Privacy Policy";
        case YKLegalDocumentKindTermsPact:
        default:
            return @"User Agreement";
    }
}

- (NSString *)yk_localHTMLResourceName {
    switch (self.yk_documentKind) {
        case YKLegalDocumentKindPrivacyPolicy:
            return @"privacy";
        case YKLegalDocumentKindTermsPact:
        default:
            return @"users";
    }
}

- (NSURL *)yk_bundledLegalHTMLURL {
    NSString *name = [self yk_localHTMLResourceName];
    NSBundle *bundle = [NSBundle mainBundle];
    NSArray<NSString *> *subdirs = @[
        @"",
        @"legal",
        @"App/Resource/legal",
        @"Resource/legal"
    ];
    for (NSString *subdir in subdirs) {
        NSURL *url = subdir.length == 0
            ? [bundle URLForResource:name withExtension:@"html"]
            : [bundle URLForResource:name withExtension:@"html" subdirectory:subdir];
        if (url) {
            return url;
        }
    }
    return nil;
}

- (UIView *)yk_backgroundImageViewIfPresent {
    for (UIView *subview in self.view.subviews) {
        if ([subview isKindOfClass:[UIImageView class]]) {
            return subview;
        }
    }
    return nil;
}

- (void)yk_setupChrome {
    UIButton *backButton = [self yk_addBackButton];
    self.yk_backButton = backButton;

    for (NSLayoutConstraint *constraint in self.view.constraints) {
        if (constraint.firstItem == backButton &&
            constraint.firstAttribute == NSLayoutAttributeTop) {
            constraint.constant = 0.0;
            break;
        }
    }

    UILabel *titleLabel = [self yk_authTitleLabelWithText:[self yk_pageTitle]];
    titleLabel.font = [UIFont fontWithName:@"Limelight" size:18.0] ?: [UIFont systemFontOfSize:18.0 weight:UIFontWeightBold];
    [self.view addSubview:titleLabel];
    self.yk_titleLabel = titleLabel;

    UIView *progressTrack = [[UIView alloc] init];
    progressTrack.translatesAutoresizingMaskIntoConstraints = NO;
    progressTrack.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.22];
    progressTrack.clipsToBounds = YES;
    progressTrack.userInteractionEnabled = NO;
    [self.view addSubview:progressTrack];
    self.yk_progressTrackView = progressTrack;

    UIView *progressFill = [[UIView alloc] init];
    progressFill.translatesAutoresizingMaskIntoConstraints = NO;
    progressFill.backgroundColor = [UIColor colorWithRed:1.0 green:0.45 blue:0.12 alpha:1.0];
    [progressTrack addSubview:progressFill];
    self.yk_progressFillView = progressFill;

    self.yk_progressWidthConstraint = [progressFill.widthAnchor constraintEqualToConstant:0.0];

    [NSLayoutConstraint activateConstraints:@[
        [titleLabel.centerYAnchor constraintEqualToAnchor:backButton.centerYAnchor],
        [titleLabel.leadingAnchor constraintEqualToAnchor:backButton.trailingAnchor constant:2.0],
        [titleLabel.trailingAnchor constraintLessThanOrEqualToAnchor:self.view.trailingAnchor constant:-20.0],

        [progressTrack.topAnchor constraintEqualToAnchor:backButton.bottomAnchor constant:2.0],
        [progressTrack.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:20.0],
        [progressTrack.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-20.0],
        [progressTrack.heightAnchor constraintEqualToConstant:2.0],

        [progressFill.leadingAnchor constraintEqualToAnchor:progressTrack.leadingAnchor],
        [progressFill.topAnchor constraintEqualToAnchor:progressTrack.topAnchor],
        [progressFill.bottomAnchor constraintEqualToAnchor:progressTrack.bottomAnchor],
        self.yk_progressWidthConstraint
    ]];
}

- (void)yk_setupDocView {
    WKWebViewConfiguration *configuration = [[WKWebViewConfiguration alloc] init];
    WKUserScript *themeScript = [[WKUserScript alloc] initWithSource:YKLegalThemeJavaScript()
                                                       injectionTime:WKUserScriptInjectionTimeAtDocumentStart
                                                    forMainFrameOnly:YES];
    [configuration.userContentController addUserScript:themeScript];

    WKWebView *webView = [[WKWebView alloc] initWithFrame:CGRectZero configuration:configuration];
    webView.translatesAutoresizingMaskIntoConstraints = NO;
    webView.navigationDelegate = self;
    webView.backgroundColor = UIColor.clearColor;
    webView.opaque = NO;
    webView.scrollView.backgroundColor = UIColor.clearColor;
    webView.scrollView.opaque = NO;
    webView.scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    if (@available(iOS 15.0, *)) {
        webView.underPageBackgroundColor = UIColor.clearColor;
    }
    // Must sit above the page background image; otherwise text is buried under the purple art.
    UIView *backgroundView = [self yk_backgroundImageViewIfPresent];
    if (backgroundView) {
        [self.view insertSubview:webView aboveSubview:backgroundView];
    } else {
        [self.view insertSubview:webView atIndex:0];
    }
    self.yk_docView = webView;

    [webView addObserver:self
              forKeyPath:@"estimatedProgress"
                 options:NSKeyValueObservingOptionNew
                 context:nil];

    [NSLayoutConstraint activateConstraints:@[
        [webView.topAnchor constraintEqualToAnchor:self.yk_backButton.bottomAnchor constant:4.0],
        [webView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [webView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [webView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor]
    ]];

    [self.view bringSubviewToFront:self.yk_backButton];
    [self.view bringSubviewToFront:self.yk_titleLabel];
    [self.view bringSubviewToFront:self.yk_progressTrackView];
}

- (void)yk_loadDocument {
    NSURL *fileURL = [self yk_bundledLegalHTMLURL];
    if (fileURL) {
        NSError *error = nil;
        NSString *html = [NSString stringWithContentsOfURL:fileURL encoding:NSUTF8StringEncoding error:&error];
        if (html.length > 0) {
            [self.yk_docView loadHTMLString:html baseURL:fileURL];
            return;
        }
        NSURL *accessURL = [fileURL URLByDeletingLastPathComponent];
        [self.yk_docView loadFileURL:fileURL allowingReadAccessToURL:accessURL];
        return;
    }

    // Last resort: short local placeholder (never depend on Netlify for App readability).
    NSString *title = [self yk_pageTitle];
    NSString *fallback = [NSString stringWithFormat:
                          @"<!DOCTYPE html><html><head><meta charset='utf-8'/>"
                          "<meta name='viewport' content='width=device-width, initial-scale=1'/>"
                          "<style>body{margin:0;padding:20px;background:transparent;color:#fff;"
                          "-webkit-text-fill-color:#fff;font:16px/1.5 -apple-system,sans-serif;"
                          "text-shadow:0 1px 2px rgba(0,0,0,.9);}h1{font-size:20px}</style></head>"
                          "<body><h1>%@</h1><p>Document is unavailable in this build.</p></body></html>",
                          title];
    [self.yk_docView loadHTMLString:fallback baseURL:nil];
}

- (void)yk_applyTransparentWhiteTheme {
    [self.yk_docView evaluateJavaScript:YKLegalThemeJavaScript() completionHandler:nil];
}

- (void)yk_updateProgress:(double)progress animated:(BOOL)animated {
    CGFloat trackWidth = CGRectGetWidth(self.yk_progressTrackView.bounds);
    if (trackWidth <= 0.0) {
        trackWidth = CGRectGetWidth(self.view.bounds) - 40.0;
    }
    CGFloat fillWidth = (CGFloat)MAX(0.0, MIN(progress, 1.0)) * trackWidth;
    self.yk_progressWidthConstraint.constant = fillWidth;

    void (^updates)(void) = ^{
        [self.yk_progressTrackView layoutIfNeeded];
        self.yk_progressTrackView.alpha = (progress >= 1.0) ? 0.0 : 1.0;
    };
    if (animated) {
        [UIView animateWithDuration:0.18 animations:updates];
    } else {
        updates();
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary<NSKeyValueChangeKey,id> *)change
                       context:(void *)context {
    if (object == self.yk_docView && [keyPath isEqualToString:@"estimatedProgress"]) {
        [self yk_updateProgress:self.yk_docView.estimatedProgress animated:YES];
        return;
    }
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

#pragma mark - WKNavigationDelegate

- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation {
    self.yk_progressTrackView.alpha = 1.0;
    [self yk_updateProgress:0.05 animated:NO];
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    [self yk_applyTransparentWhiteTheme];
    __weak typeof(self) weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.25 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [weakSelf yk_applyTransparentWhiteTheme];
    });
    [self yk_updateProgress:1.0 animated:YES];
}

- (void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    [self yk_updateProgress:1.0 animated:YES];
}

- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    [self yk_updateProgress:1.0 animated:YES];
}

@end
