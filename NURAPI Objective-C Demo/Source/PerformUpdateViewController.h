
#import <UIKit/UIKit.h>
@import iOSDFULibrary;

#import "Firmware.h"
#import "UIViewController+Theme.h"

@interface PerformUpdateViewController : UIViewController <BluetoothDelegate, DFUProgressDelegate, LoggerDelegate, DFUServiceDelegate>

@property (weak, nonatomic) IBOutlet UILabel *firmwareTypeLabel;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *versionLabel;
@property (weak, nonatomic) IBOutlet UILabel *buildTimeLabel;
@property (weak, nonatomic) IBOutlet UIButton *updateButton;

@property (nonatomic, strong) Firmware * firmware;

@end
