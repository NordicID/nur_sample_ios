
#import <UIKit/UIKit.h>

#import "Firmware.h"

@interface PerformUpdateViewController : UIViewController <BluetoothDelegate>

@property (weak, nonatomic) IBOutlet UILabel *firmwareTypeLabel;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *versionLabel;
@property (weak, nonatomic) IBOutlet UILabel *buildTimeLabel;
@property (weak, nonatomic) IBOutlet UIButton *updateButton;

@property (nonatomic, strong) Firmware * firmware;

@end
