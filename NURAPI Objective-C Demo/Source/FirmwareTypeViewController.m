
#import <NurAPIBluetooth/Bluetooth.h>

#import "FirmwareTypeViewController.h"
#import "FirmwareSelectionViewController.h"
#import "Firmware.h"

@implementation FirmwareTypeViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    if ( ! [Bluetooth sharedInstance].currentReader ) {
        [self showErrorMessage:@"Please connect an RFID reader"];

        self.readerFirmwareButton.enabled = NO;
        self.nurRfidFirmwareButton.enabled = NO;
        return;
    }
}


- (void) showErrorMessage:(NSString *)message {
    dispatch_async(dispatch_get_main_queue(), ^{
        // show in an alert view
        UIAlertController * alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Error", nil)
                                                                        message:message
                                                                 preferredStyle:UIAlertControllerStyleAlert];

        UIAlertAction* okButton = [UIAlertAction
                                   actionWithTitle:NSLocalizedString(@"Ok", nil)
                                   style:UIAlertActionStyleDefault
                                   handler:^(UIAlertAction * action) {
                                       // nothing special to do right now
                                   }];


        [alert addAction:okButton];
        [self presentViewController:alert animated:YES completion:nil];
    } );
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
