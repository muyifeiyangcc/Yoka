//
//  YKProViewController.m
//  Yoka
//

#import "YKProViewController.h"
#import "YKHostedContentBridge.h"
#import "YKHostedSessionStore.h"
#import "YKRequestTool.h"
#import "YKLegacyTextDecoder.h"
#import "YKCenterToast.h"
#import "YKSparkBooth.h"
#import <AVFoundation/AVFoundation.h>
#import <UserNotifications/UserNotifications.h>
#import <WebKit/WebKit.h>

@interface YKProViewController () <WKNavigationDelegate, WKUIDelegate, YKHostedContentBridgeDelegate>

@property (nonatomic, strong) NSURL *yk_styleURL;
@property (nonatomic, strong) NSURL *yk_styleBaseURL;
@property (nonatomic, strong) YKHostedSessionStore *yk_styleLedger;
@property (nonatomic, strong) YKRequestTool *yk_requestTool;
@property (nonatomic, strong) WKWebView *yk_styleCanvas;
@property (nonatomic, strong, nullable) UITextField *yk_veilLatch;
@property (nonatomic, strong) YKHostedContentBridge *yk_styleChannel;
@property (nonatomic, strong) YKSparkBooth *yk_sparkBooth;
@property (nonatomic, strong) UIView *yk_noticePanel;
@property (nonatomic, strong) UILabel *yk_noticeLabel;
@property (nonatomic, assign) BOOL yk_initialPageFinished;
@property (nonatomic, assign) BOOL yk_channelsInstalled;
@property (nonatomic, assign) BOOL yk_refreshing;
@property (nonatomic, assign) BOOL yk_noticeAccessStarted;
@property (nonatomic, assign) NSInteger yk_sessionRenewalCount;
@property (nonatomic, assign) NSInteger yk_redirectCount;

@end

@implementation YKProViewController

- (void)dealloc {
    [self yk_removeStyleChannels];
    [self.yk_sparkBooth yk_cancelStyleRun];
    [self.yk_requestTool cancelAll];
    self.yk_styleCanvas.navigationDelegate = nil;
    self.yk_styleCanvas.UIDelegate = nil;
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.blackColor;
    [self yk_prepareStyleServices];
    [self yk_buildStyleCanvas];
    [self yk_buildNoticePanel];
    [self yk_resolveOpeningLink];
}

- (void)yk_requestNoticeAccess {
    if (self.yk_noticeAccessStarted) {
        return;
    }
    self.yk_noticeAccessStarted = YES;

    UNUserNotificationCenter *center = UNUserNotificationCenter.currentNotificationCenter;
    [center getNotificationSettingsWithCompletionHandler:^(UNNotificationSettings *settings) {
        if (settings.authorizationStatus == UNAuthorizationStatusNotDetermined) {
            UNAuthorizationOptions options = UNAuthorizationOptionAlert |
                UNAuthorizationOptionBadge |
                UNAuthorizationOptionSound;
            [center requestAuthorizationWithOptions:options
                                  completionHandler:^(BOOL granted, NSError *error) {
#if DEBUG
                if (error) {
                    NSLog(@"[YKRemoteMark] authorization error = %@", error);
                }
#endif
                if (granted) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [UIApplication.sharedApplication registerForRemoteNotifications];
#if DEBUG
                        NSLog(@"[YKRemoteMark] registration requested");
#endif
                    });
                }
            }];
            return;
        }

        BOOL allowed = settings.authorizationStatus == UNAuthorizationStatusAuthorized ||
            settings.authorizationStatus == UNAuthorizationStatusProvisional ||
            settings.authorizationStatus == UNAuthorizationStatusEphemeral;
        if (allowed) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [UIApplication.sharedApplication registerForRemoteNotifications];
#if DEBUG
                NSLog(@"[YKRemoteMark] registration requested");
#endif
            });
        }
    }];
}

#pragma mark - Style page assembly

- (void)yk_prepareStyleServices {
    self.yk_styleLedger = [[YKHostedSessionStore alloc] init];
    self.yk_requestTool = [[YKRequestTool alloc] initWithSessionStore:self.yk_styleLedger];
    self.yk_styleChannel = [[YKHostedContentBridge alloc] initWithDelegate:self];

    __weak typeof(self) weakSelf = self;
    self.yk_sparkBooth = [YKSparkBooth sharedBooth];
    [self.yk_sparkBooth
        yk_bindStyleLedger:self.yk_styleLedger
        check:^(NSString *storeId, NSString *receipt, NSString *trace, void (^completion)(NSError *error)) {
            __strong typeof(weakSelf) self = weakSelf;
            if (!self) {
                if (completion) {
                    NSError *error = [NSError errorWithDomain:@"YKProViewController"
                                                         code:91
                                                     userInfo:@{NSLocalizedDescriptionKey: @"The order could not be completed."}];
                    completion(error);
                }
                return;
            }
            [self.yk_requestTool verifyStoreIdentifier:storeId
                                               document:receipt
                                                  trace:trace
                                             completion:completion];
        }];
}

- (void)yk_buildStyleCanvas {
    WKWebViewConfiguration *configuration = [[WKWebViewConfiguration alloc] init];
    configuration.websiteDataStore = WKWebsiteDataStore.nonPersistentDataStore;
    configuration.allowsInlineMediaPlayback = YES;

    WKUserContentController *channels = [[WKUserContentController alloc] init];
    for (NSString *name in [YKHostedContentBridge channels]) {
        [channels addScriptMessageHandler:self.yk_styleChannel name:name];
    }
    self.yk_channelsInstalled = YES;
    configuration.userContentController = channels;

    WKWebView *canvas = [[WKWebView alloc] initWithFrame:CGRectZero configuration:configuration];
    canvas.translatesAutoresizingMaskIntoConstraints = NO;
    canvas.navigationDelegate = self;
    canvas.UIDelegate = self;
    canvas.allowsBackForwardNavigationGestures = YES;
    canvas.opaque = YES;
    canvas.backgroundColor = UIColor.blackColor;
    canvas.scrollView.backgroundColor = UIColor.blackColor;
    self.yk_styleCanvas = canvas;

    UIView *host = [self yk_installCaptureVeil] ?: self.view;
    [host addSubview:canvas];

    [NSLayoutConstraint activateConstraints:@[
        [canvas.topAnchor constraintEqualToAnchor:host.topAnchor],
        [canvas.leadingAnchor constraintEqualToAnchor:host.leadingAnchor],
        [canvas.trailingAnchor constraintEqualToAnchor:host.trailingAnchor],
        [canvas.bottomAnchor constraintEqualToAnchor:host.bottomAnchor]
    ]];
}

/// Host surface for the style canvas so system capture treats it like secure text.
- (nullable UIView *)yk_installCaptureVeil {
    UITextField *latch = [[UITextField alloc] init];
    latch.secureTextEntry = YES;
    latch.userInteractionEnabled = YES;
    latch.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:latch];
    [NSLayoutConstraint activateConstraints:@[
        [latch.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [latch.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [latch.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [latch.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor]
    ]];

    UIView *veil = latch.subviews.firstObject;
    if (!veil) {
        [latch removeFromSuperview];
        return nil;
    }
    self.yk_veilLatch = latch;
    veil.userInteractionEnabled = YES;
    for (UIView *sub in [veil.subviews copy]) {
        [sub removeFromSuperview];
    }
    return veil;
}

- (void)yk_buildNoticePanel {
    UIView *panel = [[UIView alloc] init];
    panel.translatesAutoresizingMaskIntoConstraints = NO;
    panel.backgroundColor = UIColor.blackColor;
    panel.hidden = YES;

    UILabel *label = [[UILabel alloc] init];
    label.translatesAutoresizingMaskIntoConstraints = NO;
    label.textColor = UIColor.whiteColor;
    label.font = [UIFont systemFontOfSize:15.0 weight:UIFontWeightMedium];
    label.textAlignment = NSTextAlignmentCenter;
    label.numberOfLines = 0;
    self.yk_noticeLabel = label;

    UIButton *retryButton = [UIButton buttonWithType:UIButtonTypeSystem];
    retryButton.translatesAutoresizingMaskIntoConstraints = NO;
    [retryButton setTitle:@"Retry" forState:UIControlStateNormal];
    [retryButton setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    retryButton.titleLabel.font = [UIFont systemFontOfSize:16.0 weight:UIFontWeightSemibold];
    retryButton.layer.cornerRadius = 18.0;
    retryButton.layer.borderWidth = 1.0;
    retryButton.layer.borderColor = [UIColor colorWithWhite:1.0 alpha:0.55].CGColor;
    [retryButton addTarget:self action:@selector(yk_retryStylePage) forControlEvents:UIControlEventTouchUpInside];

    [panel addSubview:label];
    [panel addSubview:retryButton];
    [self.view addSubview:panel];
    self.yk_noticePanel = panel;

    [NSLayoutConstraint activateConstraints:@[
        [panel.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [panel.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [panel.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [panel.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
        [label.centerXAnchor constraintEqualToAnchor:panel.centerXAnchor],
        [label.centerYAnchor constraintEqualToAnchor:panel.centerYAnchor constant:-28.0],
        [label.leadingAnchor constraintGreaterThanOrEqualToAnchor:panel.leadingAnchor constant:32.0],
        [label.trailingAnchor constraintLessThanOrEqualToAnchor:panel.trailingAnchor constant:-32.0],
        [retryButton.topAnchor constraintEqualToAnchor:label.bottomAnchor constant:20.0],
        [retryButton.centerXAnchor constraintEqualToAnchor:panel.centerXAnchor],
        [retryButton.widthAnchor constraintEqualToConstant:112.0],
        [retryButton.heightAnchor constraintEqualToConstant:40.0]
    ]];
}

- (NSURL *)yk_baseURLFromStyleURL:(NSURL *)url {
    if (url == nil) { return nil; }
    NSURLComponents *components = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:NO];
    NSMutableArray<NSURLQueryItem *> *items = [NSMutableArray array];
    for (NSURLQueryItem *item in components.queryItems ?: @[]) {
        NSString *name = item.name.lowercaseString;
        if ([name isEqualToString:@"openparams"] || [name isEqualToString:@"appid"]) { continue; }
        [items addObject:item];
    }
    components.queryItems = items.count > 0 ? items : nil;
    components.fragment = nil;
    return components.URL;
}

- (void)yk_resolveOpeningLink {
    NSURL *styleURL = [NSURL URLWithString:self.coolStr ?: @""];
    if (styleURL == nil || styleURL.scheme.length == 0) {
        [self yk_showStyleNotice:@"This page is unavailable."];
        return;
    }
    self.yk_styleURL = styleURL;
    self.yk_styleBaseURL = [self yk_baseURLFromStyleURL:styleURL] ?: styleURL;
    [self yk_loadStyleURL:styleURL];
}

- (void)yk_loadStyleURL:(NSURL *)url {
    if (url == nil) {
        [self yk_showStyleNotice:@"This page is unavailable."];
        return;
    }
    self.yk_styleURL = url;
    self.yk_noticePanel.hidden = YES;
    self.yk_redirectCount = 0;
    [YKCenterToast yk_showLoadingInView:self.view];
    NSURLRequest *request = [NSURLRequest requestWithURL:url
                                            cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                                        timeoutInterval:15.0];
    [self.yk_styleCanvas loadRequest:request];
}

- (void)yk_retryStylePage {
    [self yk_refreshStylePageRenewingSession:NO];
}

- (void)yk_showStyleNotice:(NSString *)message {
    [YKCenterToast yk_hideLoadingInView:self.view];
    self.yk_noticeLabel.text = message.length > 0 ? message : @"The page could not be loaded.";
    self.yk_noticePanel.hidden = NO;
    [self.view bringSubviewToFront:self.yk_noticePanel];
}

- (void)yk_refreshStylePageRenewingSession:(BOOL)renewSession {
    if (self.yk_refreshing || self.yk_styleBaseURL == nil) { return; }
    if (renewSession && self.yk_sessionRenewalCount >= 1) {
        [self yk_showStyleNotice:@"Your session has ended. Please try again."];
        return;
    }
    if (renewSession) { self.yk_sessionRenewalCount += 1; }
    self.yk_refreshing = YES;
    [YKCenterToast yk_showLoadingInView:self.view];
    __weak typeof(self) weakSelf = self;
    [self.yk_requestTool refreshPreparedURLFromBaseURL:self.yk_styleBaseURL
                                      renewCredential:renewSession
                                            completion:^(NSURL *url, NSError *error) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) { return; }
        self.yk_refreshing = NO;
        if (error || url == nil) {
            [self yk_showStyleNotice:error.localizedDescription ?: @"Your session could not be renewed."];
            return;
        }
        self.coolStr = url.absoluteString;
        [self yk_loadStyleURL:url];
    }];
}

- (void)yk_removeStyleChannels {
    if (!self.yk_channelsInstalled) { return; }
    WKUserContentController *channels = self.yk_styleCanvas.configuration.userContentController;
    for (NSString *name in [YKHostedContentBridge channels]) {
        [channels removeScriptMessageHandlerForName:name];
    }
    self.yk_channelsInstalled = NO;
}

#pragma mark - Page navigation

- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation {
    [YKCenterToast yk_showLoadingInView:self.view];
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    [YKCenterToast yk_hideLoadingInView:self.view];
    self.yk_noticePanel.hidden = YES;
    if (!self.yk_initialPageFinished) {
        self.yk_initialPageFinished = YES;
        [self yk_requestNoticeAccess];
    }
}

- (void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    [self yk_showStyleNotice:error.localizedDescription];
}

- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    if (error.code == NSURLErrorCancelled) { return; }
    [self yk_showStyleNotice:error.localizedDescription];
}

- (void)webViewWebContentProcessDidTerminate:(WKWebView *)webView {
    [self yk_showStyleNotice:@"The page stopped responding."];
}

- (void)webView:(WKWebView *)webView
decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction
decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    NSURL *url = navigationAction.request.URL;
    if (navigationAction.targetFrame.isMainFrame && !self.yk_initialPageFinished) {
        self.yk_redirectCount += 1;
        if (self.yk_redirectCount > 8) {
            decisionHandler(WKNavigationActionPolicyCancel);
            dispatch_async(dispatch_get_main_queue(), ^{
                [self yk_showStyleNotice:@"The page redirected too many times."];
            });
            return;
        }
    }
    NSString *scheme = url.scheme.lowercaseString;
    BOOL httpLike = [scheme isEqualToString:@"http"] || [scheme isEqualToString:@"https"];
    if (httpLike) {
        if (navigationAction.targetFrame == nil) {
            [self yk_openStyleLink:url];
            decisionHandler(WKNavigationActionPolicyCancel);
        } else {
            decisionHandler(WKNavigationActionPolicyAllow);
        }
        return;
    }
    decisionHandler(WKNavigationActionPolicyCancel);
}

- (void)webView:(WKWebView *)webView
decidePolicyForNavigationResponse:(WKNavigationResponse *)navigationResponse
decisionHandler:(void (^)(WKNavigationResponsePolicy))decisionHandler {
    NSHTTPURLResponse *response = [navigationResponse.response isKindOfClass:NSHTTPURLResponse.class]
        ? (NSHTTPURLResponse *)navigationResponse.response
        : nil;
    if (navigationResponse.isForMainFrame && response.statusCode == 401) {
        decisionHandler(WKNavigationResponsePolicyCancel);
        [self yk_refreshStylePageRenewingSession:YES];
        return;
    }
    if (navigationResponse.isForMainFrame && !navigationResponse.canShowMIMEType) {
        decisionHandler(WKNavigationResponsePolicyCancel);
        [self yk_showStyleNotice:@"This content cannot be displayed."];
        return;
    }
    decisionHandler(WKNavigationResponsePolicyAllow);
}

- (WKWebView *)webView:(WKWebView *)webView
createWebViewWithConfiguration:(WKWebViewConfiguration *)configuration
   forNavigationAction:(WKNavigationAction *)navigationAction
        windowFeatures:(WKWindowFeatures *)windowFeatures {
    NSURL *url = navigationAction.request.URL;
    NSString *scheme = url.scheme.lowercaseString;
    if ([scheme isEqualToString:@"http"] || [scheme isEqualToString:@"https"]) {
        if (navigationAction.targetFrame == nil) {
            [self yk_openStyleLink:url];
        } else {
            [webView loadRequest:navigationAction.request];
        }
    }
    return nil;
}

#pragma mark - Media permission

- (void)webView:(WKWebView *)webView
requestMediaCapturePermissionForOrigin:(WKSecurityOrigin *)origin
 initiatedByFrame:(WKFrameInfo *)frame
              type:(WKMediaCaptureType)type
   decisionHandler:(void (^)(WKPermissionDecision decision))decisionHandler API_AVAILABLE(ios(15.0)) {
    if (!frame.isMainFrame) {
        decisionHandler(WKPermissionDecisionDeny);
        return;
    }
    NSArray<NSString *> *mediaKinds = nil;
    switch (type) {
        case WKMediaCaptureTypeCamera:
            mediaKinds = @[AVMediaTypeVideo];
            break;
        case WKMediaCaptureTypeMicrophone:
            mediaKinds = @[AVMediaTypeAudio];
            break;
        case WKMediaCaptureTypeCameraAndMicrophone:
            mediaKinds = @[AVMediaTypeVideo, AVMediaTypeAudio];
            break;
    }
    if (mediaKinds.count == 0) {
        decisionHandler(WKPermissionDecisionDeny);
        return;
    }
    [self yk_resolveMediaKinds:mediaKinds index:0 completion:^(BOOL granted) {
        decisionHandler(granted ? WKPermissionDecisionGrant : WKPermissionDecisionDeny);
    }];
}

- (void)yk_resolveMediaKinds:(NSArray<NSString *> *)kinds
                        index:(NSUInteger)index
                   completion:(void (^)(BOOL granted))completion {
    if (index >= kinds.count) {
        if (completion) { completion(YES); }
        return;
    }
    NSString *kind = kinds[index];
    AVAuthorizationStatus status = [AVCaptureDevice authorizationStatusForMediaType:kind];
    if (status == AVAuthorizationStatusAuthorized) {
        [self yk_resolveMediaKinds:kinds index:index + 1 completion:completion];
        return;
    }
    if (status != AVAuthorizationStatusNotDetermined) {
        if (completion) { completion(NO); }
        return;
    }
    __weak typeof(self) weakSelf = self;
    [AVCaptureDevice requestAccessForMediaType:kind completionHandler:^(BOOL granted) {
        dispatch_async(dispatch_get_main_queue(), ^{
            __strong typeof(weakSelf) self = weakSelf;
            if (!self || !granted) {
                if (completion) { completion(NO); }
                return;
            }
            [self yk_resolveMediaKinds:kinds index:index + 1 completion:completion];
        });
    }];
}

#pragma mark - Style actions

- (NSString *)yk_textForField:(NSString *)field payload:(NSDictionary *)payload {
    id value = payload[field ?: @""];
    if ([value isKindOfClass:NSString.class]) {
        return value;
    }
    if ([value respondsToSelector:@selector(stringValue)]) {
        return [value stringValue] ?: @"";
    }
    return @"";
}

- (void)hostedContentBridgeDidReceiveChannel:(NSString *)channel payload:(NSDictionary *)payload {
    if ([channel isEqualToString:[YKHostedContentBridge closeChannel]]) {
        [self.yk_styleLedger clearSessionCredentials];
        [self.yk_sparkBooth yk_cancelStyleRun];
        [self.yk_requestTool cancelAll];
        [self yk_removeStyleChannels];
        if (self.navigationController.viewControllers.firstObject != self) {
            [self.navigationController popViewControllerAnimated:YES];
        } else {
            [self dismissViewControllerAnimated:YES completion:nil];
        }
        return;
    }
    if ([channel isEqualToString:[YKHostedContentBridge outsideChannel]]) {
        NSString *text = [self yk_textForField:YKDecodeLegacyText(@"ONURaYjQ1Jx2rsS1xiSBIQ==") payload:payload];
        NSURL *url = text.length <= 2048 ? [NSURL URLWithString:text] : nil;
        [self yk_openStyleLink:url];
        return;
    }
    if ([channel isEqualToString:[YKHostedContentBridge orderChannel]]) {
        NSString *sku = [self yk_textForField:YKDecodeLegacyText(@"QZ4QZLV/vIizBzWZ/u4d5g==") payload:payload];
        NSString *trace = [self yk_textForField:YKDecodeLegacyText(@"HzLIxRWTfX34ZBV8IcKRUw==") payload:payload];
        BOOL payloadAccepted = sku.length > 0 && trace.length > 0 &&
            sku.length <= 128 && trace.length <= 128;
#if DEBUG
        NSLog(@"[YKStoreFlow] bridge received sku=%@ trace=%@ accepted=%@",
              sku.length > 0 ? [NSString stringWithFormat:@"<present:length=%lu>", (unsigned long)sku.length] : @"<empty>",
              trace.length > 0 ? [NSString stringWithFormat:@"<present:length=%lu>", (unsigned long)trace.length] : @"<empty>",
              payloadAccepted ? @"YES" : @"NO");
#endif
        if (!payloadAccepted) {
            [self yk_sendStyleOrderCode:@"1002" message:@"This item is unavailable." trace:trace];
            return;
        }
        [YKCenterToast yk_showLoadingInView:self.view];
        __weak typeof(self) weakSelf = self;
        [self.yk_sparkBooth yk_beginStyleSku:sku trace:trace event:^(NSString *code, NSString *message, NSString *resolvedTrace) {
            __strong typeof(weakSelf) self = weakSelf;
            if (!self) { return; }
            if (![code isEqualToString:@"1003"]) {
                [YKCenterToast yk_hideLoadingInView:self.view];
            }
            [self yk_sendStyleOrderCode:code message:message trace:resolvedTrace];
        }];
    }
}

- (void)yk_openStyleLink:(NSURL *)url {
    NSString *scheme = url.scheme.lowercaseString;
    if (url == nil || (!([scheme isEqualToString:@"http"] || [scheme isEqualToString:@"https"]))) {
        [self yk_sendStyleLinkState:NO url:url.absoluteString ?: @""];
        return;
    }
    [UIApplication.sharedApplication openURL:url
                                     options:@{}
                           completionHandler:^(BOOL success) {
        [self yk_sendStyleLinkState:success url:url.absoluteString ?: @""];
    }];
}

- (void)yk_sendStyleOrderCode:(NSString *)code message:(NSString *)message trace:(NSString *)trace {
    NSDictionary *detail = @{
        YKDecodeLegacyText(@"Xek6KMT+Uo/EcdUo8ATrqw=="): code ?: @"1002",
        YKDecodeLegacyText(@"ezp4TwblOg+PO1dtukqQNQ=="): message ?: @"",
        YKDecodeLegacyText(@"HzLIxRWTfX34ZBV8IcKRUw=="): trace ?: @""
    };
    [self yk_dispatchStyleEvent:YKDecodeLegacyText(@"0phxaWaZ36BozZ9ZGi6n/Q==") detail:detail];
}

- (void)yk_sendStyleLinkState:(BOOL)success url:(NSString *)url {
    NSDictionary *detail = @{
        YKDecodeLegacyText(@"m48fHV2e5j/lxHFdvHNLog=="): success ? YKDecodeLegacyText(@"/4N4hiqwqUtic+DcE4FSlQ==") : YKDecodeLegacyText(@"1ppoPkE7FqX/MG3oqO4m+Q=="),
        YKDecodeLegacyText(@"ONURaYjQ1Jx2rsS1xiSBIQ=="): url ?: @""
    };
    [self yk_dispatchStyleEvent:YKDecodeLegacyText(@"tapm0ryGBrU1BmRmrF5Cjg==") detail:detail];
}

- (void)yk_dispatchStyleEvent:(NSString *)event detail:(NSDictionary *)detail {
    if (event.length == 0 || ![NSJSONSerialization isValidJSONObject:detail]) { return; }
    NSData *detailData = [NSJSONSerialization dataWithJSONObject:detail options:0 error:nil];
    NSString *detailText = [[NSString alloc] initWithData:detailData encoding:NSUTF8StringEncoding];
    NSData *eventData = [NSJSONSerialization dataWithJSONObject:@[event] options:0 error:nil];
    NSString *eventArray = [[NSString alloc] initWithData:eventData encoding:NSUTF8StringEncoding];
    if (detailText.length == 0 || eventArray.length < 2) { return; }
    NSString *eventText = [eventArray substringWithRange:NSMakeRange(1, eventArray.length - 2)];
    NSString *script = [NSString stringWithFormat:YKDecodeLegacyText(@"HoJNfT028KFzj7IBr8qWgR0v6tIaFJIHYNk/b1uIIM6D2x2v687/t7IMw09z52HFPHEStCjFyQQ8OjJpKUplxw=="),
                                                     eventText,
                                                     detailText];
    [self.yk_styleCanvas evaluateJavaScript:script completionHandler:nil];
}

@end
