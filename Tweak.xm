#import "BetterReachability.h"

BOOL isReachabilityEnabled = NO;
FBRootWindow *rootWindow;
OverlayView *panningView;
CGPoint lastTranslation = CGPointZero;
BOOL isLeft = YES;
OverlayView *slidingView;
UIImageView *wallpaperImageView;
BOOL isInsideSystemGestureView = NO;
UIVisualEffectView *scaleIndicator;
UILabel *indicatorLabel;
CGSize scaleIndicatorSize = CGSizeMake(50.0, 26.0);
CGFloat scaleIndicatorPadding = 4.0;

@implementation OverlayView

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
    if (isInsideSystemGestureView) {
        return NO;
    }

    return [super pointInside:point withEvent:event];
}

@end

%hook SBReachabilityManager

-(void)addObserver:(id)arg1 {
    NSString *className = NSStringFromClass([arg1 class]);

    if ([className isEqual:@"SBControlCenterController"] || [className isEqual:@"SBCoverSheetPrimarySlidingViewController"]) {
        %orig;
    }
}

%new
-(void)setWallpaper:(id)controller {
    if (!wallpaperImageView) {
        CGRect bounds = [UIScreen mainScreen].fixedCoordinateSpace.bounds;

        wallpaperImageView = [[UIImageView alloc] initWithFrame:bounds];
        wallpaperImageView.contentMode = UIViewContentModeScaleAspectFill;
    }

    if (rootWindow && !wallpaperImageView.superview) {
        [rootWindow insertSubview:wallpaperImageView atIndex:1];
    }

    SBWallpaperController *ctrl = controller;
    UIImage *image;

    id wallpaperView = [ctrl _wallpaperViewForVariant:1];

    if ([wallpaperView isKindOfClass:[%c(SBFProceduralWallpaperView) class]]) {
        SBFProceduralWallpaperView *theWallpaperView = wallpaperView;

        image = [theWallpaperView _blurredImage];
    } else {
        image = [ctrl homescreenLightForegroundBlurImage];
    }

    if (wallpaperImageView.superview) {
        [UIView transitionWithView:wallpaperImageView duration:1.0 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
            wallpaperImageView.image = image;
        } completion:nil];
    } else {
        wallpaperImageView.image = image;
    }
}

%new
-(void)pan:(UIPanGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateBegan) {
        lastTranslation = CGPointZero;
    }

    if (!scaleIndicator.effect) {
        scaleIndicator.effect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
        indicatorLabel.alpha = 1.0;
    }

    CGFloat currentFactor = [rootWindow sceneContainerView].transform.a;

    CGPoint currentTranslation = [sender translationInView:panningView];

    CGFloat distance = hypotf(lastTranslation.x - currentTranslation.x, lastTranslation.y - currentTranslation.y);

    if (currentTranslation.y < lastTranslation.y) {
        distance = -distance;
    }

    CGRect bounds = [UIScreen mainScreen].fixedCoordinateSpace.bounds;

    CGFloat newScaleFactor = ((distance / 2.0) * currentFactor) / (bounds.size.width * currentFactor);

    lastTranslation = currentTranslation;

    CGFloat newScale = currentFactor - newScaleFactor;

    CGFloat newScaleClamped = fmin(0.75, fmax(0.5, newScale));

    CGAffineTransform newTransform = CGAffineTransformMakeScale(newScaleClamped, newScaleClamped);

    CGFloat scaledHeight = bounds.size.height * newScaleClamped;
    CGFloat scaledWidth = bounds.size.width * newScaleClamped;

    CGFloat centerX = isLeft ? scaledWidth / 2.0 : bounds.size.width - scaledWidth / 2.0;
    CGFloat centerY = bounds.size.height - scaledHeight + scaledHeight / 2.0;

    [rootWindow sceneContainerView].center = CGPointMake(centerX, centerY);
    [rootWindow _systemGestureView].center = CGPointMake(centerX, centerY);

    [rootWindow sceneContainerView].transform = newTransform;
    [rootWindow _systemGestureView].transform = newTransform;

    panningView.frame = CGRectMake(
        panningView.frame.origin.x, 
        panningView.frame.origin.y,
        panningView.frame.size.width,
        bounds.size.height * (1.0 - newScaleClamped)
    );

    slidingView.frame = CGRectMake(
        isLeft ? bounds.size.width - bounds.size.width * (1.0 - newScaleClamped) : 0.0,
        bounds.size.height * (1.0 - newScaleClamped),
        bounds.size.width * (1.0 - newScaleClamped),
        scaledHeight
    );

    scaleIndicator.frame = CGRectMake(
        isLeft ? bounds.size.width * newScaleClamped + scaleIndicatorPadding : bounds.size.width * (1.0 - newScaleClamped) - scaleIndicatorSize.width - scaleIndicatorPadding,
        bounds.size.height * (1.0 - newScaleClamped) - scaleIndicatorSize.height - scaleIndicatorPadding,
        scaleIndicatorSize.width,
        scaleIndicatorSize.height
    );

    indicatorLabel.text = [NSString stringWithFormat:@"%.f %%", newScaleClamped * 100.0];

    if (sender.state == UIGestureRecognizerStateEnded || sender.state == UIGestureRecognizerStateCancelled) {
        NSUserDefaults *defaults = [[[NSUserDefaults alloc] initWithSuiteName:@"com.shiftcmdk.betterreachabilitypreferences"] autorelease];

        [defaults setObject:[NSNumber numberWithFloat:newScaleClamped] forKey:@"lastscale"];

        [self fadeScaleIndicatorDelayed];
    }
}

%new
-(void)fadeScaleIndicatorDelayed {
    if (scaleIndicator) {
        [UIView animateWithDuration:0.5 delay:1.5 options:UIViewAnimationCurveLinear animations:^{
            scaleIndicator.effect = nil;
            indicatorLabel.alpha = 0.0;
        } completion:^(BOOL finished) {

        }];
    }
}

%new
-(void)swipe {
    CGRect bounds = [UIScreen mainScreen].fixedCoordinateSpace.bounds;

    CGPoint currentCenter = [rootWindow sceneContainerView].center;
    CGFloat currentScale = [rootWindow sceneContainerView].transform.a;

    CGFloat scaledWidth = bounds.size.width * currentScale;

    CGPoint center = CGPointMake(
        isLeft ? scaledWidth / 2.0 : bounds.size.width - scaledWidth / 2.0,
        currentCenter.y
    );

    [UIView animateWithDuration:0.3 animations:^{
        [rootWindow sceneContainerView].center = center;
        [rootWindow _systemGestureView].center = center;

        scaleIndicator.frame = CGRectMake(
            isLeft ? bounds.size.width * currentScale + scaleIndicatorPadding : bounds.size.width * (1.0 - currentScale) - scaleIndicatorSize.width - scaleIndicatorPadding,
            bounds.size.height * (1.0 - currentScale) - scaleIndicatorSize.height - scaleIndicatorPadding,
            scaleIndicatorSize.width,
            scaleIndicatorSize.height
        );
    } completion: ^(BOOL finished) {
        slidingView.frame = CGRectMake(
            isLeft ? bounds.size.width - slidingView.frame.size.width : 0.0,
            slidingView.frame.origin.y,
            slidingView.frame.size.width,
            slidingView.frame.size.height
        );

        [self fadeScaleIndicatorDelayed];
    }];
}

%new
-(void)swipeLeft:(UISwipeGestureRecognizer *)sender {
    isLeft = YES;

    scaleIndicator.effect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
    indicatorLabel.alpha = 1.0;

    NSUserDefaults *defaults = [[[NSUserDefaults alloc] initWithSuiteName:@"com.shiftcmdk.betterreachabilitypreferences"] autorelease];

    [defaults setObject:@0 forKey:@"lastposition"];

    [self swipe];
}

%new
-(void)swipeRight:(UISwipeGestureRecognizer *)sender {
    isLeft = NO;

    scaleIndicator.effect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
    indicatorLabel.alpha = 1.0;

    NSUserDefaults *defaults = [[[NSUserDefaults alloc] initWithSuiteName:@"com.shiftcmdk.betterreachabilitypreferences"] autorelease];

    [defaults setObject:@1 forKey:@"lastposition"];

    [self swipe];
}

%new
-(void)doubleTap:(UITapGestureRecognizer *)sender {
    [[%c(SBReachabilityManager) sharedInstance] toggleReachability];
}

-(void)toggleReachability {
    isReachabilityEnabled = !isReachabilityEnabled;

    if (!rootWindow) {
        for (UIWindow *window in [UIApplication sharedApplication].windows) {
            if ([window isKindOfClass:[%c(FBRootWindow) class]]) {
                rootWindow = (FBRootWindow *)window;
                break;
            }
        }
    }

    if (rootWindow) {
        CGRect bounds = [UIScreen mainScreen].fixedCoordinateSpace.bounds;

        if (!panningView) {
            panningView = [[OverlayView alloc] initWithFrame:CGRectMake(
                0.0,
                0.0,
                bounds.size.width,
                0.0
            )];
            panningView.alpha = 0.5;

            UIPanGestureRecognizer *pan = [[[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(pan:)] autorelease];

            [panningView addGestureRecognizer:pan];

            UITapGestureRecognizer *doubleTap = [[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doubleTap:)] autorelease];
            doubleTap.numberOfTapsRequired = 2; 

            [panningView addGestureRecognizer:doubleTap];

            [rootWindow addSubview:panningView];
        }

        if (!scaleIndicator) {
            UIVisualEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];

            scaleIndicator = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
            scaleIndicator.clipsToBounds = YES;
            scaleIndicator.layer.cornerRadius = 8.0;

            [rootWindow insertSubview:scaleIndicator aboveSubview:panningView];

            indicatorLabel = [[[UILabel alloc] init] autorelease];
            indicatorLabel.textAlignment = NSTextAlignmentCenter;
            indicatorLabel.font = [UIFont systemFontOfSize:14.0];

            [scaleIndicator.contentView addSubview:indicatorLabel];

            scaleIndicator.userInteractionEnabled = NO;
        }

        NSUserDefaults *defaults = [[[NSUserDefaults alloc] initWithSuiteName:@"com.shiftcmdk.betterreachabilitypreferences"] autorelease];

        id initialPosition = [defaults objectForKey:@"initialposition"];

        id lastPosition = [defaults objectForKey:@"lastposition"];

        BOOL isLastPositionLeft = lastPosition == nil || [lastPosition intValue] == 0;

        if (initialPosition != nil) {
            if ([initialPosition intValue] == 0) {
                isLeft = YES;
            } else if ([initialPosition intValue] == 1) {
                isLeft = NO;
            } else {
                isLeft = isLastPositionLeft;
            }
        } else {
            isLeft = isLastPositionLeft;
        }

        CGFloat initialScale;

        if ([defaults objectForKey:@"initialscale"] == nil || [[defaults objectForKey:@"initialscale"] intValue] == 0) {
            initialScale = 0.75;

            [defaults setObject:[NSNumber numberWithFloat:0.75] forKey:@"lastscale"];
        } else {
            if ([defaults objectForKey:@"lastscale"] == nil) {
                initialScale = 0.75;
            } else {
                initialScale = fmin(0.75, fmax(0.5, [[defaults objectForKey:@"lastscale"] floatValue]));
            }
        }

        BOOL showScaleIndicator = [defaults objectForKey:@"scaleindicator"] == nil || [[defaults objectForKey:@"scaleindicator"] boolValue];

        scaleIndicator.hidden = !showScaleIndicator;

        if (!slidingView) {
            slidingView = [[OverlayView alloc] initWithFrame:CGRectMake(
                isLeft ? bounds.size.width - bounds.size.width * (1.0 - initialScale) : 0.0,
                bounds.size.height,
                bounds.size.width * (1.0 - initialScale),
                0.0
            )];
            slidingView.alpha = 0.5;

            [rootWindow insertSubview:slidingView atIndex:0];

            UISwipeGestureRecognizer *leftSwipe = [[[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeLeft:)] autorelease];
            leftSwipe.direction = UISwipeGestureRecognizerDirectionLeft;
            
            [slidingView addGestureRecognizer:leftSwipe];

            UISwipeGestureRecognizer *rightSwipe = [[[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeRight:)] autorelease];
            rightSwipe.direction = UISwipeGestureRecognizerDirectionRight;
            
            [slidingView addGestureRecognizer:rightSwipe];
        }

        if (!wallpaperImageView.superview) {
            [rootWindow insertSubview:wallpaperImageView atIndex:0];
        }

        if (isReachabilityEnabled) {
            scaleIndicator.frame = CGRectMake(
                isLeft ? bounds.size.width + scaleIndicatorPadding : -scaleIndicatorSize.width - scaleIndicatorPadding,
                -scaleIndicatorSize.height - scaleIndicatorPadding,
                scaleIndicatorSize.width,
                scaleIndicatorSize.height
            );

            if (!scaleIndicator.effect) {
                scaleIndicator.effect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
                indicatorLabel.alpha = 1.0;
            }

            indicatorLabel.frame = scaleIndicator.bounds;

            indicatorLabel.text = [NSString stringWithFormat:@"%.f %%", initialScale * 100.0];

            [UIView animateWithDuration:0.3 animations:^{
                CGAffineTransform scale = CGAffineTransformMakeScale(initialScale, initialScale);
                CGFloat scaledHeight = bounds.size.height * initialScale;
                CGFloat scaledWidth = bounds.size.width * initialScale;

                CGPoint center = CGPointMake(
                    isLeft ? scaledWidth / 2.0 : bounds.size.width - scaledWidth / 2.0, 
                    bounds.size.height - scaledHeight + scaledHeight / 2.0
                );

                [rootWindow sceneContainerView].center = center;
                [rootWindow _systemGestureView].center = center;

                [rootWindow sceneContainerView].transform = scale;
                [rootWindow _systemGestureView].transform = scale;

                panningView.frame = CGRectMake(
                    0.0,
                    0.0,
                    bounds.size.width,
                    bounds.size.height * (1.0 - initialScale)
                );

                slidingView.frame = CGRectMake(
                    isLeft ? bounds.size.width - bounds.size.width * (1.0 - initialScale) : 0.0,
                    bounds.size.height * (1.0 - initialScale),
                    bounds.size.width * (1.0 - initialScale),
                    bounds.size.height - bounds.size.height * (1.0 - initialScale)
                );

                scaleIndicator.frame = CGRectMake(
                    isLeft ? bounds.size.width * initialScale + scaleIndicatorPadding : bounds.size.width * (1.0 - initialScale) - scaleIndicatorSize.width - scaleIndicatorPadding,
                    bounds.size.height * (1.0 - initialScale) - scaleIndicatorSize.height - scaleIndicatorPadding,
                    scaleIndicatorSize.width,
                    scaleIndicatorSize.height
                );
            } completion: ^(BOOL finished) {
                [self fadeScaleIndicatorDelayed];
            }];
        } else {
            [UIView animateWithDuration:0.3 animations:^{
                [rootWindow sceneContainerView].center = CGPointMake(bounds.size.width / 2.0, bounds.size.height / 2.0);
                [rootWindow _systemGestureView].center = CGPointMake(bounds.size.width / 2.0, bounds.size.height / 2.0);

                [rootWindow sceneContainerView].transform = CGAffineTransformIdentity;
                [rootWindow _systemGestureView].transform = CGAffineTransformIdentity;

                panningView.frame = CGRectMake(
                    0.0,
                    0.0,
                    bounds.size.width,
                    0.0
                );

                slidingView.frame = CGRectMake(
                    bounds.size.width - bounds.size.width * 0.25,
                    bounds.size.height,
                    bounds.size.width * 0.25,
                    0.0
                );

                scaleIndicator.frame = CGRectMake(
                    isLeft ? bounds.size.width + scaleIndicatorPadding : -scaleIndicatorSize.width - scaleIndicatorPadding,
                    -scaleIndicatorSize.height - scaleIndicatorPadding,
                    scaleIndicatorSize.width,
                    scaleIndicatorSize.height
                );
                scaleIndicator.effect = nil;
                indicatorLabel.alpha = 0.0;
            } completion: ^(BOOL finished) {

            }];
        }
    }
}

%end

%hook SBReachabilitySettings

-(double)reachabilityInteractiveKeepAlive {
    return INFINITY;
}
-(double)reachabilityDefaultKeepAlive {
    return INFINITY;
}

%end

%hook SBWallpaperController

-(void)_handleWallpaperChangedForVariant:(long long)arg1 {
    %orig;

    if (arg1 == 1) {
        [[%c(SBReachabilityManager) sharedInstance] setWallpaper:self];
    }
}

%end

@interface FBSystemGestureView: UIView
@end

%hook FBSystemGestureView

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
    BOOL isInside = %orig;

    isInsideSystemGestureView = isInside;

    return isInside;
}

%end

static void notificationCallback(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
    if (scaleIndicator) {
        NSUserDefaults *defaults = [[[NSUserDefaults alloc] initWithSuiteName:@"com.shiftcmdk.betterreachabilitypreferences"] autorelease];

        BOOL showScaleIndicator = [defaults objectForKey:@"scaleindicator"] == nil || [[defaults objectForKey:@"scaleindicator"] boolValue];

        scaleIndicator.hidden = !showScaleIndicator;
    }
}

static void *observer = NULL;

%ctor {
    CFNotificationCenterAddObserver(
        CFNotificationCenterGetDarwinNotifyCenter(),
        &observer,
        notificationCallback,
        (CFStringRef)@"com.shiftcmdk.betterreachabilitypreferences.scaleindicator",
        NULL,
        CFNotificationSuspensionBehaviorDeliverImmediately
    );
}

%dtor {
    CFNotificationCenterRemoveObserver(
        CFNotificationCenterGetDarwinNotifyCenter(),
        &observer,
        (CFStringRef)@"com.shiftcmdk.betterreachabilitypreferences.scaleindicator",
        NULL
    );
}
