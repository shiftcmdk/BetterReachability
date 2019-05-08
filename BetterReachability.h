@interface OverlayView: UIView
@end

@interface SBCoverSheetSlidingViewController
-(void)_dismissCoverSheetAnimated:(BOOL)arg1 withCompletion:(id)arg2;
-(void)_presentCoverSheetAnimated:(BOOL)arg1 withCompletion:(id)arg2;
@end

@interface SBCoverSheetPresentationManager
@property(retain, nonatomic) SBCoverSheetSlidingViewController *coverSheetSlidingViewController;
@property(retain, nonatomic) SBCoverSheetSlidingViewController *secureAppSlidingViewController;
+(id)sharedInstance;
-(BOOL)isVisible;
-(BOOL)isInSecureApp;
@end

@interface SBControlCenterController: NSObject

+(id)sharedInstance;
-(void)presentAnimated:(BOOL)arg1;

@end

@interface VolumeControl : NSObject

+(id)sharedVolumeControl;
-(void)_changeVolumeBy:(float)arg1;
-(float)volumeStepUp;
-(float)volumeStepDown;

@end

@interface UITouchesEvent: UIEvent

-(id)_firstTouchForView:(id)arg1 ;

@end

@interface SBReachabilitySettings
@end

@interface SBReachabilityManager: NSObject

+(id)sharedInstance;
-(BOOL)reachabilityModeActive;
-(void)toggleReachability;
-(void)_notifyObserversReachabilityModeActive:(BOOL)arg1 excludingObserver:(id)arg2;
-(void)setWallpaper:(id)controller duration:(NSTimeInterval)duration;
-(void)setBackground:(BOOL)animated;
-(void)swipeLeft:(UISwipeGestureRecognizer *)sender;
-(void)swipeRight:(UISwipeGestureRecognizer *)sender;
-(void)swipe;
-(void)fadeScaleIndicatorDelayed;

@property (nonatomic, retain) OverlayView *panningView;
@property (nonatomic, retain) OverlayView *slidingView;
@property (nonatomic, retain) UIImageView *wallpaperImageView;
@property (nonatomic, retain) UIVisualEffectView *scaleIndicator;
@property (nonatomic, retain) UILabel *indicatorLabel;
@property (nonatomic, assign) NSInteger backgroundMode;
@property (nonatomic, retain) UIImage *selectedImage;

@end

@interface FBRootWindow: UIWindow

-(UIView *)_systemGestureView;
-(void)attachSceneTransform:(id)arg1 ;
-(void)removeSceneTransform:(id)arg1 ;
-(UIView *)sceneContainerView;

@end

@interface SBWallpaperController: NSObject

+(id)sharedInstance;
-(id)_wallpaperViewForVariant:(long long)arg1;
-(id)homescreenLightForegroundBlurImage;

@end

@interface SBFStaticWallpaperView: UIView

-(id)wallpaperImage;
-(id)_displayedImage;

@end

@interface SBFProceduralWallpaperView: UIView

-(id)snapshotImage;
-(id)_blurredImage;

@end

@interface MTSystemModuleMaterialSettings: NSObject

+(id)sharedMaterialSettings;

@end

@interface MTMaterialView: UIView

- (id)initWithSettings:(id)arg1 options:(unsigned long long)arg2 initialWeighting:(double)arg3 scaleAdjustment:(id /* block */)arg4;
- (void)_setContinuousCornerRadius:(double)arg1;

@end
