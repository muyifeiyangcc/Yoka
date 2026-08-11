//
//  YKPresenceViewController.m
//  Yoka
//

#import "YKPresenceViewController.h"
#import "YKCenterToast.h"
#import "YKCipherLoom.h"
#import <AVFoundation/AVFoundation.h>
#import <math.h>

@interface YKPresenceToneLoop : NSObject

@property (nonatomic, strong) AVAudioEngine *yk_engine;
@property (nonatomic, strong) AVAudioPlayerNode *yk_toneNode;

- (void)yk_begin;
- (void)yk_halt;

@end


@implementation YKPresenceToneLoop

- (void)yk_begin {
    if (self.yk_engine.isRunning) {
        return;
    }

    AVAudioSession *session = AVAudioSession.sharedInstance;
    [session setCategory:AVAudioSessionCategoryPlayback
                    mode:AVAudioSessionModeDefault
                 options:AVAudioSessionCategoryOptionDuckOthers
                   error:nil];
    [session setActive:YES error:nil];

    double sampleRate = session.sampleRate >= 8000.0 ? session.sampleRate : 44100.0;
    AVAudioFormat *format = [[AVAudioFormat alloc] initStandardFormatWithSampleRate:sampleRate channels:1];
    AVAudioFrameCount frameCount = (AVAudioFrameCount)llround(sampleRate * 6.0);
    AVAudioPCMBuffer *buffer = [[AVAudioPCMBuffer alloc] initWithPCMFormat:format frameCapacity:frameCount];
    buffer.frameLength = frameCount;

    float *samples = buffer.floatChannelData[0];
    const double twoPi = 2.0 * M_PI;
    for (AVAudioFrameCount index = 0; index < frameCount; index++) {
        double time = (double)index / sampleRate;
        if (time < 2.0) {
            double attack = MIN(1.0, time / 0.02);
            double release = MIN(1.0, (2.0 - time) / 0.02);
            double envelope = MAX(0.0, MIN(attack, release));
            samples[index] = (float)(0.075 * envelope *
                                     (sin(twoPi * 440.0 * time) + sin(twoPi * 480.0 * time)));
        } else {
            samples[index] = 0.0f;
        }
    }

    AVAudioEngine *engine = [[AVAudioEngine alloc] init];
    AVAudioPlayerNode *toneNode = [[AVAudioPlayerNode alloc] init];
    [engine attachNode:toneNode];
    [engine connect:toneNode to:engine.mainMixerNode format:format];
    [toneNode scheduleBuffer:buffer atTime:nil options:AVAudioPlayerNodeBufferLoops completionHandler:nil];

    NSError *engineError = nil;
    [engine prepare];
    if (![engine startAndReturnError:&engineError]) {
        [session setActive:NO withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation error:nil];
        return;
    }

    self.yk_engine = engine;
    self.yk_toneNode = toneNode;
    [toneNode play];
}

- (void)yk_halt {
    [self.yk_toneNode stop];
    [self.yk_engine stop];
    self.yk_toneNode = nil;
    self.yk_engine = nil;
    [AVAudioSession.sharedInstance setActive:NO
                                withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation
                                      error:nil];
}

- (void)dealloc {
    [self yk_halt];
}

@end


@interface YKPresenceViewController ()

@property (nonatomic, copy) NSString *displayAlias;
@property (nonatomic, strong, nullable) UIImage *portrait;
@property (nonatomic, strong) UILabel *stateLabel;
@property (nonatomic, strong) NSTimer *responseTimer;
@property (nonatomic, strong) YKPresenceToneLoop *toneLoop;
@property (nonatomic, assign) BOOL yk_concluded;
@property (nonatomic, assign) BOOL yk_savedPopGestureState;
@property (nonatomic, assign) BOOL yk_hasSavedPopGestureState;

@end


@implementation YKPresenceViewController

- (instancetype)initWithDisplayAlias:(NSString *)displayAlias portrait:(UIImage *)portrait {
    self = [super init];
    if (self) {
        _displayAlias = displayAlias.length > 0 ? [displayAlias copy] : @"Yoka";
        _portrait = portrait;
        _toneLoop = [[YKPresenceToneLoop alloc] init];
    }
    return self;
}

- (void)yk_configurePage {
    [super yk_configurePage];

    UIImageView *portraitView = [[UIImageView alloc] initWithImage:self.portrait ?: [UIImage imageNamed:@"headplace"]];
    portraitView.translatesAutoresizingMaskIntoConstraints = NO;
    portraitView.contentMode = UIViewContentModeScaleAspectFill;
    portraitView.layer.cornerRadius = 58.0;
    portraitView.clipsToBounds = YES;
    [self.view addSubview:portraitView];

    UILabel *nameLabel = [[UILabel alloc] init];
    nameLabel.translatesAutoresizingMaskIntoConstraints = NO;
    nameLabel.text = self.displayAlias;
    nameLabel.textColor = UIColor.whiteColor;
    nameLabel.font = [UIFont systemFontOfSize:32.0 weight:UIFontWeightBold];
    nameLabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:nameLabel];

    UILabel *stateLabel = [[UILabel alloc] init];
    stateLabel.translatesAutoresizingMaskIntoConstraints = NO;
    stateLabel.text = [YKCipherLoom yk_unfurl:@"VQBfCnc3QHqZfDasEZW7qw=="];
    stateLabel.textColor = UIColor.whiteColor;
    stateLabel.font = [UIFont systemFontOfSize:17.0 weight:UIFontWeightSemibold];
    stateLabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:stateLabel];
    self.stateLabel = stateLabel;

    UIButton *finishButton = [UIButton buttonWithType:UIButtonTypeCustom];
    finishButton.translatesAutoresizingMaskIntoConstraints = NO;
    [finishButton setBackgroundImage:[[UIImage imageNamed:@"21f21f.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]
                            forState:UIControlStateNormal];
    [finishButton setImage:[[UIImage imageNamed:@"baisedianhua"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]
                 forState:UIControlStateNormal];
    finishButton.imageView.contentMode = UIViewContentModeCenter;
    finishButton.accessibilityLabel = [YKCipherLoom yk_unfurl:@"PPROPVASWyr73rD2oUKQ6w=="];
    [finishButton addTarget:self action:@selector(yk_finishTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:finishButton];

    [NSLayoutConstraint activateConstraints:@[
        [portraitView.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [portraitView.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor constant:-140.0],
        [portraitView.widthAnchor constraintEqualToConstant:116.0],
        [portraitView.heightAnchor constraintEqualToConstant:116.0],

        [nameLabel.topAnchor constraintEqualToAnchor:portraitView.bottomAnchor constant:20.0],
        [nameLabel.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:24.0],
        [nameLabel.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-24.0],

        [stateLabel.topAnchor constraintEqualToAnchor:nameLabel.bottomAnchor constant:8.0],
        [stateLabel.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:24.0],
        [stateLabel.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-24.0],

        [finishButton.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [finishButton.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor constant:-54.0],
        [finishButton.widthAnchor constraintEqualToConstant:84.0],
        [finishButton.heightAnchor constraintEqualToConstant:84.0]
    ]];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    UIGestureRecognizer *popGesture = self.navigationController.interactivePopGestureRecognizer;
    if (popGesture && !self.yk_hasSavedPopGestureState) {
        self.yk_savedPopGestureState = popGesture.enabled;
        self.yk_hasSavedPopGestureState = YES;
        popGesture.enabled = NO;
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (!self.yk_concluded && self.responseTimer == nil) {
        [self.toneLoop yk_begin];
        NSTimer *timer = [NSTimer timerWithTimeInterval:20.0
                                                target:self
                                              selector:@selector(yk_responseWindowElapsed:)
                                              userInfo:nil
                                               repeats:NO];
        [[NSRunLoop mainRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
        self.responseTimer = timer;
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self yk_haltReach];
    if (self.yk_hasSavedPopGestureState) {
        self.navigationController.interactivePopGestureRecognizer.enabled = self.yk_savedPopGestureState;
        self.yk_hasSavedPopGestureState = NO;
    }
}

- (void)dealloc {
    [self yk_haltReach];
}

- (void)yk_finishTapped:(UIButton *)sender {
    if (self.yk_concluded) {
        return;
    }
    self.yk_concluded = YES;
    [self yk_haltReach];

    UINavigationController *navigationController = self.navigationController;
    UIViewController *destination = navigationController.viewControllers.count > 1
        ? navigationController.viewControllers[navigationController.viewControllers.count - 2]
        : nil;
    [navigationController popViewControllerAnimated:YES];

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.35 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (destination.viewIfLoaded.window) {
            [YKCenterToast yk_showNotice:[YKCipherLoom yk_unfurl:@"+VsSnRGBaqtEHCVW28Xw+A=="]
                                  inView:destination.view];
        }
    });
}

- (void)yk_responseWindowElapsed:(NSTimer *)timer {
    if (self.yk_concluded) {
        return;
    }
    self.yk_concluded = YES;
    [self yk_haltReach];

    NSString *notice = [YKCipherLoom yk_unfurl:@"X6OncWwwBdlaSqgPGP0qyg=="];
    self.stateLabel.text = notice;
    [YKCenterToast yk_showNotice:notice inView:self.view];

    __weak typeof(self) weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.8 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        typeof(self) self = weakSelf;
        if (self && self.navigationController.topViewController == self) {
            [self.navigationController popViewControllerAnimated:YES];
        }
    });
}

- (void)yk_haltReach {
    [self.responseTimer invalidate];
    self.responseTimer = nil;
    [self.toneLoop yk_halt];
}

@end
