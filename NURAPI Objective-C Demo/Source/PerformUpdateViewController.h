
#import <UIKit/UIKit.h>

#import "Firmware.h"

@interface PerformUpdateViewController : UIViewController

@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *versionLabel;
@property (weak, nonatomic) IBOutlet UILabel *buildTimeLabel;

@property (nonatomic, strong) Firmware * firmware;

@end
