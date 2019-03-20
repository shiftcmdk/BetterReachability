#include "BRRootListController.h"

@interface PSTableCell : UITableViewCell
@end

@interface ScaleCell : PSTableCell
@end

@implementation ScaleCell
@end

@interface PositionCell : PSTableCell
@end

@implementation PositionCell
@end

@interface BRRootListController ()

-(void)removeAccessoryForCellsInSection:(int)section;

@end

@implementation BRRootListController

- (NSArray *)specifiers {
	if (!_specifiers) {
		_specifiers = [[self loadSpecifiersFromPlistName:@"Root" target:self] retain];
	}

	return _specifiers;
}

// com.shiftcmdk.betterreachabilitypreferences
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

	return cell;
}

-(void)removeAccessoryForCellsInSection:(int)section {
	// -(id)table;
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
		} else {
			[super tableView:arg1 didSelectRowAtIndexPath:arg2];
		}
	} else {
		[super tableView:arg1 didSelectRowAtIndexPath:arg2];
	}
}

@end
