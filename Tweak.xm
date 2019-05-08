#import "BetterReachability.h"

BOOL isReachabilityEnabled = NO;
FBRootWindow *rootWindow;
CGPoint lastTranslation = CGPointZero;
BOOL isLeft = YES;
BOOL isInsideSystemGestureView = NO;
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

%property (nonatomic, retain) OverlayView *panningView;
%property (nonatomic, retain) OverlayView *slidingView;
%property (nonatomic, retain) UIImageView *wallpaperImageView;
%property (nonatomic, retain) UIVisualEffectView *scaleIndicator;
%property (nonatomic, retain) UILabel *indicatorLabel;
%property (nonatomic, assign) NSInteger backgroundMode;
%property (nonatomic, retain) UIImage *selectedImage;

-(id)init {
    SBReachabilityManager *original = %orig;

    if (original) {
        NSDictionary *dict = [[[NSDictionary alloc] initWithContentsOfFile:@"/var/mobile/Library/Preferences/com.shiftcmdk.betterreachabilitypreferences.image.plist"] autorelease];

        NSData *imageData = [dict objectForKey:@"image"];

        if (imageData) {
            original.selectedImage = [UIImage imageWithData:imageData];
        } else {
            original.selectedImage = nil;
        }
    }

    return original;
}

-(void)addObserver:(id)arg1 {
    NSString *className = NSStringFromClass([arg1 class]);

    if ([className isEqual:@"SBControlCenterController"] || [className isEqual:@"SBCoverSheetPrimarySlidingViewController"]) {
        %orig;
    }
}

%new
-(void)setBackground:(BOOL)animated {
    if (!self.wallpaperImageView) {
        CGRect bounds = [UIScreen mainScreen].fixedCoordinateSpace.bounds;

        self.wallpaperImageView = [[[UIImageView alloc] initWithFrame:bounds] autorelease];
        self.wallpaperImageView.contentMode = UIViewContentModeScaleAspectFill;
    }

    if (rootWindow && !self.wallpaperImageView.superview) {
        [rootWindow insertSubview:self.wallpaperImageView atIndex:1];
    }

    NSUserDefaults *defaults = [[[NSUserDefaults alloc] initWithSuiteName:@"com.shiftcmdk.betterreachabilitypreferences"] autorelease];

    switch (self.backgroundMode) {
        case 1: {
            id customColor = [defaults objectForKey:@"customcolor"];

            UIColor *selectedColor;

	        if ([customColor isKindOfClass:[NSArray class]] && [customColor count] >= 3) {
                selectedColor = [UIColor colorWithRed:[customColor[0] floatValue] green:[customColor[1] floatValue] blue:[customColor[2] floatValue] alpha:1.0];
            } else {
                selectedColor = [UIColor blackColor];
            }

            if (animated) {
                [UIView transitionWithView:self.wallpaperImageView duration:0.3 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
                    self.wallpaperImageView.image = nil;
                    self.wallpaperImageView.backgroundColor = selectedColor;
                } completion:nil];
            } else {
                self.wallpaperImageView.image = nil;
                self.wallpaperImageView.backgroundColor = selectedColor;
            }
            break;
        }
        case 2: {
            if (animated) {
                [UIView transitionWithView:self.wallpaperImageView duration:0.3 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
                    self.wallpaperImageView.image = self.selectedImage;
                    self.wallpaperImageView.backgroundColor = [UIColor clearColor];
                } completion:nil];
            } else {
                self.wallpaperImageView.image = self.selectedImage;
                self.wallpaperImageView.backgroundColor = [UIColor clearColor];
            }
            break;
        }
        default:
            SBWallpaperController *wallpaperController = [%c(SBWallpaperController) sharedInstance];

            [self setWallpaper:wallpaperController duration:0.3];

            break;
    }
}

%new
-(void)setWallpaper:(id)controller duration:(NSTimeInterval)duration {
    SBWallpaperController *ctrl = controller;
    UIImage *image;

    id wallpaperView = [ctrl _wallpaperViewForVariant:1];

    if ([wallpaperView isKindOfClass:[%c(SBFProceduralWallpaperView) class]]) {
        SBFProceduralWallpaperView *theWallpaperView = wallpaperView;

        image = [theWallpaperView _blurredImage];
    } else {
        image = [ctrl homescreenLightForegroundBlurImage];
    }

    if (self.wallpaperImageView.superview) {
        [UIView transitionWithView:self.wallpaperImageView duration:duration options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
            self.wallpaperImageView.image = image;
        } completion:nil];
    } else {
        self.wallpaperImageView.image = image;
    }
}

%new
-(void)pan:(UIPanGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateBegan) {
        lastTranslation = CGPointZero;
    }

    if (!self.scaleIndicator.effect) {
        self.scaleIndicator.effect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
        self.indicatorLabel.alpha = 1.0;
    }

    CGFloat currentFactor = [rootWindow sceneContainerView].transform.a;

    CGPoint currentTranslation = [sender translationInView:self.panningView];

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

    self.panningView.frame = CGRectMake(
        self.panningView.frame.origin.x, 
        self.panningView.frame.origin.y,
        self.panningView.frame.size.width,
        bounds.size.height * (1.0 - newScaleClamped)
    );

    self.slidingView.frame = CGRectMake(
        isLeft ? bounds.size.width - bounds.size.width * (1.0 - newScaleClamped) : 0.0,
        bounds.size.height * (1.0 - newScaleClamped),
        bounds.size.width * (1.0 - newScaleClamped),
        scaledHeight
    );

    self.scaleIndicator.frame = CGRectMake(
        isLeft ? bounds.size.width * newScaleClamped + scaleIndicatorPadding : bounds.size.width * (1.0 - newScaleClamped) - scaleIndicatorSize.width - scaleIndicatorPadding,
        bounds.size.height * (1.0 - newScaleClamped) - scaleIndicatorSize.height - scaleIndicatorPadding,
        scaleIndicatorSize.width,
        scaleIndicatorSize.height
    );

    self.indicatorLabel.text = [NSString stringWithFormat:@"%.f %%", newScaleClamped * 100.0];

    if (sender.state == UIGestureRecognizerStateEnded || sender.state == UIGestureRecognizerStateCancelled) {
        NSUserDefaults *defaults = [[[NSUserDefaults alloc] initWithSuiteName:@"com.shiftcmdk.betterreachabilitypreferences"] autorelease];

        [defaults setObject:[NSNumber numberWithFloat:newScaleClamped] forKey:@"lastscale"];

        [self fadeScaleIndicatorDelayed];
    }
}

%new
-(void)fadeScaleIndicatorDelayed {
    if (self.scaleIndicator) {
        [UIView animateWithDuration:0.5 delay:1.5 options:UIViewAnimationCurveLinear animations:^{
            self.scaleIndicator.effect = nil;
            self.indicatorLabel.alpha = 0.0;
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

        self.scaleIndicator.frame = CGRectMake(
            isLeft ? bounds.size.width * currentScale + scaleIndicatorPadding : bounds.size.width * (1.0 - currentScale) - scaleIndicatorSize.width - scaleIndicatorPadding,
            bounds.size.height * (1.0 - currentScale) - scaleIndicatorSize.height - scaleIndicatorPadding,
            scaleIndicatorSize.width,
            scaleIndicatorSize.height
        );
    } completion: ^(BOOL finished) {
        self.slidingView.frame = CGRectMake(
            isLeft ? bounds.size.width - self.slidingView.frame.size.width : 0.0,
            self.slidingView.frame.origin.y,
            self.slidingView.frame.size.width,
            self.slidingView.frame.size.height
        );

        [self fadeScaleIndicatorDelayed];
    }];
}

%new
-(void)swipeLeft:(UISwipeGestureRecognizer *)sender {
    isLeft = YES;

    self.scaleIndicator.effect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
    self.indicatorLabel.alpha = 1.0;

    NSUserDefaults *defaults = [[[NSUserDefaults alloc] initWithSuiteName:@"com.shiftcmdk.betterreachabilitypreferences"] autorelease];

    [defaults setObject:@0 forKey:@"lastposition"];

    [self swipe];
}

%new
-(void)swipeRight:(UISwipeGestureRecognizer *)sender {
    isLeft = NO;

    self.scaleIndicator.effect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
    self.indicatorLabel.alpha = 1.0;

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

        if (!self.panningView) {
            self.panningView = [[[OverlayView alloc] initWithFrame:CGRectMake(
                0.0,
                0.0,
                bounds.size.width,
                0.0
            )] autorelease];
            self.panningView.alpha = 0.5;

            UIPanGestureRecognizer *pan = [[[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(pan:)] autorelease];

            [self.panningView addGestureRecognizer:pan];

            UITapGestureRecognizer *doubleTap = [[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doubleTap:)] autorelease];
            doubleTap.numberOfTapsRequired = 2; 

            [self.panningView addGestureRecognizer:doubleTap];

            [rootWindow addSubview:self.panningView];
        }

        if (!self.scaleIndicator) {
            UIVisualEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];

            self.scaleIndicator = [[[UIVisualEffectView alloc] initWithEffect:blurEffect] autorelease];
            self.scaleIndicator.clipsToBounds = YES;
            self.scaleIndicator.layer.cornerRadius = 8.0;

            [rootWindow insertSubview:self.scaleIndicator aboveSubview:self.panningView];

            self.indicatorLabel = [[[UILabel alloc] init] autorelease];
            self.indicatorLabel.textAlignment = NSTextAlignmentCenter;
            self.indicatorLabel.font = [UIFont systemFontOfSize:14.0];

            [self.scaleIndicator.contentView addSubview:self.indicatorLabel];

            self.scaleIndicator.userInteractionEnabled = NO;
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

        self.scaleIndicator.hidden = !showScaleIndicator;

        if (!self.slidingView) {
            self.slidingView = [[[OverlayView alloc] initWithFrame:CGRectMake(
                isLeft ? bounds.size.width - bounds.size.width * (1.0 - initialScale) : 0.0,
                bounds.size.height,
                bounds.size.width * (1.0 - initialScale),
                0.0
            )] autorelease];
            self.slidingView.alpha = 0.5;

            [rootWindow insertSubview:self.slidingView atIndex:0];

            UISwipeGestureRecognizer *leftSwipe = [[[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeLeft:)] autorelease];
            leftSwipe.direction = UISwipeGestureRecognizerDirectionLeft;
            
            [self.slidingView addGestureRecognizer:leftSwipe];

            UISwipeGestureRecognizer *rightSwipe = [[[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeRight:)] autorelease];
            rightSwipe.direction = UISwipeGestureRecognizerDirectionRight;
            
            [self.slidingView addGestureRecognizer:rightSwipe];
        }

        self.backgroundMode = [[defaults objectForKey:@"background"] intValue];

        [self setBackground:NO];

        NSTimeInterval reachabilityAnimationDuration = 0.3;

        if (isReachabilityEnabled) {
            self.scaleIndicator.frame = CGRectMake(
                isLeft ? bounds.size.width + scaleIndicatorPadding : -scaleIndicatorSize.width - scaleIndicatorPadding,
                -scaleIndicatorSize.height - scaleIndicatorPadding,
                scaleIndicatorSize.width,
                scaleIndicatorSize.height
            );

            if (!self.scaleIndicator.effect) {
                self.scaleIndicator.effect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
                self.indicatorLabel.alpha = 1.0;
            }

            self.indicatorLabel.frame = self.scaleIndicator.bounds;

            self.indicatorLabel.text = [NSString stringWithFormat:@"%.f %%", initialScale * 100.0];

            [UIView animateWithDuration:reachabilityAnimationDuration animations:^{
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

                self.panningView.frame = CGRectMake(
                    0.0,
                    0.0,
                    bounds.size.width,
                    bounds.size.height * (1.0 - initialScale)
                );

                self.slidingView.frame = CGRectMake(
                    isLeft ? bounds.size.width - bounds.size.width * (1.0 - initialScale) : 0.0,
                    bounds.size.height * (1.0 - initialScale),
                    bounds.size.width * (1.0 - initialScale),
                    bounds.size.height - bounds.size.height * (1.0 - initialScale)
                );

                self.scaleIndicator.frame = CGRectMake(
                    isLeft ? bounds.size.width * initialScale + scaleIndicatorPadding : bounds.size.width * (1.0 - initialScale) - scaleIndicatorSize.width - scaleIndicatorPadding,
                    bounds.size.height * (1.0 - initialScale) - scaleIndicatorSize.height - scaleIndicatorPadding,
                    scaleIndicatorSize.width,
                    scaleIndicatorSize.height
                );
            } completion: ^(BOOL finished) {
                [self fadeScaleIndicatorDelayed];
            }];
        } else {
            [UIView animateWithDuration:reachabilityAnimationDuration animations:^{
                [rootWindow sceneContainerView].center = CGPointMake(bounds.size.width / 2.0, bounds.size.height / 2.0);
                [rootWindow _systemGestureView].center = CGPointMake(bounds.size.width / 2.0, bounds.size.height / 2.0);

                [rootWindow sceneContainerView].transform = CGAffineTransformIdentity;
                [rootWindow _systemGestureView].transform = CGAffineTransformIdentity;

                self.panningView.frame = CGRectMake(
                    0.0,
                    0.0,
                    bounds.size.width,
                    0.0
                );

                self.slidingView.frame = CGRectMake(
                    bounds.size.width - bounds.size.width * 0.25,
                    bounds.size.height,
                    bounds.size.width * 0.25,
                    0.0
                );

                self.scaleIndicator.frame = CGRectMake(
                    isLeft ? bounds.size.width + scaleIndicatorPadding : -scaleIndicatorSize.width - scaleIndicatorPadding,
                    -scaleIndicatorSize.height - scaleIndicatorPadding,
                    scaleIndicatorSize.width,
                    scaleIndicatorSize.height
                );
                self.scaleIndicator.effect = nil;
                self.indicatorLabel.alpha = 0.0;
            } completion: ^(BOOL finished) {
                if (!isReachabilityEnabled) {
                    [self.panningView removeFromSuperview];
                    self.panningView = nil;

                    [self.slidingView removeFromSuperview];
                    self.slidingView = nil;

                    [self.wallpaperImageView removeFromSuperview];
                    self.wallpaperImageView = nil;

                    [self.indicatorLabel removeFromSuperview];
                    self.indicatorLabel = nil;

                    [self.scaleIndicator removeFromSuperview];
                    self.scaleIndicator = nil;
                }
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

    NSUserDefaults *defaults = [[[NSUserDefaults alloc] initWithSuiteName:@"com.shiftcmdk.betterreachabilitypreferences"] autorelease];

    if (arg1 == 1 && [[defaults objectForKey:@"background"] intValue] == 0) {
        [[%c(SBReachabilityManager) sharedInstance] setWallpaper:self duration:1.0];
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
    if ([(NSString *)name isEqual:@"com.shiftcmdk.betterreachabilitypreferences.scaleindicator"]) {
        if ([[%c(SBReachabilityManager) sharedInstance] scaleIndicator]) {
            NSUserDefaults *defaults = [[[NSUserDefaults alloc] initWithSuiteName:@"com.shiftcmdk.betterreachabilitypreferences"] autorelease];

            BOOL showScaleIndicator = [defaults objectForKey:@"scaleindicator"] == nil || [[defaults objectForKey:@"scaleindicator"] boolValue];

            [[%c(SBReachabilityManager) sharedInstance] scaleIndicator].hidden = !showScaleIndicator;
        }
    } else if ([(NSString *)name isEqual:@"com.shiftcmdk.betterreachabilitypreferences.background"]) {
        SBReachabilityManager *manager = [%c(SBReachabilityManager) sharedInstance];

        NSUserDefaults *defaults = [[[NSUserDefaults alloc] initWithSuiteName:@"com.shiftcmdk.betterreachabilitypreferences"] autorelease];

        int lastBackgroundMode = [manager backgroundMode];
        int newBackgroundMode = [[defaults objectForKey:@"background"] intValue];

        manager.backgroundMode = newBackgroundMode;

        if (newBackgroundMode == 2) {
            NSDictionary *dict = [[[NSDictionary alloc] initWithContentsOfFile:@"/var/mobile/Library/Preferences/com.shiftcmdk.betterreachabilitypreferences.image.plist"] autorelease];

            NSData *imageData = [dict objectForKey:@"image"];

            if (imageData) {
                manager.selectedImage = [UIImage imageWithData:imageData];
            } else {
                manager.selectedImage = nil;
            }
        }

        if (isReachabilityEnabled) {
            if (newBackgroundMode == 2 && lastBackgroundMode == 2) {
                [manager setBackground:YES];
            } else {
                [manager setBackground:lastBackgroundMode != newBackgroundMode];
            }
        }
    }
}

static void *observer = NULL;

%ctor {
    NSString *path = @"/var/mobile/Library/Preferences/com.shiftcmdk.betterreachabilitypreferences.image.plist";

    if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
        [[NSDictionary dictionary] writeToFile:path atomically:YES];
    }

    CFNotificationCenterAddObserver(
        CFNotificationCenterGetDarwinNotifyCenter(),
        &observer,
        notificationCallback,
        (CFStringRef)@"com.shiftcmdk.betterreachabilitypreferences.scaleindicator",
        NULL,
        CFNotificationSuspensionBehaviorDeliverImmediately
    );

    CFNotificationCenterAddObserver(
        CFNotificationCenterGetDarwinNotifyCenter(),
        &observer,
        notificationCallback,
        (CFStringRef)@"com.shiftcmdk.betterreachabilitypreferences.background",
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

    CFNotificationCenterRemoveObserver(
        CFNotificationCenterGetDarwinNotifyCenter(),
        &observer,
        (CFStringRef)@"com.shiftcmdk.betterreachabilitypreferences.background",
        NULL
    );
}
