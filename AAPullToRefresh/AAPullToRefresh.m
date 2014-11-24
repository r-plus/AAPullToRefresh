#import "AAPullToRefresh.h"

#define DEGREES_TO_RADIANS(x) (x)/180.0*M_PI
#define RADIANS_TO_DEGREES(x) (x)/M_PI*180.0

@implementation UIScrollView (AAPullToRefresh)

- (AAPullToRefresh *)addPullToRefreshPosition:(AAPullToRefreshPosition)position actionHandler:(void (^)(AAPullToRefresh *v))handler
{
    // dont dupuricate add.
    for (UIView *v in self.subviews) {
        if ([v isKindOfClass:[AAPullToRefresh class]])
            if (((AAPullToRefresh *)v).position == position)
                return (AAPullToRefresh *)v;
    }

    AAPullToRefresh *view = [[AAPullToRefresh alloc] initWithImage:[UIImage imageNamed:@"centerIcon"]
                                                          position:position];
    switch (view.position) {
        case AAPullToRefreshPositionTop:
        case AAPullToRefreshPositionBottom:
            view.frame = CGRectMake((self.bounds.size.width - view.bounds.size.width)/2,
                    -view.bounds.size.height, view.bounds.size.width, view.bounds.size.height);
            break;
        case AAPullToRefreshPositionLeft:
            view.frame = CGRectMake(-view.bounds.size.width, self.bounds.size.height/2.0f, view.bounds.size.width, view.bounds.size.height);
            break;
        case AAPullToRefreshPositionRight:
            view.frame = CGRectMake(self.bounds.size.width, self.bounds.size.height/2.0f, view.bounds.size.width, view.bounds.size.height);
            break;
        default:
            break;
    }
    
    view.pullToRefreshHandler = handler;
    view.scrollView = self;
    view.originalInsetTop = self.contentInset.top;
    view.originalInsetBottom = self.contentInset.bottom;
    view.showPullToRefresh = YES;
    view.alpha = 0.0;
    [self addSubview:view];
    
    return view;
}
@end

@interface AAPullToRefreshBackgroundLayer : CALayer

@property (nonatomic, assign) CGFloat outlineWidth;
@property (nonatomic, assign, getter = isGlow) BOOL glow;
- (id)initWithBorderWidth:(CGFloat)width;

@end

@implementation AAPullToRefreshBackgroundLayer

- (id)initWithBorderWidth:(CGFloat)width
{
    if ((self = [super init])) {
        self.outlineWidth = width;
        self.contentsScale = [UIScreen mainScreen].scale;
        self.shadowColor = [UIColor whiteColor].CGColor;
        self.shadowOffset = CGSizeZero;
        self.shadowRadius = 7.0f;
        self.shadowOpacity = 0.0f;
        [self setNeedsDisplay];
    }
    return self;
}

- (void)drawInContext:(CGContextRef)ctx
{
    //Draw white circle
    CGContextSetFillColor(ctx, CGColorGetComponents([UIColor colorWithWhite:1.0f alpha:0.8f].CGColor));
    CGContextFillEllipseInRect(ctx,CGRectInset(self.bounds, self.outlineWidth, self.outlineWidth));
    
    //Draw circle outline
    CGContextSetStrokeColorWithColor(ctx, [UIColor colorWithWhite:0.4f alpha:0.9f].CGColor);
    CGContextSetLineWidth(ctx, self.outlineWidth);
    CGContextStrokeEllipseInRect(ctx, CGRectInset(self.bounds, self.outlineWidth, self.outlineWidth));
}

- (void)setOutlineWidth:(CGFloat)outlineWidth
{
    _outlineWidth = outlineWidth;
    [self setNeedsDisplay];
}

- (void)setGlow:(BOOL)glow
{
    self.shadowOpacity = glow ? 1.0 : 0.0;
    _glow = glow;
}

@end

/*-----------------------------------------------------------------*/
@interface AAPullToRefresh()

@property (nonatomic, assign) BOOL isUserAction;
@property (nonatomic, assign) AAPullToRefreshState state;
@property (nonatomic, assign, readonly) BOOL isSidePosition;
@property (nonatomic, strong) AAPullToRefreshBackgroundLayer *backgroundLayer;
@property (nonatomic, strong) CAShapeLayer *shapeLayer;
@property (nonatomic, strong) CALayer *imageLayer;
@property (nonatomic, assign) double progress;
@property (nonatomic, assign) double prevProgress;

@end

@implementation AAPullToRefresh

#pragma mark - init
- (id)initWithImage:(UIImage *)image position:(AAPullToRefreshPosition)position
{
    if ((self = [super init])) {
        _position = position;
        self.imageIcon = image;
        [self _commonInit];
    }
    return self;
}

- (void)_commonInit
{
    self.borderColor = [UIColor colorWithRed:203/255.0 green:32/255.0 blue:39/255.0 alpha:1];
    self.borderWidth = 2.0f;
    self.threshold = 60.0f;
    self.isUserAction = NO;
    self.contentMode = UIViewContentModeRedraw;
    self.state = AAPullToRefreshStateNormal;
    if (self.isSidePosition)
        self.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    else
        self.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
    self.backgroundColor = [UIColor clearColor];
    //init actitvity indicator
    _activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    _activityIndicatorView.hidesWhenStopped = YES;
    _activityIndicatorView.frame = self.bounds;
    [self addSubview:_activityIndicatorView];
    
    //init background layer
    AAPullToRefreshBackgroundLayer *backgroundLayer = [[AAPullToRefreshBackgroundLayer alloc] initWithBorderWidth:self.borderWidth];
    backgroundLayer.frame = self.bounds;
    [self.layer addSublayer:backgroundLayer];
    self.backgroundLayer = backgroundLayer;
    
    if (!self.imageIcon)
        self.imageIcon = [UIImage imageNamed:@"centerIcon"];
    
    //init icon layer
    CALayer *imageLayer = [CALayer layer];
    imageLayer.contentsScale = [UIScreen mainScreen].scale;
    imageLayer.frame = CGRectInset(self.bounds, self.borderWidth, self.borderWidth);
    imageLayer.contents = (id)self.imageIcon.CGImage;
    [self.layer addSublayer:imageLayer];
    self.imageLayer = imageLayer;
    
    //init arc draw layer
    CAShapeLayer *shapeLayer = [[CAShapeLayer alloc] init];
    shapeLayer.frame = self.bounds;
    shapeLayer.fillColor = nil;
    shapeLayer.strokeColor = self.borderColor.CGColor;
    shapeLayer.strokeEnd = 0.0f;
    shapeLayer.shadowColor = [UIColor colorWithWhite:1 alpha:0.8f].CGColor;
    shapeLayer.shadowOpacity = 0.7f;
    shapeLayer.shadowRadius = 20.0f;
    shapeLayer.contentsScale = [UIScreen mainScreen].scale;
    shapeLayer.lineWidth = self.borderWidth;
    shapeLayer.lineCap = kCALineCapRound;
    
    [self.layer addSublayer:shapeLayer];
    self.shapeLayer = shapeLayer;
}

#pragma mark - layout
- (void)layoutSubviews{
    [super layoutSubviews];
    self.shapeLayer.frame = self.bounds;
    [self updatePath];
}

- (void)updatePath {
    CGPoint center = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
    
    UIBezierPath *bezierPath = [UIBezierPath bezierPathWithArcCenter:center radius:(self.bounds.size.width/2.0f - self.borderWidth)  startAngle:DEGREES_TO_RADIANS(-90) endAngle:DEGREES_TO_RADIANS(360-90) clockwise:YES];
    
    self.shapeLayer.path = bezierPath.CGPath;
}

#pragma mark - ScrollViewInset
- (void)setupScrollViewContentInsetForLoadingIndicator:(actionHandler)handler
{
    UIEdgeInsets currentInsets = self.scrollView.contentInset;
    if (self.position == AAPullToRefreshPositionTop) {
        CGFloat offset = MAX(self.scrollView.contentOffset.y * -1, 0);
        currentInsets.top = MIN(offset, self.originalInsetTop + self.bounds.size.height + 20.0f);
    } else {
        //CGFloat overBottomOffsetY = self.scrollView.contentOffset.y - self.scrollView.contentSize.height + self.scrollView.frame.size.height;
        //currentInsets.bottom = MIN(overBottomOffsetY, self.originalInsetBottom + self.bounds.size.height + 40.0);
        currentInsets.bottom = MIN(self.threshold, self.originalInsetBottom + self.bounds.size.height + 40.0f);
    }
    [self setScrollViewContentInset:currentInsets handler:handler];
}

- (void)resetScrollViewContentInset:(actionHandler)handler
{
    UIEdgeInsets currentInsets = self.scrollView.contentInset;
    if (self.position == AAPullToRefreshPositionTop) {
        currentInsets.top = self.originalInsetTop;
    } else {
        currentInsets.bottom = self.originalInsetBottom;
    }
    [self setScrollViewContentInset:currentInsets handler:handler];
}

- (void)setScrollViewContentInset:(UIEdgeInsets)contentInset handler:(actionHandler)handler
{
    [UIView animateWithDuration:0.3f
                          delay:0
                        options:UIViewAnimationOptionAllowUserInteraction |
     UIViewAnimationOptionCurveEaseOut |
     UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         self.scrollView.contentInset = contentInset;
                     }
                     completion:^(BOOL finished) {
                         if (handler)
                             handler();
                     }];
}

#pragma mark - property
- (void)setShowPullToRefresh:(BOOL)showPullToRefresh
{
    self.hidden = !showPullToRefresh;
    
    if (showPullToRefresh) {
        if (!self.isObserving) {
            [self.scrollView addObserver:self forKeyPath:@"contentOffset" options:NSKeyValueObservingOptionNew context:nil];
            [self.scrollView addObserver:self forKeyPath:@"contentSize" options:NSKeyValueObservingOptionNew context:nil];
            [self.scrollView addObserver:self forKeyPath:@"frame" options:NSKeyValueObservingOptionNew context:nil];
            self.isObserving = YES;
        }
    } else {
        if (self.isObserving) {
            [self.scrollView removeObserver:self forKeyPath:@"contentOffset"];
            [self.scrollView removeObserver:self forKeyPath:@"contentSize"];
            [self.scrollView removeObserver:self forKeyPath:@"frame"];
            self.isObserving = NO;
        }
    }
}

- (void)willMoveToSuperview:(UIView *)newSuperview
{
    if (self.superview && newSuperview == nil)
        if (self.isObserving)
            self.showPullToRefresh = NO;
}

- (BOOL)showPullToRefresh
{
    return !self.hidden;
}

- (void)setProgress:(double)progress
{
    if (progress > 1.0) {
        progress = 1.0;
        self.backgroundLayer.glow = YES;
    } else {
        self.backgroundLayer.glow = NO;
    }
    
    self.alpha = 1.0 * progress;
    
    if (progress >= 0 && progress <= 1.0f) {
        //rotation Animation
        CABasicAnimation *animationImage = [CABasicAnimation animationWithKeyPath:@"transform.rotation"];
        animationImage.fromValue = [NSNumber numberWithFloat:DEGREES_TO_RADIANS(180+180*self.prevProgress)];
        animationImage.toValue = [NSNumber numberWithFloat:DEGREES_TO_RADIANS(180+180*progress)];
        animationImage.duration = 0.1f;
        animationImage.removedOnCompletion = NO;
        animationImage.fillMode = kCAFillModeForwards;
        [self.imageLayer addAnimation:animationImage forKey:@"animation"];
        
        //strokeAnimation
        CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"strokeEnd"];
        animation.fromValue = [NSNumber numberWithFloat:((CAShapeLayer *)self.shapeLayer.presentationLayer).strokeEnd];
        animation.toValue = [NSNumber numberWithFloat:progress];
        animation.duration = 0.1f;
        animation.removedOnCompletion = NO;
        animation.fillMode = kCAFillModeForwards;
        animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
        [self.shapeLayer addAnimation:animation forKey:@"animation"];
    }
    self.prevProgress = self.progress;
    _progress = progress;
}

- (BOOL)isSidePosition
{
    return (self.position == AAPullToRefreshPositionLeft || self.position == AAPullToRefreshPositionRight);
}

#pragma mark misc.
- (void)setLayerOpacity:(CGFloat)opacity
{
    self.imageLayer.opacity = opacity;
    self.backgroundLayer.opacity = opacity;
    self.shapeLayer.opacity = opacity;
}

- (void)setLayerHidden:(BOOL)hidden
{
    self.imageLayer.hidden = hidden;
    self.shapeLayer.hidden = hidden;
    self.backgroundLayer.hidden = hidden;
}

#pragma mark - KVO
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"contentOffset"]) {
        [self scrollViewDidScroll:[[change valueForKey:NSKeyValueChangeNewKey] CGPointValue]];
    } else if ([keyPath isEqualToString:@"contentSize"]) {
        [self setNeedsLayout];
        [self setNeedsDisplay];
    } else if ([keyPath isEqualToString:@"frame"]) {
        [self setNeedsLayout];
        [self setNeedsDisplay];
    }
}

- (void)scrollViewDidScroll:(CGPoint)contentOffset
{
    CGFloat yOffset = contentOffset.y;
    CGFloat xOffset = contentOffset.x;
    CGFloat overBottomOffsetY = yOffset - self.scrollView.contentSize.height + self.scrollView.frame.size.height;
    CGFloat centerX;
    CGFloat centerY;
    switch (self.position) {
        case AAPullToRefreshPositionTop:
            self.progress = ((yOffset + self.originalInsetTop) / -self.threshold);
            centerX = self.scrollView.center.x + xOffset;
            centerY = (yOffset + self.originalInsetTop) / 2.0f;
            break;
        case AAPullToRefreshPositionBottom:
            self.progress = overBottomOffsetY / self.threshold;
            centerX = self.scrollView.center.x + xOffset;
            centerY = self.scrollView.frame.size.height + self.frame.size.height / 2.0f + yOffset;
            if (overBottomOffsetY >= 0.0f) {
                centerY -= overBottomOffsetY / 1.5f;
            }
            break;
        case AAPullToRefreshPositionLeft:
            self.progress = xOffset / -self.threshold;
            centerX = xOffset / 2.0f;
            centerY = self.scrollView.bounds.size.height / 2.0f + yOffset;
            break;
        case AAPullToRefreshPositionRight: {
            CGFloat rightEdgeOffset = self.scrollView.contentSize.width - self.scrollView.bounds.size.width;
            centerX = self.scrollView.contentSize.width + MAX((xOffset - rightEdgeOffset) / 2.0f, 0);
            centerY = self.scrollView.bounds.size.height / 2.0f + yOffset;
            self.progress = MAX((xOffset - rightEdgeOffset) / self.threshold, 0);
            break;
        }
        default:
            break;
    }
    
    self.center = CGPointMake(centerX, centerY);
    switch (self.state) {
        case AAPullToRefreshStateNormal: //detect action
            if (self.isUserAction && !self.scrollView.dragging && !self.scrollView.isZooming && self.prevProgress > 0.99f) {
                [self actionTriggeredState];
            }
            break;
        case AAPullToRefreshStateStopped: // finish
        case AAPullToRefreshStateLoading: // wait until stopIndicatorAnimation
            break;
        default:
            break;
    }
    
    self.isUserAction = (self.scrollView.dragging) ? YES : NO;
}

- (void)actionTriggeredState
{
    self.state = AAPullToRefreshStateLoading;
    
    [UIView animateWithDuration:0.1f delay:0.0f
                        options:UIViewAnimationOptionCurveEaseInOut|UIViewAnimationOptionAllowUserInteraction
                     animations:^{
                         [self setLayerOpacity:0.0f];
                     } completion:^(BOOL finished) {
                         [self setLayerHidden:YES];
                     }];
    
    [self.activityIndicatorView startAnimating];
    [self setupScrollViewContentInsetForLoadingIndicator:nil];
    if (self.pullToRefreshHandler)
        self.pullToRefreshHandler(self);
}

- (void)actionStopState
{
    [UIView animateWithDuration:0.2f
                          delay:0.0f
                        options:UIViewAnimationOptionCurveEaseInOut|UIViewAnimationOptionAllowUserInteraction
                     animations:^{
                         self.activityIndicatorView.transform = CGAffineTransformMakeScale(0.1f, 0.1f);
                     } completion:^(BOOL finished) {
                         [self.activityIndicatorView stopAnimating];
                         [self resetScrollViewContentInset:^{
                             self.activityIndicatorView.transform = CGAffineTransformIdentity;
                             [self setLayerHidden:NO];
                             [self setLayerOpacity:1.0f];
                             self.state = AAPullToRefreshStateNormal;
                         }];
                     }];
}

#pragma mark - public method
- (void)stopIndicatorAnimation
{
    [self actionStopState];
}

- (void)manuallyTriggered
{
    [self setLayerOpacity:0.0f];
    
    UIEdgeInsets currentInsets = self.scrollView.contentInset;
    currentInsets.top = self.originalInsetTop + self.bounds.size.height + 20.0f;
    [UIView animateWithDuration:0.3f delay:0.0f options:UIViewAnimationOptionCurveEaseInOut animations:^{
        self.scrollView.contentOffset = CGPointMake(self.scrollView.contentOffset.x, -currentInsets.top);
    } completion:^(BOOL finished) {
        [self actionTriggeredState];
    }];
}

- (void)setSize:(CGSize) size
{
    CGRect rect = CGRectMake((self.scrollView.bounds.size.width - size.width)/2.0f,
                             -size.height, size.width, size.height);
    
    self.frame = rect;
    self.shapeLayer.frame = self.bounds;
    self.activityIndicatorView.frame = self.bounds;
    self.imageLayer.frame = CGRectInset(self.bounds, self.borderWidth, self.borderWidth);
    
    self.backgroundLayer.frame = self.bounds;
    [self.backgroundLayer setNeedsDisplay];
}

- (void)setImageIcon:(UIImage *)imageIcon
{
    _imageIcon = imageIcon;
    _imageLayer.contents = (id)_imageIcon.CGImage;
    _imageLayer.frame = CGRectInset(self.bounds, self.borderWidth, self.borderWidth);
    
    [self setSize:_imageIcon.size];
}

- (void)setBorderWidth:(CGFloat)borderWidth
{
    _borderWidth = borderWidth;
    
    _backgroundLayer.outlineWidth = _borderWidth;
    [_backgroundLayer setNeedsDisplay];
    
    _shapeLayer.lineWidth = _borderWidth;
    _imageLayer.frame = CGRectInset(self.bounds, self.borderWidth, self.borderWidth);
}

- (void)setBorderColor:(UIColor *)borderColor
{
    _borderColor = borderColor;
    _shapeLayer.strokeColor = _borderColor.CGColor;
}

- (void)setActivityIndicatorView:(UIActivityIndicatorView *)activityIndicatorView
{
    if(_activityIndicatorView)
        [activityIndicatorView removeFromSuperview];
    _activityIndicatorView = activityIndicatorView;
    _activityIndicatorView.hidesWhenStopped = YES;
    _activityIndicatorView.frame = self.bounds;
    [self addSubview:_activityIndicatorView];
    
}

@end
