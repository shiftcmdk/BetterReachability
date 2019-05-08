#import "Cells.h"

@implementation ScaleCell
@end

@implementation PositionCell
@end

@implementation SegmentCell

-(void)layoutSubviews {
	[super layoutSubviews];

	for (UIView *aView in self.contentView.subviews) {
		if ([aView isKindOfClass:[UISegmentedControl class]]) {
			aView.frame = CGRectMake(
				self.contentView.layoutMargins.left,
				aView.frame.origin.y,
				self.contentView.bounds.size.width - 2.0 * self.contentView.layoutMargins.left,
				aView.bounds.size.height
			);
		}
	}
}

@end

@implementation ColorCell

-(id)initWithStyle:(long long)arg1 reuseIdentifier:(id)arg2 specifier:(id)arg3 {
	self = [super initWithStyle:arg1 reuseIdentifier:arg2 specifier:arg3];

	if (self) {
		self.colorView = [[[UIView alloc] init] autorelease];
		self.colorView.translatesAutoresizingMaskIntoConstraints = NO;
		self.colorView.backgroundColor = [UIColor blackColor];

		[self.contentView addSubview:self.colorView];

		[self.colorView.centerXAnchor constraintEqualToAnchor:self.contentView.centerXAnchor].active = YES;
		[self.colorView.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:8.0].active = YES;
		[self.colorView.heightAnchor constraintEqualToConstant:244.0].active = YES;
		[self.colorView.widthAnchor constraintEqualToConstant:137.0].active = YES;

		self.rSlider = [[[UISlider alloc] init] autorelease];
		self.rSlider.translatesAutoresizingMaskIntoConstraints = NO;
		self.rSlider.minimumTrackTintColor = [UIColor redColor];

		[self.contentView addSubview:self.rSlider];

		[self.rSlider.topAnchor constraintEqualToAnchor:self.colorView.bottomAnchor constant:8.0].active = YES;
		[self.rSlider.heightAnchor constraintEqualToConstant:34.0].active = YES;

		self.gSlider = [[[UISlider alloc] init] autorelease];
		self.gSlider.translatesAutoresizingMaskIntoConstraints = NO;
		self.gSlider.minimumTrackTintColor = [UIColor greenColor];

		[self.contentView addSubview:self.gSlider];

		[self.gSlider.topAnchor constraintEqualToAnchor:self.rSlider.bottomAnchor constant:8.0].active = YES;
		[self.gSlider.heightAnchor constraintEqualToConstant:34.0].active = YES;

		self.bSlider = [[[UISlider alloc] init] autorelease];
		self.bSlider.translatesAutoresizingMaskIntoConstraints = NO;
		self.bSlider.minimumTrackTintColor = [UIColor blueColor];

		[self.contentView addSubview:self.bSlider];

		[self.bSlider.topAnchor constraintEqualToAnchor:self.gSlider.bottomAnchor constant:8.0].active = YES;
		[self.bSlider.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor constant:-8.0].active = YES;
		[self.bSlider.heightAnchor constraintEqualToConstant:34.0].active = YES;

		UILabel *rLabel = [[[UILabel alloc] init] autorelease];
		rLabel.translatesAutoresizingMaskIntoConstraints = NO;
		rLabel.text = @"R";
		rLabel.textColor = [UIColor colorWithRed:153.0 / 255.0 green:153.0 / 255.0 blue:153.0 / 255.0 alpha:1.0];

		[self.contentView addSubview:rLabel];

		[rLabel.centerYAnchor constraintEqualToAnchor:self.rSlider.centerYAnchor].active = YES;
		[rLabel.leadingAnchor constraintEqualToAnchor:self.contentView.layoutMarginsGuide.leadingAnchor].active = YES;

		UILabel *gLabel = [[[UILabel alloc] init] autorelease];
		gLabel.translatesAutoresizingMaskIntoConstraints = NO;
		gLabel.text = @"G";
		gLabel.textColor = [UIColor colorWithRed:153.0 / 255.0 green:153.0 / 255.0 blue:153.0 / 255.0 alpha:1.0];

		[self.contentView addSubview:gLabel];

		[gLabel.centerYAnchor constraintEqualToAnchor:self.gSlider.centerYAnchor].active = YES;
		[gLabel.leadingAnchor constraintEqualToAnchor:self.contentView.layoutMarginsGuide.leadingAnchor].active = YES;

		UILabel *bLabel = [[[UILabel alloc] init] autorelease];
		bLabel.translatesAutoresizingMaskIntoConstraints = NO;
		bLabel.text = @"B";
		bLabel.textColor = [UIColor colorWithRed:153.0 / 255.0 green:153.0 / 255.0 blue:153.0 / 255.0 alpha:1.0];

		[self.contentView addSubview:bLabel];

		[bLabel.centerYAnchor constraintEqualToAnchor:self.bSlider.centerYAnchor].active = YES;
		[bLabel.leadingAnchor constraintEqualToAnchor:self.contentView.layoutMarginsGuide.leadingAnchor].active = YES;

		[self.rSlider.leadingAnchor constraintEqualToAnchor:rLabel.trailingAnchor constant:8.0].active = YES;
		[self.gSlider.leadingAnchor constraintEqualToAnchor:rLabel.trailingAnchor constant:8.0].active = YES;
		[self.bSlider.leadingAnchor constraintEqualToAnchor:rLabel.trailingAnchor constant:8.0].active = YES;

		self.rTextField = [[[UITextField alloc] init] autorelease];
		self.rTextField.translatesAutoresizingMaskIntoConstraints = NO;
		self.rTextField.text = @"0";
		self.rTextField.textAlignment = NSTextAlignmentRight;

		[self.contentView addSubview:self.rTextField];

		[self.rTextField.topAnchor constraintEqualToAnchor:self.rSlider.topAnchor].active = YES;
		[self.rTextField.bottomAnchor constraintEqualToAnchor:self.rSlider.bottomAnchor].active = YES;
		[self.rTextField.trailingAnchor constraintEqualToAnchor:self.contentView.layoutMarginsGuide.trailingAnchor].active = YES;
		[self.rTextField.widthAnchor constraintEqualToConstant:35.0].active = YES;

		self.gTextField = [[[UITextField alloc] init] autorelease];
		self.gTextField.translatesAutoresizingMaskIntoConstraints = NO;
		self.gTextField.text = @"0";
		self.gTextField.textAlignment = NSTextAlignmentRight;

		[self.contentView addSubview:self.gTextField];

		[self.gTextField.topAnchor constraintEqualToAnchor:self.gSlider.topAnchor].active = YES;
		[self.gTextField.bottomAnchor constraintEqualToAnchor:self.gSlider.bottomAnchor].active = YES;
		[self.gTextField.trailingAnchor constraintEqualToAnchor:self.contentView.layoutMarginsGuide.trailingAnchor].active = YES;
		[self.gTextField.widthAnchor constraintEqualToAnchor:self.rTextField.widthAnchor].active = YES;

		self.bTextField = [[[UITextField alloc] init] autorelease];
		self.bTextField.translatesAutoresizingMaskIntoConstraints = NO;
		self.bTextField.text = @"0";
		self.bTextField.textAlignment = NSTextAlignmentRight;

		[self.contentView addSubview:self.bTextField];

		[self.bTextField.topAnchor constraintEqualToAnchor:self.bSlider.topAnchor].active = YES;
		[self.bTextField.bottomAnchor constraintEqualToAnchor:self.bSlider.bottomAnchor].active = YES;
		[self.bTextField.trailingAnchor constraintEqualToAnchor:self.contentView.layoutMarginsGuide.trailingAnchor].active = YES;
		[self.bTextField.widthAnchor constraintEqualToAnchor:self.rTextField.widthAnchor].active = YES;

		self.rTextField.placeholder = @"R";
		self.rTextField.autocorrectionType = UITextAutocorrectionTypeNo;
		self.rTextField.spellCheckingType = UITextSpellCheckingTypeNo;
		self.rTextField.returnKeyType = UIReturnKeyDone;
		self.rTextField.autocapitalizationType = UITextAutocapitalizationTypeNone;

		self.gTextField.placeholder = @"G";
		self.gTextField.autocorrectionType = UITextAutocorrectionTypeNo;
		self.gTextField.spellCheckingType = UITextSpellCheckingTypeNo;
		self.gTextField.returnKeyType = UIReturnKeyDone;
		self.gTextField.autocapitalizationType = UITextAutocapitalizationTypeNone;

		self.bTextField.placeholder = @"B";
		self.bTextField.autocorrectionType = UITextAutocorrectionTypeNo;
		self.bTextField.spellCheckingType = UITextSpellCheckingTypeNo;
		self.bTextField.returnKeyType = UIReturnKeyDone;
		self.bTextField.autocapitalizationType = UITextAutocapitalizationTypeNone;

		[self.rSlider.trailingAnchor constraintEqualToAnchor:self.rTextField.leadingAnchor constant:-8.0].active = YES;
		[self.gSlider.trailingAnchor constraintEqualToAnchor:self.rTextField.leadingAnchor constant:-8.0].active = YES;
		[self.bSlider.trailingAnchor constraintEqualToAnchor:self.rTextField.leadingAnchor constant:-8.0].active = YES;
	}

	return self;
}

-(void)layoutSubviews {
	[super layoutSubviews];
}

-(void)dealloc {
	self.colorView = nil;

	self.rSlider = nil;
	self.gSlider = nil;
	self.bSlider = nil;

	self.rTextField = nil;
	self.gTextField = nil;
	self.bTextField = nil;

	[super dealloc];
}

@end

@implementation ImageCell

-(id)initWithStyle:(long long)arg1 reuseIdentifier:(id)arg2 specifier:(id)arg3 {
	self = [super initWithStyle:arg1 reuseIdentifier:arg2 specifier:arg3];

	if (self) {
		self.customImageView = [[[UIImageView alloc] init] autorelease];
		self.customImageView.translatesAutoresizingMaskIntoConstraints = NO;
		self.customImageView.clipsToBounds = YES;
		self.customImageView.contentMode = UIViewContentModeScaleAspectFill;

		[self.contentView addSubview:self.customImageView];

		[self.customImageView.centerXAnchor constraintEqualToAnchor:self.contentView.centerXAnchor].active = YES;
		[self.customImageView.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:8.0].active = YES;
		[self.customImageView.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor constant:-8.0].active = YES;
		[self.customImageView.heightAnchor constraintEqualToConstant:244.0].active = YES;
		[self.customImageView.widthAnchor constraintEqualToConstant:137.0].active = YES;

		self.addButton = [UIButton buttonWithType:UIButtonTypeSystem];
		self.addButton.backgroundColor = self.tintColor;
		self.addButton.layer.cornerRadius = 8.0;
		self.addButton.translatesAutoresizingMaskIntoConstraints = NO;
		[self.addButton setTitle:@"Choose Image..." forState:UIControlStateNormal];
		[self.addButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];

		[self.contentView addSubview:self.addButton];

		[self.addButton.leadingAnchor constraintEqualToAnchor:self.contentView.layoutMarginsGuide.leadingAnchor].active = YES;
		[self.addButton.trailingAnchor constraintEqualToAnchor:self.contentView.layoutMarginsGuide.trailingAnchor].active = YES;
		[self.addButton.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor].active = YES;
		[self.addButton.heightAnchor constraintEqualToConstant:44.0].active = YES;

		UIView *containerView = [[[UIView alloc] init] autorelease];
		containerView.translatesAutoresizingMaskIntoConstraints = NO;

		[self.contentView addSubview:containerView];

		[containerView.topAnchor constraintEqualToAnchor:self.customImageView.topAnchor].active = YES;
		[containerView.bottomAnchor constraintEqualToAnchor:self.customImageView.bottomAnchor].active = YES;
		[containerView.leadingAnchor constraintEqualToAnchor:self.customImageView.trailingAnchor].active = YES;
		[containerView.trailingAnchor constraintEqualToAnchor:self.contentView.layoutMarginsGuide.trailingAnchor].active = YES;

		NSBundle *bundle = [NSBundle bundleWithPath:@"/System/Library/Frameworks/UIKit.framework/Artwork.bundle"];
		UIImage *image = [UIImage imageNamed:@"UIButtonBarTrash" inBundle:bundle compatibleWithTraitCollection:nil];

		self.trashButton = [UIButton buttonWithType:UIButtonTypeSystem];
		self.trashButton.translatesAutoresizingMaskIntoConstraints = NO;
		self.trashButton.tintColor = [UIColor colorWithRed:1.0 green:59.0 / 255.0 blue:48.0 / 255.0 alpha:1.0];
		[self.trashButton setImage:image forState:UIControlStateNormal];

		[containerView addSubview:self.trashButton];

		[self.trashButton.centerXAnchor constraintEqualToAnchor:containerView.centerXAnchor].active = YES;
		[self.trashButton.centerYAnchor constraintEqualToAnchor:containerView.centerYAnchor].active = YES;
		[self.trashButton.widthAnchor constraintEqualToConstant:image.size.width].active = YES;
		[self.trashButton.heightAnchor constraintEqualToConstant:image.size.height].active = YES;
	}

	return self;
}

-(void)layoutSubviews {
	[super layoutSubviews];

	self.addButton.hidden = self.customImageView.image != nil;
	self.trashButton.hidden = self.customImageView.image == nil;
}

-(void)dealloc {
	self.customImageView = nil;
	self.addButton = nil;
	self.trashButton = nil;

	[super dealloc];
}

@end