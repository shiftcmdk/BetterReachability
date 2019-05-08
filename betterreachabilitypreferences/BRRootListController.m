#include "BRRootListController.h"
#import "Cells.h"

@interface BRRootListController () <UINavigationControllerDelegate, UIImagePickerControllerDelegate>

@property (nonatomic, retain) PSSpecifier *backgroundSpecifier;
@property (nonatomic, retain) PSSpecifier *colorSpecifier;
@property (nonatomic, retain) PSSpecifier *imageSpecifier;
@property (nonatomic, assign) BOOL showColor;
@property (nonatomic, assign) BOOL showImage;
@property (nonatomic, retain) UIImage *selectedImage;
@property (nonatomic, retain) UIColor *selectedColor;
-(void)postBackgroundNotification;
-(void)removeAccessoryForCellsInSection:(int)section;

@end

@implementation BRRootListController

- (NSArray *)specifiers {
	NSUserDefaults *defaults = [[[NSUserDefaults alloc] initWithSuiteName:@"com.shiftcmdk.betterreachabilitypreferences"] autorelease];

	int background = [[defaults objectForKey:@"background"] intValue];

	self.showColor = background == 1;
	self.showImage = background == 2;

	if (!_specifiers) {
		NSMutableArray *theSpecifiers = [NSMutableArray array];

		for (PSSpecifier *aSpecifier in [self loadSpecifiersFromPlistName:@"Root" target:self]) {
			id props = [aSpecifier properties];

			NSString *classString = [NSString stringWithFormat:@"%@", [props objectForKey:@"cellClass"]];
			if ([[props objectForKey:@"identifier"] isEqual:@"backgroundSegment"]) {
				self.backgroundSpecifier = aSpecifier;

				[theSpecifiers addObject:aSpecifier];
			} else if ([classString isEqual:NSStringFromClass([ColorCell class])]) {
				self.colorSpecifier = aSpecifier;

				if (self.showColor) {
					[theSpecifiers addObject:aSpecifier];
				}
			} else if ([classString isEqual:NSStringFromClass([ImageCell class])]) {
				self.imageSpecifier = aSpecifier;

				if (self.showImage) {
					[theSpecifiers addObject:aSpecifier];
				}
			} else {
				[theSpecifiers addObject:aSpecifier];
			}
		}

		_specifiers = [theSpecifiers retain];
	}

	return _specifiers;
}

-(void)viewDidLoad {
	[super viewDidLoad];

	NSUserDefaults *defaults = [[[NSUserDefaults alloc] initWithSuiteName:@"com.shiftcmdk.betterreachabilitypreferences"] autorelease];

	id customColor = [defaults objectForKey:@"customcolor"];

	if ([customColor isKindOfClass:[NSArray class]] && [customColor count] >= 3) {
		self.selectedColor = [UIColor colorWithRed:[customColor[0] floatValue] green:[customColor[1] floatValue] blue:[customColor[2] floatValue] alpha:1.0];
	} else {
		self.selectedColor = [UIColor blackColor];
	}

	NSDictionary *dict = [[[NSDictionary alloc] initWithContentsOfFile:@"/var/mobile/Library/Preferences/com.shiftcmdk.betterreachabilitypreferences.image.plist"] autorelease];

	NSData *imageData = [dict objectForKey:@"image"];

	if (imageData) {
		self.selectedImage = [UIImage imageWithData:imageData];
	}
}

-(id)tableView:(id)arg1 cellForRowAtIndexPath:(NSIndexPath *)arg2 {
	UITableViewCell *cell = [super tableView:arg1 cellForRowAtIndexPath:arg2];

	if ([cell isKindOfClass:[ScaleCell class]]) {
		NSUserDefaults *defaults = [[[NSUserDefaults alloc] initWithSuiteName:@"com.shiftcmdk.betterreachabilitypreferences"] autorelease];

		int selectedRow;

		if ([defaults objectForKey:@"initialscale"] == nil) {
			selectedRow = 0;
		} else {
			selectedRow = [[defaults objectForKey:@"initialscale"] intValue];
		}

		if (arg2.row == selectedRow) {
			cell.accessoryType = UITableViewCellAccessoryCheckmark;
		} else {
			cell.accessoryType = UITableViewCellAccessoryNone;
		}

		cell.selectionStyle = UITableViewCellSelectionStyleDefault;
	}

	if ([cell isKindOfClass:[PositionCell class]]) {
		NSUserDefaults *defaults = [[[NSUserDefaults alloc] initWithSuiteName:@"com.shiftcmdk.betterreachabilitypreferences"] autorelease];

		int selectedRow;

		if ([defaults objectForKey:@"initialposition"] == nil) {
			selectedRow = 2;
		} else {
			selectedRow = [[defaults objectForKey:@"initialposition"] intValue];
		}

		if (arg2.row == selectedRow) {
			cell.accessoryType = UITableViewCellAccessoryCheckmark;
		} else {
			cell.accessoryType = UITableViewCellAccessoryNone;
		}

		cell.selectionStyle = UITableViewCellSelectionStyleDefault;
	}

	if ([cell isKindOfClass:[ImageCell class]]) {
		ImageCell *imageCell = (ImageCell *)cell;

		[imageCell.addButton addTarget:self action:@selector(chooseImageTapped:) forControlEvents:UIControlEventTouchUpInside];
		[imageCell.trashButton addTarget:self action:@selector(trashButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
		imageCell.customImageView.image = self.selectedImage;
	}

	if ([cell isKindOfClass:[ColorCell class]]) {
		ColorCell *colorCell = (ColorCell *)cell;
		colorCell.colorView.backgroundColor = self.selectedColor;

		CGFloat red = 0.0, green = 0.0, blue = 0.0;
		[self.selectedColor getRed:&red green:&green blue:&blue alpha:nil];

		colorCell.rSlider.value = red;
		colorCell.gSlider.value = green;
		colorCell.bSlider.value = blue;

		colorCell.rTextField.text = [NSString stringWithFormat:@"%i", (int)(red * 255.0)];
		colorCell.gTextField.text = [NSString stringWithFormat:@"%i", (int)(green * 255.0)];
		colorCell.bTextField.text = [NSString stringWithFormat:@"%i", (int)(blue * 255.0)];

		[colorCell.rTextField addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
		[colorCell.gTextField addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
		[colorCell.bTextField addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];

		[colorCell.rTextField addTarget:nil action:@selector(dimissTextField:) forControlEvents:UIControlEventEditingDidEndOnExit];
		[colorCell.gTextField addTarget:nil action:@selector(dimissTextField:) forControlEvents:UIControlEventEditingDidEndOnExit];
		[colorCell.bTextField addTarget:nil action:@selector(dimissTextField:) forControlEvents:UIControlEventEditingDidEndOnExit];

		[colorCell.rSlider addTarget:self action:@selector(sliderChanged:) forControlEvents:UIControlEventValueChanged];
		[colorCell.gSlider addTarget:self action:@selector(sliderChanged:) forControlEvents:UIControlEventValueChanged];
		[colorCell.bSlider addTarget:self action:@selector(sliderChanged:) forControlEvents:UIControlEventValueChanged];
	}

	return cell;
}

-(void)postBackgroundNotification {
	CFNotificationCenterPostNotification(
		CFNotificationCenterGetDarwinNotifyCenter(), 
		(CFStringRef)@"com.shiftcmdk.betterreachabilitypreferences.background", 
		NULL, 
		NULL, 
		YES
	);
}

-(void)dimissTextField:(UITextField *)sender {
	[sender resignFirstResponder];
}

-(void)textFieldDidChange:(UITextField *)sender {
	for (UITableViewCell *cell in [self table].visibleCells) {
		if ([cell isKindOfClass:[ColorCell class]]) {
			ColorCell *colorCell = (ColorCell *)cell;

			colorCell.rSlider.value = (double)[colorCell.rTextField.text intValue] / 255.0;
			colorCell.gSlider.value = (double)[colorCell.gTextField.text intValue] / 255.0;
			colorCell.bSlider.value = (double)[colorCell.bTextField.text intValue] / 255.0;

			self.selectedColor = [UIColor colorWithRed:colorCell.rSlider.value green:colorCell.gSlider.value blue:colorCell.bSlider.value alpha:1.0];

			NSUserDefaults *defaults = [[[NSUserDefaults alloc] initWithSuiteName:@"com.shiftcmdk.betterreachabilitypreferences"] autorelease];

			NSNumber *r = [NSNumber numberWithFloat:colorCell.rSlider.value];
			NSNumber *g = [NSNumber numberWithFloat:colorCell.gSlider.value];
			NSNumber *b = [NSNumber numberWithFloat:colorCell.bSlider.value];

			[defaults setObject:@[r, g, b] forKey:@"customcolor"];

			colorCell.colorView.backgroundColor = self.selectedColor;

			break;
		}
	}

	[self postBackgroundNotification];
}

-(void)sliderChanged:(UISlider *)sender {
	for (UITableViewCell *cell in [self table].visibleCells) {
		if ([cell isKindOfClass:[ColorCell class]]) {
			ColorCell *colorCell = (ColorCell *)cell;

			self.selectedColor = [UIColor colorWithRed:colorCell.rSlider.value green:colorCell.gSlider.value blue:colorCell.bSlider.value alpha:1.0];

			NSUserDefaults *defaults = [[[NSUserDefaults alloc] initWithSuiteName:@"com.shiftcmdk.betterreachabilitypreferences"] autorelease];

			NSNumber *r = [NSNumber numberWithFloat:colorCell.rSlider.value];
			NSNumber *g = [NSNumber numberWithFloat:colorCell.gSlider.value];
			NSNumber *b = [NSNumber numberWithFloat:colorCell.bSlider.value];

			colorCell.rTextField.text = [NSString stringWithFormat:@"%i", (int)(colorCell.rSlider.value * 255.0)];
			colorCell.gTextField.text = [NSString stringWithFormat:@"%i", (int)(colorCell.gSlider.value * 255.0)];
			colorCell.bTextField.text = [NSString stringWithFormat:@"%i", (int)(colorCell.bSlider.value * 255.0)];

			[defaults setObject:@[r, g, b] forKey:@"customcolor"];

			colorCell.colorView.backgroundColor = self.selectedColor;

			break;
		}
	}

	[self postBackgroundNotification];
}

-(void)chooseImageTapped:(UIButton *)sender {
	UIImagePickerController* imagePicker = [[[UIImagePickerController alloc] init] autorelease];
	
	if([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) {
		imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
		imagePicker.delegate = self;
		[self presentViewController:imagePicker animated:true completion:nil];
	}
}

-(void)trashButtonTapped:(UIButton *)sender {
	NSMutableDictionary *dict = [[[NSMutableDictionary alloc] initWithContentsOfFile:@"/var/mobile/Library/Preferences/com.shiftcmdk.betterreachabilitypreferences.image.plist"] autorelease];

	[dict removeObjectForKey:@"image"];

	[dict writeToFile:@"/var/mobile/Library/Preferences/com.shiftcmdk.betterreachabilitypreferences.image.plist" atomically:YES];

	self.selectedImage = nil;

	[self postBackgroundNotification];

	for (UITableViewCell *cell in [self table].visibleCells) {
		if ([cell isKindOfClass:[ImageCell class]]) {
			ImageCell *imageCell = (ImageCell *)cell;

			imageCell.customImageView.image = nil;
			imageCell.trashButton.hidden = YES;
			imageCell.addButton.hidden = NO;

			break;
		}
	}
}

-(void)removeAccessoryForCellsInSection:(int)section {
	UITableView *tableView = [self table];

	for (int i = 0; i < [tableView numberOfRowsInSection:section]; i++) {
		UITableViewCell *theCell = [tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:section]];

		if (theCell) {
			theCell.accessoryType = UITableViewCellAccessoryNone;
		}
	}
}

-(void)tableView:(UITableView *)arg1 didSelectRowAtIndexPath:(NSIndexPath *)arg2 {
	UITableViewCell *cell = [arg1 cellForRowAtIndexPath:arg2];

	if (cell) {
		if ([cell isKindOfClass:[ScaleCell class]]) {
			[self removeAccessoryForCellsInSection:arg2.section];

			NSUserDefaults *defaults = [[[NSUserDefaults alloc] initWithSuiteName:@"com.shiftcmdk.betterreachabilitypreferences"] autorelease];

			[defaults setObject:[NSNumber numberWithInt:arg2.row] forKey:@"initialscale"];

			cell.accessoryType = UITableViewCellAccessoryCheckmark;

			[arg1 deselectRowAtIndexPath:arg2 animated:YES];
		} else if ([cell isKindOfClass:[PositionCell class]]) {
			[self removeAccessoryForCellsInSection:arg2.section];

			NSUserDefaults *defaults = [[[NSUserDefaults alloc] initWithSuiteName:@"com.shiftcmdk.betterreachabilitypreferences"] autorelease];

			[defaults setObject:[NSNumber numberWithInt:arg2.row] forKey:@"initialposition"];

			cell.accessoryType = UITableViewCellAccessoryCheckmark;

			[arg1 deselectRowAtIndexPath:arg2 animated:YES];
		} else if ([cell isKindOfClass:[ImageCell class]]) {
			if (self.selectedImage) {
				UIImagePickerController* imagePicker = [[[UIImagePickerController alloc] init] autorelease];
	
				if([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) {
					imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
					imagePicker.delegate = self;
					[self presentViewController:imagePicker animated:true completion:nil];
				}
			}
		} else {
			[super tableView:arg1 didSelectRowAtIndexPath:arg2];
		}
	} else {
		[super tableView:arg1 didSelectRowAtIndexPath:arg2];
	}
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
	[self dismissViewControllerAnimated:YES completion:nil];

	UIImage *image = info[UIImagePickerControllerOriginalImage];

	if (image) {
		self.selectedImage = image;

		NSMutableDictionary *dict = [[[NSMutableDictionary alloc] initWithContentsOfFile:@"/var/mobile/Library/Preferences/com.shiftcmdk.betterreachabilitypreferences.image.plist"] autorelease];

		NSData *imageData = UIImagePNGRepresentation(image);

		if (imageData) {
			[dict setObject:imageData forKey:@"image"];
		}

		[dict writeToFile:@"/var/mobile/Library/Preferences/com.shiftcmdk.betterreachabilitypreferences.image.plist" atomically:YES];

		CFNotificationCenterPostNotification(
			CFNotificationCenterGetDarwinNotifyCenter(), 
			(CFStringRef)@"com.shiftcmdk.betterreachabilitypreferences.background", 
			NULL, 
			NULL, 
			YES
		);

		for (UITableViewCell *cell in [self table].visibleCells) {
			if ([cell isKindOfClass:[ImageCell class]]) {
				((ImageCell *)cell).customImageView.image = image;
				((ImageCell *)cell).addButton.hidden = YES;
				((ImageCell *)cell).trashButton.hidden = NO;

				break;
			}
		}
	}
}

-(void)selectedIndexDidChange:(NSString *)arg1 {
	NSUserDefaults *defaults = [[[NSUserDefaults alloc] initWithSuiteName:@"com.shiftcmdk.betterreachabilitypreferences"] autorelease];

	[defaults setObject:[NSNumber numberWithInt:[arg1 intValue]] forKey:@"background"];
	int index = [arg1 intValue];

	int colorIndex = [self indexOfSpecifier:self.colorSpecifier];
	int imageIndex = [self indexOfSpecifier:self.imageSpecifier];

	if (index == 0) {
		self.showColor = NO;
		self.showImage = NO;

		if (colorIndex > 0) {
			[self removeSpecifierAtIndex:colorIndex animated:YES];
		} else if (imageIndex > 0) {
			[self removeSpecifierAtIndex:imageIndex animated:YES];
		}
	} else if (index == 1) {
		self.showColor = YES;
		self.showImage = NO;

		if (imageIndex > 0) {
			[self removeSpecifierAtIndex:imageIndex animated:YES];
		}

		[self insertSpecifier:self.colorSpecifier afterSpecifier:self.backgroundSpecifier animated:YES];
	} else if (index == 2) {
		self.showColor = NO;
		self.showImage = YES;

		if (colorIndex > 0) {
			[self removeSpecifierAtIndex:colorIndex animated:YES];
		}

		[self insertSpecifier:self.imageSpecifier afterSpecifier:self.backgroundSpecifier animated:YES];
	}

	CFNotificationCenterPostNotification(
		CFNotificationCenterGetDarwinNotifyCenter(), 
		(CFStringRef)@"com.shiftcmdk.betterreachabilitypreferences.background", 
		NULL, 
		NULL, 
		YES
	);
}

-(NSString *)selectedIndex {
	NSUserDefaults *defaults = [[[NSUserDefaults alloc] initWithSuiteName:@"com.shiftcmdk.betterreachabilitypreferences"] autorelease];

	return [NSString stringWithFormat:@"%i", [[defaults objectForKey:@"background"] intValue]];
}

-(void)dealloc {
	self.backgroundSpecifier = nil;
	self.colorSpecifier = nil;
	self.imageSpecifier = nil;
	self.selectedImage = nil;
	self.selectedColor = nil;

	[super dealloc];
}

@end
