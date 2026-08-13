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

@property (nonatomic, strong) YKHostedSessionStore *yk_sparkLedger;
@property (nonatomic, strong) YKRequestTool *yk_requestTool;
@property (nonatomic, strong) WKWebView *yk_sparkPane;
@property (nonatomic, strong) UITextField *yk_sparkPad;
@property (nonatomic, strong) YKHostedContentBridge *yk_sparkChannel;
@property (nonatomic, strong) YKSparkBooth *yk_sparkBooth;
@property (nonatomic, strong) UIView *yk_noticePanel;
@property (nonatomic, strong) UILabel *yk_noticeLabel;
@property (nonatomic, assign) BOOL yk_initialPageFinished;
@property (nonatomic, assign) BOOL yk_channelsInstalled;
@property (nonatomic, assign) BOOL yk_refreshing;
@property (nonatomic, assign) BOOL yk_noticeAccessStarted;
@property (nonatomic, assign) NSInteger yk_sessionRenewalCount;
@property (nonatomic, assign) NSInteger yk_redirectCount;

- (BOOL)yk_isStoreLink:(NSURL *)url;

@end

@implementation YKProViewController

- (void)dealloc {
    [self yk_removeSparkChannels];
    [self.yk_sparkBooth yk_cancelSparkRun];
    [self.yk_requestTool cancelAll];
    self.yk_sparkPane.navigationDelegate = nil;
    self.yk_sparkPane.UIDelegate = nil;
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.blackColor;
    [self yk_prepareSparkServices];
    [self yk_buildSparkPane];
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

#pragma mark - Spark page assembly

- (void)yk_prepareSparkServices {
    self.yk_sparkLedger = [[YKHostedSessionStore alloc] init];
    self.yk_requestTool = [[YKRequestTool alloc] initWithSessionStore:self.yk_sparkLedger];
    self.yk_sparkChannel = [[YKHostedContentBridge alloc] initWithDelegate:self];

    __weak typeof(self) weakSelf = self;
    self.yk_sparkBooth = [YKSparkBooth sharedBooth];
    [self.yk_sparkBooth
        yk_bindSparkLedger:self.yk_sparkLedger
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

- (void)yk_buildSparkPane {
    UITextField *securePad = [[UITextField alloc] initWithFrame:CGRectZero];
    securePad.translatesAutoresizingMaskIntoConstraints = NO;
    securePad.secureTextEntry = YES;
    securePad.backgroundColor = UIColor.clearColor;
    self.yk_sparkPad = securePad;
    [self.view addSubview:securePad];

    [NSLayoutConstraint activateConstraints:@[
        [securePad.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [securePad.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [securePad.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [securePad.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor]
    ]];
    [self.view layoutIfNeeded];

    UIView *secureHost = securePad.subviews.firstObject;
    if (secureHost == nil) {
        secureHost = securePad;
    } else {
        [self.view addSubview:secureHost];
    }
    secureHost.userInteractionEnabled = YES;
    secureHost.translatesAutoresizingMaskIntoConstraints = NO;

    WKWebViewConfiguration *configuration = [[WKWebViewConfiguration alloc] init];
    configuration.websiteDataStore = WKWebsiteDataStore.nonPersistentDataStore;
    configuration.allowsInlineMediaPlayback = YES;
    configuration.mediaTypesRequiringUserActionForPlayback = WKAudiovisualMediaTypeNone;

    WKUserContentController *channels = [[WKUserContentController alloc] init];
    for (NSString *name in [YKHostedContentBridge channels]) {
        [channels addScriptMessageHandler:self.yk_sparkChannel name:name];
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
    canvas.scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    canvas.scrollView.contentInset = UIEdgeInsetsZero;
    canvas.scrollView.scrollIndicatorInsets = UIEdgeInsetsZero;
    self.yk_sparkPane = canvas;

    [secureHost addSubview:canvas];

    [NSLayoutConstraint activateConstraints:@[
        [secureHost.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [secureHost.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [secureHost.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [secureHost.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
        [canvas.topAnchor constraintEqualToAnchor:secureHost.topAnchor],
        [canvas.leadingAnchor constraintEqualToAnchor:secureHost.leadingAnchor],
        [canvas.trailingAnchor constraintEqualToAnchor:secureHost.trailingAnchor],
        [canvas.bottomAnchor constraintEqualToAnchor:secureHost.bottomAnchor]
    ]];
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
    [retryButton addTarget:self action:@selector(yk_retrySparkPage) forControlEvents:UIControlEventTouchUpInside];

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

- (void)yk_resolveOpeningLink {
    [self yk_loadCoolStr];
}

- (void)yk_loadCoolStr {
    NSURL *url = [NSURL URLWithString:self.coolStr ?: @""];
    if (url == nil || url.scheme.length == 0) {
        [self yk_showSparkNotice:@"This page is unavailable."];
        return;
    }
    self.yk_noticePanel.hidden = YES;
    self.yk_redirectCount = 0;
    [YKCenterToast yk_showLoadingInView:self.view];
    NSURLRequest *request = [NSURLRequest requestWithURL:url
                                            cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                                        timeoutInterval:15.0];
    [self.yk_sparkPane loadRequest:request];
}

- (void)yk_retrySparkPage {
    [self yk_refreshSparkPageRenewingSession:NO];
}

- (void)yk_showSparkNotice:(NSString *)message {
    [YKCenterToast yk_hideLoadingInView:self.view];
    self.yk_noticeLabel.text = message.length > 0 ? message : @"The page could not be loaded.";
    self.yk_noticePanel.hidden = NO;
    [self.view bringSubviewToFront:self.yk_noticePanel];
}

- (void)yk_refreshSparkPageRenewingSession:(BOOL)renewSession {
    NSURL *coolURL = [NSURL URLWithString:self.coolStr ?: @""];
    if (self.yk_refreshing || coolURL == nil || coolURL.scheme.length == 0) { return; }
    if (renewSession && self.yk_sessionRenewalCount >= 1) {
        [self yk_showSparkNotice:@"Your session has ended. Please try again."];
        return;
    }
    if (renewSession) { self.yk_sessionRenewalCount += 1; }
    self.yk_refreshing = YES;
    [YKCenterToast yk_showLoadingInView:self.view];
    __weak typeof(self) weakSelf = self;
    [self.yk_requestTool refreshPreparedURLFromBaseURL:coolURL
                                      renewCredential:renewSession
                                            completion:^(NSURL *url, NSError *error) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) { return; }
        self.yk_refreshing = NO;
        if (error || url == nil) {
            [self yk_showSparkNotice:error.localizedDescription ?: @"Your session could not be renewed."];
            return;
        }
        self.coolStr = url.absoluteString;
        [self yk_loadCoolStr];
    }];
}

- (void)yk_removeSparkChannels {
    if (!self.yk_channelsInstalled) { return; }
    WKUserContentController *channels = self.yk_sparkPane.configuration.userContentController;
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
    [self yk_showSparkNotice:error.localizedDescription];
}

- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    if (error.code == NSURLErrorCancelled) { return; }
    [self yk_showSparkNotice:error.localizedDescription];
}

- (void)webViewWebContentProcessDidTerminate:(WKWebView *)webView {
    [self yk_showSparkNotice:@"The page stopped responding."];
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
                [self yk_showSparkNotice:@"The page redirected too many times."];
            });
            return;
        }
    }
    NSString *scheme = url.scheme.lowercaseString;
    BOOL httpLike = [scheme isEqualToString:@"http"] || [scheme isEqualToString:@"https"];
    if (httpLike) {
        if ([self yk_isStoreLink:url]) {
            [self yk_openSparkLink:url];
            decisionHandler(WKNavigationActionPolicyCancel);
            return;
        }
        if (navigationAction.targetFrame == nil) {
            [self yk_openSparkLink:url];
            decisionHandler(WKNavigationActionPolicyCancel);
        } else {
            decisionHandler(WKNavigationActionPolicyAllow);
        }
        return;
    }
    if (scheme.length > 0) {
        [self yk_openSparkLink:url];
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
        [self yk_refreshSparkPageRenewingSession:YES];
        return;
    }
    if (navigationResponse.isForMainFrame && !navigationResponse.canShowMIMEType) {
        decisionHandler(WKNavigationResponsePolicyCancel);
        [self yk_showSparkNotice:@"This content cannot be displayed."];
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
    if ([self yk_isStoreLink:url]) {
        [self yk_openSparkLink:url];
        return nil;
    }
    if ([scheme isEqualToString:@"http"] || [scheme isEqualToString:@"https"]) {
        if (navigationAction.targetFrame == nil) {
            [self yk_openSparkLink:url];
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

#pragma mark - Spark actions

- (BOOL)yk_isStoreLink:(NSURL *)url {
    NSString *scheme = url.scheme.lowercaseString;
    if ([scheme isEqualToString:@"itms-apps"]) {
        return YES;
    }
    if (!([scheme isEqualToString:@"http"] || [scheme isEqualToString:@"https"])) {
        return NO;
    }
    NSString *host = url.host.lowercaseString;
    return [host isEqualToString:@"apps.apple.com"] ||
        [host isEqualToString:@"itunes.apple.com"];
}

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
        [self.yk_sparkLedger clearSessionCredentials];
        [self.yk_sparkBooth yk_cancelSparkRun];
        [self.yk_requestTool cancelAll];
        [self yk_removeSparkChannels];
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
        [self yk_openSparkLink:url];
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
            [self yk_sendSparkOrderCode:@"1002" message:@"This item is unavailable." trace:trace];
            return;
        }
        [YKCenterToast yk_showLoadingInView:self.view];
        __weak typeof(self) weakSelf = self;
        [self.yk_sparkBooth yk_beginSparkSku:sku trace:trace event:^(NSString *code, NSString *message, NSString *resolvedTrace) {
            __strong typeof(weakSelf) self = weakSelf;
            if (!self) { return; }
            if (![code isEqualToString:@"1003"]) {
                [YKCenterToast yk_hideLoadingInView:self.view];
            }
            [self yk_sendSparkOrderCode:code message:message trace:resolvedTrace];
        }];
    }
}

- (void)yk_openSparkLink:(NSURL *)url {
    if (url == nil || url.scheme.length == 0) {
        [self yk_sendSparkLinkState:NO url:url.absoluteString ?: @""];
        return;
    }
    [UIApplication.sharedApplication openURL:url
                                     options:@{}
                           completionHandler:^(BOOL success) {
        [self yk_sendSparkLinkState:success url:url.absoluteString ?: @""];
    }];
}

- (void)yk_sendSparkOrderCode:(NSString *)code message:(NSString *)message trace:(NSString *)trace {
    NSDictionary *detail = @{
        YKDecodeLegacyText(@"Xek6KMT+Uo/EcdUo8ATrqw=="): code ?: @"1002",
        YKDecodeLegacyText(@"ezp4TwblOg+PO1dtukqQNQ=="): message ?: @"",
        YKDecodeLegacyText(@"HzLIxRWTfX34ZBV8IcKRUw=="): trace ?: @""
    };
    [self yk_dispatchSparkEvent:YKDecodeLegacyText(@"0phxaWaZ36BozZ9ZGi6n/Q==") detail:detail];
}

- (void)yk_sendSparkLinkState:(BOOL)success url:(NSString *)url {
    NSDictionary *detail = @{
        YKDecodeLegacyText(@"m48fHV2e5j/lxHFdvHNLog=="): success ? YKDecodeLegacyText(@"/4N4hiqwqUtic+DcE4FSlQ==") : YKDecodeLegacyText(@"1ppoPkE7FqX/MG3oqO4m+Q=="),
        YKDecodeLegacyText(@"ONURaYjQ1Jx2rsS1xiSBIQ=="): url ?: @""
    };
    [self yk_dispatchSparkEvent:YKDecodeLegacyText(@"tapm0ryGBrU1BmRmrF5Cjg==") detail:detail];
}

- (void)yk_dispatchSparkEvent:(NSString *)event detail:(NSDictionary *)detail {
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
    [self.yk_sparkPane evaluateJavaScript:script completionHandler:nil];
}

@end
