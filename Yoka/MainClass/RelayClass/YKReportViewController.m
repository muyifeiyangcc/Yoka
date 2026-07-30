//
//  YKReportViewController.m
//  Yoka
//

#import "YKReportViewController.h"
#import "../../BaseClass/YKCenterToast.h"

@interface YKReportViewController () <UITextViewDelegate>

@property (nonatomic, copy) NSString *personaId;
@property (nonatomic, strong) NSArray<NSString *> *yk_reasons;
@property (nonatomic, strong) NSMutableArray<UIButton *> *yk_reasonButtons;
@property (nonatomic, assign) NSInteger yk_selectedIndex;
@property (nonatomic, strong) UIScrollView *yk_scrollView;
@property (nonatomic, strong) UITextView *yk_otherTextView;
@property (nonatomic, strong) UILabel *yk_otherHintLabel;
@property (nonatomic, strong) UIButton *yk_submitButton;
@property (nonatomic, strong) NSLayoutConstraint *yk_submitBottomConstraint;

@end

@implementation YKReportViewController

- (instancetype)initWithPersonaId:(NSString *)personaId {
    self = [super init];
    if (self) {
        _personaId = [personaId copy] ?: @"";
        _yk_selectedIndex = 0;
        _yk_reasonButtons = [NSMutableArray array];
        _yk_reasons = @[
            @"Pornographic and vulgar",
            @"False information",
            @"Verbal attack",
            @"Violent terror",
            @"Copyright infringement",
            @"Frequent harassment"
        ];
    }
    return self;
}

- (instancetype)init {
    return [self initWithPersonaId:nil];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)yk_configurePage {
    [super yk_configurePage];
    [self yk_setupViews];
    [self yk_installKeyboardObservers];
}

- (void)yk_installKeyboardObservers {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(yk_keyboardWillChange:)
                                                 name:UIKeyboardWillChangeFrameNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(yk_keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
}

- (void)yk_setupViews {
    UIButton *backButton = [self yk_addBackButton];

    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    titleLabel.text = @"Report";
    titleLabel.textColor = UIColor.whiteColor;
    titleLabel.font = [UIFont fontWithName:@"Limelight" size:22.0] ?: [UIFont systemFontOfSize:22.0 weight:UIFontWeightBold];
    [self.view addSubview:titleLabel];

    UIScrollView *scroll = [[UIScrollView alloc] init];
    scroll.translatesAutoresizingMaskIntoConstraints = NO;
    scroll.showsVerticalScrollIndicator = NO;
    scroll.alwaysBounceVertical = YES;
    scroll.keyboardDismissMode = UIScrollViewKeyboardDismissModeInteractive;
    scroll.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    [self.view addSubview:scroll];
    self.yk_scrollView = scroll;

    UIView *content = [[UIView alloc] init];
    content.translatesAutoresizingMaskIntoConstraints = NO;
    [scroll addSubview:content];

    UIStackView *reasonStack = [[UIStackView alloc] init];
    reasonStack.translatesAutoresizingMaskIntoConstraints = NO;
    reasonStack.axis = UILayoutConstraintAxisVertical;
    reasonStack.spacing = 12.0;
    reasonStack.alignment = UIStackViewAlignmentFill;
    [content addSubview:reasonStack];

    for (NSInteger i = 0; i < (NSInteger)self.yk_reasons.count; i++) {
        UIButton *button = [self yk_reasonButtonWithTitle:self.yk_reasons[i] tag:i];
        [reasonStack addArrangedSubview:button];
        [self.yk_reasonButtons addObject:button];
        [button.heightAnchor constraintEqualToConstant:44.0].active = YES;
    }
    [self yk_refreshReasonSelection];

    UILabel *otherLabel = [[UILabel alloc] init];
    otherLabel.translatesAutoresizingMaskIntoConstraints = NO;
    otherLabel.text = @"Other";
    otherLabel.textColor = UIColor.whiteColor;
    otherLabel.font = [UIFont fontWithName:@"Limelight" size:20.0] ?: [UIFont systemFontOfSize:20.0 weight:UIFontWeightBold];
    [content addSubview:otherLabel];

    UITextView *otherText = [[UITextView alloc] init];
    otherText.translatesAutoresizingMaskIntoConstraints = NO;
    otherText.backgroundColor = UIColor.whiteColor;
    otherText.textColor = UIColor.blackColor;
    otherText.font = [UIFont systemFontOfSize:15.0];
    otherText.textContainerInset = UIEdgeInsetsMake(12.0, 10.0, 12.0, 10.0);
    otherText.layer.borderColor = UIColor.blackColor.CGColor;
    otherText.layer.borderWidth = 2.0;
    otherText.delegate = self;
    [content addSubview:otherText];
    self.yk_otherTextView = otherText;

    UILabel *placeholder = [[UILabel alloc] init];
    placeholder.translatesAutoresizingMaskIntoConstraints = NO;
    placeholder.text = @"Write down other reasons...";
    placeholder.textColor = [UIColor colorWithWhite:0.55 alpha:1.0];
    placeholder.font = [UIFont systemFontOfSize:15.0];
    placeholder.userInteractionEnabled = NO;
    [otherText addSubview:placeholder];
    self.yk_otherHintLabel = placeholder;

    UIButton *submitButton = [UIButton buttonWithType:UIButtonTypeCustom];
    submitButton.translatesAutoresizingMaskIntoConstraints = NO;
    submitButton.backgroundColor = UIColor.clearColor;
    submitButton.adjustsImageWhenHighlighted = YES;
    UIImage *submitImage = [[UIImage imageNamed:@"report_submit_button"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    [submitButton setBackgroundImage:submitImage forState:UIControlStateNormal];
    [submitButton setBackgroundImage:submitImage forState:UIControlStateHighlighted];
    [submitButton addTarget:self action:@selector(yk_submitTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:submitButton];
    self.yk_submitButton = submitButton;

    self.yk_submitBottomConstraint = [submitButton.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor
                                                                              constant:-(self.view.safeAreaInsets.bottom + 18.0)];

    [NSLayoutConstraint activateConstraints:@[
        [titleLabel.centerYAnchor constraintEqualToAnchor:backButton.centerYAnchor],
        [titleLabel.leadingAnchor constraintEqualToAnchor:backButton.trailingAnchor constant:2.0],

        [submitButton.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        self.yk_submitBottomConstraint,
        [submitButton.widthAnchor constraintEqualToConstant:215.0],
        [submitButton.heightAnchor constraintEqualToConstant:49.0],

        [scroll.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:56.0],
        [scroll.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [scroll.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [scroll.bottomAnchor constraintEqualToAnchor:submitButton.topAnchor constant:-16.0],

        [content.topAnchor constraintEqualToAnchor:scroll.contentLayoutGuide.topAnchor],
        [content.leadingAnchor constraintEqualToAnchor:scroll.contentLayoutGuide.leadingAnchor],
        [content.trailingAnchor constraintEqualToAnchor:scroll.contentLayoutGuide.trailingAnchor],
        [content.bottomAnchor constraintEqualToAnchor:scroll.contentLayoutGuide.bottomAnchor],
        [content.widthAnchor constraintEqualToAnchor:scroll.frameLayoutGuide.widthAnchor],

        [reasonStack.topAnchor constraintEqualToAnchor:content.topAnchor constant:8.0],
        [reasonStack.leadingAnchor constraintEqualToAnchor:content.leadingAnchor constant:28.0],
        [reasonStack.trailingAnchor constraintEqualToAnchor:content.trailingAnchor constant:-28.0],

        [otherLabel.topAnchor constraintEqualToAnchor:reasonStack.bottomAnchor constant:22.0],
        [otherLabel.leadingAnchor constraintEqualToAnchor:reasonStack.leadingAnchor],

        [otherText.topAnchor constraintEqualToAnchor:otherLabel.bottomAnchor constant:12.0],
        [otherText.leadingAnchor constraintEqualToAnchor:reasonStack.leadingAnchor],
        [otherText.trailingAnchor constraintEqualToAnchor:reasonStack.trailingAnchor],
        [otherText.heightAnchor constraintEqualToConstant:120.0],
        [otherText.bottomAnchor constraintEqualToAnchor:content.bottomAnchor constant:-24.0],

        [placeholder.topAnchor constraintEqualToAnchor:otherText.topAnchor constant:12.0],
        [placeholder.leadingAnchor constraintEqualToAnchor:otherText.leadingAnchor constant:15.0]
    ]];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    if (!self.yk_otherTextView.isFirstResponder) {
        CGFloat bottom = MAX(self.view.safeAreaInsets.bottom, 8.0) + 18.0;
        if (fabs(self.yk_submitBottomConstraint.constant + bottom) > 0.5) {
            self.yk_submitBottomConstraint.constant = -bottom;
        }
    }
}

- (UIButton *)yk_reasonButtonWithTitle:(NSString *)title tag:(NSInteger)tag {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.translatesAutoresizingMaskIntoConstraints = NO;
    button.tag = tag;
    button.layer.borderWidth = 2.0;
    button.titleLabel.font = [UIFont systemFontOfSize:16.0 weight:UIFontWeightRegular];
    button.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
    [button setTitle:title forState:UIControlStateNormal];
    [button addTarget:self action:@selector(yk_reasonTapped:) forControlEvents:UIControlEventTouchUpInside];
    return button;
}

- (void)yk_reasonTapped:(UIButton *)sender {
    self.yk_selectedIndex = sender.tag;
    [self yk_refreshReasonSelection];
}

- (void)yk_refreshReasonSelection {
    UIColor *selectedFill = [UIColor colorWithRed:0.86 green:0.42 blue:0.95 alpha:1.0];
    for (UIButton *button in self.yk_reasonButtons) {
        BOOL selected = button.tag == self.yk_selectedIndex;
        if (selected) {
            button.backgroundColor = selectedFill;
            button.layer.borderColor = UIColor.whiteColor.CGColor;
            [button setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
        } else {
            button.backgroundColor = UIColor.whiteColor;
            button.layer.borderColor = UIColor.blackColor.CGColor;
            [button setTitleColor:UIColor.blackColor forState:UIControlStateNormal];
        }
    }
}

- (void)textViewDidChange:(UITextView *)textView {
    self.yk_otherHintLabel.hidden = textView.text.length > 0;
}

#pragma mark - Keyboard

- (void)yk_keyboardWillChange:(NSNotification *)note {
    NSDictionary *info = note.userInfo;
    CGRect endFrame = [info[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGRect endInView = [self.view convertRect:endFrame fromView:nil];
    CGFloat overlap = MAX(0.0, CGRectGetMaxY(self.view.bounds) - CGRectGetMinY(endInView));
    if (overlap < 1.0) {
        overlap = 0.0;
    }
    [self yk_applyKeyboardOverlap:overlap userInfo:info];
}

- (void)yk_keyboardWillHide:(NSNotification *)note {
    [self yk_applyKeyboardOverlap:0.0 userInfo:note.userInfo];
}

- (void)yk_applyKeyboardOverlap:(CGFloat)overlap userInfo:(NSDictionary *)info {
    CGFloat bottomPad;
    if (overlap > 0.5) {
        bottomPad = overlap + 12.0;
    } else {
        bottomPad = MAX(self.view.safeAreaInsets.bottom, 8.0) + 18.0;
    }
    self.yk_submitBottomConstraint.constant = -bottomPad;

    NSTimeInterval duration = [info[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    UIViewAnimationOptions curve = ([info[UIKeyboardAnimationCurveUserInfoKey] integerValue] << 16);
    if (duration <= 0) {
        duration = 0.25;
    }

    [UIView animateWithDuration:duration
                          delay:0
                        options:curve | UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
        [self.view layoutIfNeeded];
    } completion:^(BOOL finished) {
        if (overlap > 0.5 && self.yk_otherTextView.isFirstResponder) {
            [self yk_scrollOtherFieldVisible];
        }
    }];
}

- (void)yk_scrollOtherFieldVisible {
    UIScrollView *scroll = self.yk_scrollView;
    UIView *field = self.yk_otherTextView;
    if (!scroll || !field) {
        return;
    }
    [scroll layoutIfNeeded];
    CGRect fieldFrame = [field convertRect:field.bounds toView:scroll];
    fieldFrame = CGRectInset(fieldFrame, 0.0, -20.0);
    [scroll scrollRectToVisible:fieldFrame animated:YES];
}

- (void)yk_submitTapped:(UIButton *)sender {
    [self.view endEditing:YES];
    __weak typeof(self) weakSelf = self;
    [YKCenterToast yk_showLoadingInView:self.view performAfterDelay:0.55 work:^{
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) { return; }
        [YKCenterToast yk_showNotice:@"Report submitted" inView:self.view];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.7 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self.navigationController popViewControllerAnimated:YES];
        });
    }];
}

@end
