
#import <UIKit/UIKit.h>

@interface FirmwareTypeViewController : UIViewController

@property (weak, nonatomic) IBOutlet UILabel *currentReaderFirmwareVersion;
@property (weak, nonatomic) IBOutlet UILabel *currentNurRfidFirmwareVersion;
@property (weak, nonatomic) IBOutlet UILabel *availableReaderFirmwareVersion;
@property (weak, nonatomic) IBOutlet UILabel *availableNurRfidFirmwareVersion;
@property (weak, nonatomic) IBOutlet UIButton *readerFirmwareButton;
@property (weak, nonatomic) IBOutlet UIButton *nurRfidFirmwareButton;

@end
