
#import "FirmwareTypeViewController.h"
#import "FirmwareSelectionViewController.h"
#import "Firmware.h"

@implementation FirmwareTypeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}



#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    FirmwareSelectionViewController * destination = [segue destinationViewController];

    if ( [segue.identifier isEqualToString:@"RFIDFirmwareUpdateSegue"] ) {
        destination.firmwareType = kNurRfidFirmware;
    }
    else if ( [segue.identifier isEqualToString:@"ReaderFirmwareUpdateSegue"] ) {
        destination.firmwareType = kReaderFirmware;
    }
}

@end
