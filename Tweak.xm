#import "BetterReachability.h"

BOOL isReachabilityEnabled = NO;
FBRootWindow *rootWindow;
OverlayView *panningView;
CGPoint lastTranslation = CGPointZero;
BOOL isLeft = YES;
OverlayView *slidingView;
UIImageView *wallpaperImageView;
BOOL isInsideSystemGestureView = NO;

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
    } completion: ^(BOOL finished) {
        slidingView.frame = CGRectMake(
            isLeft ? bounds.size.width - slidingView.frame.size.width : 0.0,
            slidingView.frame.origin.y,
            slidingView.frame.size.width,
            slidingView.frame.size.height
        );
    }];
}

%new
-(void)swipeLeft:(UISwipeGestureRecognizer *)sender {
    isLeft = YES;

    [self swipe];
}

%new
-(void)swipeRight:(UISwipeGestureRecognizer *)sender {
    isLeft = NO;

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

        if (!slidingView) {
            slidingView = [[OverlayView alloc] initWithFrame:CGRectMake(
                bounds.size.width - bounds.size.width * 0.25,
                bounds.size.height,
                bounds.size.width * 0.25,
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

        isLeft = YES;

        if (isReachabilityEnabled) {
            [UIView animateWithDuration:0.3 animations:^{
                CGAffineTransform scale = CGAffineTransformMakeScale(0.75, 0.75);
                CGFloat scaledHeight = bounds.size.height * 0.75;
                CGFloat scaledWidth = bounds.size.width * 0.75;

                [rootWindow sceneContainerView].center = CGPointMake(scaledWidth / 2.0, bounds.size.height - scaledHeight + scaledHeight / 2.0);
                [rootWindow _systemGestureView].center = CGPointMake(scaledWidth / 2.0, bounds.size.height - scaledHeight + scaledHeight / 2.0);

                [rootWindow sceneContainerView].transform = scale;
                [rootWindow _systemGestureView].transform = scale;

                panningView.frame = CGRectMake(
                    0.0,
                    0.0,
                    bounds.size.width,
                    bounds.size.height * 0.25
                );

                slidingView.frame = CGRectMake(
                    bounds.size.width - bounds.size.width * 0.25,
                    bounds.size.height * 0.25,
                    bounds.size.width * 0.25,
                    bounds.size.height - bounds.size.height * 0.25
                );
            } completion: ^(BOOL finished) {
                
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
