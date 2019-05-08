@interface PSTableCell : UITableViewCell

-(id)initWithStyle:(long long)arg1 reuseIdentifier:(id)arg2 specifier:(id)arg3;

@end

@interface ScaleCell : PSTableCell
@end

@interface PositionCell : PSTableCell
@end

@interface PSSegmentTableCell: PSTableCell
@end

@interface SegmentCell : PSSegmentTableCell
@end

@interface ColorCell : PSTableCell

@property (nonatomic, retain) UIView *colorView;
@property (nonatomic, retain) UISlider *rSlider;
@property (nonatomic, retain) UISlider *gSlider;
@property (nonatomic, retain) UISlider *bSlider;
@property (nonatomic, retain) UITextField *rTextField;
@property (nonatomic, retain) UITextField *gTextField;
@property (nonatomic, retain) UITextField *bTextField;

@end

@interface ImageCell : PSTableCell

@property (nonatomic, retain) UIImageView *customImageView;
@property (nonatomic, retain) UIButton *addButton;
@property (nonatomic, retain) UIButton *trashButton;

@end