
#import <UIKit/UIKit.h>
#import "ThemeableTableViewCell.h"

@interface FirmwareCell : ThemeableTableViewCell

@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *versionLabel;
@property (weak, nonatomic) IBOutlet UILabel *buildTimeLabel;

@end
