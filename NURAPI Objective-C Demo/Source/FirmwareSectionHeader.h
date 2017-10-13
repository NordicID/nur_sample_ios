
#import <UIKit/UIKit.h>

@interface FirmwareSectionHeader : UITableViewHeaderFooterView

@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *versionLabel;
@property (weak, nonatomic) IBOutlet UILabel *statusLabel;

@end
