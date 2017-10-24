
#import <UIKit/UIKit.h>
#import "FirmwareDownloader.h"
#import "UIViewController+Theme.h"

@interface FirmwareTypeViewController : UIViewController <FirmwareDownloaderDelegate>

@property (weak, nonatomic) IBOutlet UILabel *currentReaderFirmwareVersion;
@property (weak, nonatomic) IBOutlet UILabel *currentNurRfidFirmwareVersion;
@property (weak, nonatomic) IBOutlet UILabel *availableReaderFirmwareVersion;
@property (weak, nonatomic) IBOutlet UILabel *availableNurRfidFirmwareVersion;
@property (weak, nonatomic) IBOutlet UIButton *readerFirmwareButton;
@property (weak, nonatomic) IBOutlet UIButton *nurRfidFirmwareButton;

@end
