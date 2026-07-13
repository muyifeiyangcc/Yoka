//
//  YKChatViewController.m
//  Yoka
//

#import "YKChatViewController.h"

@interface YKChatViewController ()

@property (nonatomic, copy) NSString *userName;
@property (nonatomic, strong) UIColor *tintColor;
@property (nonatomic, strong) UIView *inputFieldView;
@property (nonatomic, strong) UIView *voicePanelView;

@end

@implementation YKChatViewController

- (instancetype)initWithUserName:(NSString *)userName tintColor:(UIColor *)tintColor {
    self = [super init];
    if (self) {
        _userName = userName.length > 0 ? [userName copy] : @"Freya";
        _tintColor = tintColor ?: [UIColor colorWithRed:0.56 green:0.33 blue:0.32 alpha:1.0];
    }
    return self;
}

- (void)yk_configurePage {
    [super yk_configurePage];
    [self yk_setupViews];
}

- (void)yk_setupViews {
    UIButton *backButton = [self yk_addBackButton];

    UIImageView *avatarImageView = [self yk_avatarImageViewWithSize:44.0];
    [self.view addSubview:avatarImageView];

    UILabel *nameLabel = [[UILabel alloc] init];
    nameLabel.translatesAutoresizingMaskIntoConstraints = NO;
    nameLabel.text = self.userName;
    nameLabel.textColor = UIColor.whiteColor;
    nameLabel.font = [UIFont systemFontOfSize:20.0 weight:UIFontWeightBold];
    [self.view addSubview:nameLabel];

    UIButton *moreButton = [UIButton buttonWithType:UIButtonTypeCustom];
    moreButton.translatesAutoresizingMaskIntoConstraints = NO;
    [moreButton setImage:[[UIImage imageNamed:@"detail_more_button"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] forState:UIControlStateNormal];
    [self.view addSubview:moreButton];

    UIView *incomingText = [self yk_textBubbleWithText:@"Hey! Thanks for connecting. How's\nyour day going?"
                                            incoming:YES];
    [self.view addSubview:incomingText];

    UIImageView *incomingAvatar1 = [self yk_avatarImageViewWithSize:40.0];
    [self.view addSubview:incomingAvatar1];

    UIView *outgoingText = [self yk_textBubbleWithText:@"Hey! Thanks for connecting. How's\nyour day going?"
                                            incoming:NO];
    [self.view addSubview:outgoingText];

    UIImageView *outgoingAvatar1 = [self yk_avatarImageViewWithSize:40.0];
    [self.view addSubview:outgoingAvatar1];

    UIView *incomingVoice = [self yk_voiceBubbleIncoming:YES];
    [self.view addSubview:incomingVoice];

    UIImageView *incomingAvatar2 = [self yk_avatarImageViewWithSize:40.0];
    [self.view addSubview:incomingAvatar2];

    UIView *outgoingVoice = [self yk_voiceBubbleIncoming:NO];
    [self.view addSubview:outgoingVoice];

    UIImageView *outgoingAvatar2 = [self yk_avatarImageViewWithSize:40.0];
    [self.view addSubview:outgoingAvatar2];

    UIView *inputContainer = [[UIView alloc] init];
    inputContainer.translatesAutoresizingMaskIntoConstraints = NO;
    inputContainer.backgroundColor = [UIColor colorWithRed:0.91 green:0.30 blue:0.94 alpha:0.92];
    inputContainer.layer.cornerRadius = 28.0;
    inputContainer.layer.borderColor = UIColor.whiteColor.CGColor;
    inputContainer.layer.borderWidth = 1.5;
    [self.view addSubview:inputContainer];

    UIView *inputFieldView = [[UIView alloc] init];
    inputFieldView.translatesAutoresizingMaskIntoConstraints = NO;
    inputFieldView.backgroundColor = UIColor.whiteColor;
    inputFieldView.layer.cornerRadius = 23.0;
    [inputContainer addSubview:inputFieldView];
    self.inputFieldView = inputFieldView;

    UITextField *textField = [[UITextField alloc] init];
    textField.translatesAutoresizingMaskIntoConstraints = NO;
    textField.placeholder = @"Say something";
    textField.textColor = UIColor.blackColor;
    textField.tintColor = [UIColor colorWithRed:0.46 green:0.15 blue:0.90 alpha:1.0];
    textField.font = [UIFont systemFontOfSize:16.0];
    [inputFieldView addSubview:textField];

    UIButton *voiceButton = [UIButton buttonWithType:UIButtonTypeCustom];
    voiceButton.translatesAutoresizingMaskIntoConstraints = NO;
    [voiceButton setImage:[[UIImage imageNamed:@"talkimage"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] forState:UIControlStateNormal];
    [voiceButton addTarget:self action:@selector(yk_voiceButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [inputFieldView addSubview:voiceButton];

    UIButton *sendButton = [UIButton buttonWithType:UIButtonTypeCustom];
    sendButton.translatesAutoresizingMaskIntoConstraints = NO;
    [sendButton setImage:[[UIImage imageNamed:@"messend"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] forState:UIControlStateNormal];
    [inputFieldView addSubview:sendButton];

    UIView *voicePanelView = [[UIView alloc] init];
    voicePanelView.translatesAutoresizingMaskIntoConstraints = NO;
    voicePanelView.hidden = YES;
    [inputContainer addSubview:voicePanelView];
    self.voicePanelView = voicePanelView;

    UIButton *recordButton = [UIButton buttonWithType:UIButtonTypeCustom];
    recordButton.translatesAutoresizingMaskIntoConstraints = NO;
    recordButton.backgroundColor = UIColor.whiteColor;
    recordButton.layer.cornerRadius = 38.0;
    recordButton.layer.masksToBounds = YES;
    [recordButton setImage:[[UIImage imageNamed:@"talkimage"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] forState:UIControlStateNormal];
    [voicePanelView addSubview:recordButton];

    UILayoutGuide *safeGuide = self.view.safeAreaLayoutGuide;
    [NSLayoutConstraint activateConstraints:@[
        [avatarImageView.centerYAnchor constraintEqualToAnchor:backButton.centerYAnchor],
        [avatarImageView.leadingAnchor constraintEqualToAnchor:backButton.trailingAnchor constant:16.0],
        [avatarImageView.widthAnchor constraintEqualToConstant:44.0],
        [avatarImageView.heightAnchor constraintEqualToConstant:44.0],

        [nameLabel.centerYAnchor constraintEqualToAnchor:avatarImageView.centerYAnchor],
        [nameLabel.leadingAnchor constraintEqualToAnchor:avatarImageView.trailingAnchor constant:10.0],

        [moreButton.centerYAnchor constraintEqualToAnchor:avatarImageView.centerYAnchor],
        [moreButton.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-24.0],
        [moreButton.widthAnchor constraintEqualToConstant:36.0],
        [moreButton.heightAnchor constraintEqualToConstant:36.0],

        [incomingAvatar1.topAnchor constraintEqualToAnchor:safeGuide.topAnchor constant:118.0],
        [incomingAvatar1.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:28.0],
        [incomingAvatar1.widthAnchor constraintEqualToConstant:40.0],
        [incomingAvatar1.heightAnchor constraintEqualToConstant:40.0],

        [incomingText.topAnchor constraintEqualToAnchor:incomingAvatar1.topAnchor],
        [incomingText.leadingAnchor constraintEqualToAnchor:incomingAvatar1.trailingAnchor constant:12.0],
        [incomingText.widthAnchor constraintEqualToConstant:248.0],
        [incomingText.heightAnchor constraintEqualToConstant:58.0],

        [outgoingAvatar1.topAnchor constraintEqualToAnchor:incomingText.bottomAnchor constant:32.0],
        [outgoingAvatar1.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-24.0],
        [outgoingAvatar1.widthAnchor constraintEqualToConstant:40.0],
        [outgoingAvatar1.heightAnchor constraintEqualToConstant:40.0],

        [outgoingText.topAnchor constraintEqualToAnchor:incomingText.bottomAnchor constant:30.0],
        [outgoingText.trailingAnchor constraintEqualToAnchor:outgoingAvatar1.leadingAnchor constant:-12.0],
        [outgoingText.widthAnchor constraintEqualToConstant:248.0],
        [outgoingText.heightAnchor constraintEqualToConstant:58.0],

        [incomingAvatar2.topAnchor constraintEqualToAnchor:outgoingText.bottomAnchor constant:34.0],
        [incomingAvatar2.leadingAnchor constraintEqualToAnchor:incomingAvatar1.leadingAnchor],
        [incomingAvatar2.widthAnchor constraintEqualToConstant:40.0],
        [incomingAvatar2.heightAnchor constraintEqualToConstant:40.0],

        [incomingVoice.centerYAnchor constraintEqualToAnchor:incomingAvatar2.centerYAnchor],
        [incomingVoice.leadingAnchor constraintEqualToAnchor:incomingAvatar2.trailingAnchor constant:12.0],
        [incomingVoice.widthAnchor constraintEqualToConstant:88.0],
        [incomingVoice.heightAnchor constraintEqualToConstant:42.0],

        [outgoingAvatar2.topAnchor constraintEqualToAnchor:incomingVoice.bottomAnchor constant:34.0],
        [outgoingAvatar2.trailingAnchor constraintEqualToAnchor:outgoingAvatar1.trailingAnchor],
        [outgoingAvatar2.widthAnchor constraintEqualToConstant:40.0],
        [outgoingAvatar2.heightAnchor constraintEqualToConstant:40.0],

        [outgoingVoice.centerYAnchor constraintEqualToAnchor:outgoingAvatar2.centerYAnchor],
        [outgoingVoice.trailingAnchor constraintEqualToAnchor:outgoingAvatar2.leadingAnchor constant:-12.0],
        [outgoingVoice.widthAnchor constraintEqualToConstant:82.0],
        [outgoingVoice.heightAnchor constraintEqualToConstant:42.0],

        [inputContainer.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [inputContainer.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [inputContainer.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
        [inputContainer.heightAnchor constraintEqualToConstant:108.0],

        [inputFieldView.leadingAnchor constraintEqualToAnchor:inputContainer.leadingAnchor constant:26.0],
        [inputFieldView.trailingAnchor constraintEqualToAnchor:inputContainer.trailingAnchor constant:-26.0],
        [inputFieldView.topAnchor constraintEqualToAnchor:inputContainer.topAnchor constant:22.0],
        [inputFieldView.heightAnchor constraintEqualToConstant:52.0],

        [textField.centerYAnchor constraintEqualToAnchor:inputFieldView.centerYAnchor],
        [textField.leadingAnchor constraintEqualToAnchor:inputFieldView.leadingAnchor constant:18.0],
        [textField.trailingAnchor constraintEqualToAnchor:voiceButton.leadingAnchor constant:-12.0],

        [sendButton.centerYAnchor constraintEqualToAnchor:inputFieldView.centerYAnchor],
        [sendButton.trailingAnchor constraintEqualToAnchor:inputFieldView.trailingAnchor constant:-5.0],
        [sendButton.widthAnchor constraintEqualToConstant:44.0],
        [sendButton.heightAnchor constraintEqualToConstant:44.0],

        [voiceButton.centerYAnchor constraintEqualToAnchor:inputFieldView.centerYAnchor],
        [voiceButton.trailingAnchor constraintEqualToAnchor:sendButton.leadingAnchor constant:-12.0],
        [voiceButton.widthAnchor constraintEqualToConstant:32.0],
        [voiceButton.heightAnchor constraintEqualToConstant:32.0],

        [voicePanelView.topAnchor constraintEqualToAnchor:inputContainer.topAnchor],
        [voicePanelView.leadingAnchor constraintEqualToAnchor:inputContainer.leadingAnchor],
        [voicePanelView.trailingAnchor constraintEqualToAnchor:inputContainer.trailingAnchor],
        [voicePanelView.bottomAnchor constraintEqualToAnchor:inputContainer.bottomAnchor],

        [recordButton.centerXAnchor constraintEqualToAnchor:voicePanelView.centerXAnchor],
        [recordButton.topAnchor constraintEqualToAnchor:voicePanelView.topAnchor constant:22.0],
        [recordButton.widthAnchor constraintEqualToConstant:76.0],
        [recordButton.heightAnchor constraintEqualToConstant:76.0]
    ]];
}

- (void)yk_voiceButtonTapped:(UIButton *)sender {
    [self.view endEditing:YES];
    self.inputFieldView.hidden = YES;
    self.voicePanelView.hidden = NO;
}

- (UIImageView *)yk_avatarImageViewWithSize:(CGFloat)size {
    UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"headplace"]];
    imageView.translatesAutoresizingMaskIntoConstraints = NO;
    imageView.backgroundColor = self.tintColor;
    imageView.contentMode = UIViewContentModeScaleAspectFill;
    imageView.layer.cornerRadius = size * 0.5;
    imageView.layer.masksToBounds = YES;
    return imageView;
}

- (UIView *)yk_textBubbleWithText:(NSString *)text incoming:(BOOL)incoming {
    UILabel *label = [[UILabel alloc] init];
    label.translatesAutoresizingMaskIntoConstraints = NO;
    label.numberOfLines = 0;
    label.text = text;
    label.font = [UIFont systemFontOfSize:15.0];
    label.textColor = incoming ? UIColor.blackColor : UIColor.whiteColor;

    UIView *bubbleView = [[UIView alloc] init];
    bubbleView.translatesAutoresizingMaskIntoConstraints = NO;
    bubbleView.backgroundColor = incoming ? UIColor.whiteColor : [UIColor colorWithWhite:1.0 alpha:0.12];
    bubbleView.layer.borderColor = (incoming ? UIColor.blackColor : UIColor.whiteColor).CGColor;
    bubbleView.layer.borderWidth = 2.0;
    [bubbleView addSubview:label];

    [NSLayoutConstraint activateConstraints:@[
        [label.topAnchor constraintEqualToAnchor:bubbleView.topAnchor constant:8.0],
        [label.leadingAnchor constraintEqualToAnchor:bubbleView.leadingAnchor constant:12.0],
        [label.trailingAnchor constraintEqualToAnchor:bubbleView.trailingAnchor constant:-12.0],
        [label.bottomAnchor constraintEqualToAnchor:bubbleView.bottomAnchor constant:-8.0]
    ]];

    return bubbleView;
}

- (UIView *)yk_voiceBubbleIncoming:(BOOL)incoming {
    UIView *bubbleView = [[UIView alloc] init];
    bubbleView.translatesAutoresizingMaskIntoConstraints = NO;
    bubbleView.backgroundColor = incoming ? UIColor.whiteColor : [UIColor colorWithWhite:1.0 alpha:0.12];
    bubbleView.layer.borderColor = (incoming ? UIColor.blackColor : UIColor.whiteColor).CGColor;
    bubbleView.layer.borderWidth = 2.0;

    UIImage *voiceImage = [[UIImage imageNamed:@"mesvoiceimage"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    UIImageView *voiceImageView = [[UIImageView alloc] initWithImage:voiceImage];
    voiceImageView.translatesAutoresizingMaskIntoConstraints = NO;
    voiceImageView.contentMode = UIViewContentModeScaleAspectFit;
    voiceImageView.tintColor = incoming ? UIColor.blackColor : UIColor.whiteColor;
    [bubbleView addSubview:voiceImageView];

    UILabel *durationLabel = [[UILabel alloc] init];
    durationLabel.translatesAutoresizingMaskIntoConstraints = NO;
    durationLabel.text = @"21'";
    durationLabel.textColor = incoming ? UIColor.blackColor : UIColor.whiteColor;
    durationLabel.font = [UIFont systemFontOfSize:15.0 weight:UIFontWeightMedium];
    [bubbleView addSubview:durationLabel];

    [NSLayoutConstraint activateConstraints:@[
        [voiceImageView.leadingAnchor constraintEqualToAnchor:bubbleView.leadingAnchor constant:14.0],
        [voiceImageView.centerYAnchor constraintEqualToAnchor:bubbleView.centerYAnchor],
        [voiceImageView.widthAnchor constraintEqualToConstant:24.0],
        [voiceImageView.heightAnchor constraintEqualToConstant:24.0],

        [durationLabel.centerYAnchor constraintEqualToAnchor:bubbleView.centerYAnchor],
        [durationLabel.leadingAnchor constraintEqualToAnchor:voiceImageView.trailingAnchor constant:12.0]
    ]];
    return bubbleView;
}

@end
