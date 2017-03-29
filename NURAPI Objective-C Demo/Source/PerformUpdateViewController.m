
#import <CommonCrypto/CommonDigest.h>

#import "PerformUpdateViewController.h"

@interface PerformUpdateViewController ()

@property (nonatomic, strong) UIAlertController * inProgressAlert;
@property (nonatomic, strong) NSData * firmwareData;

@end

@implementation PerformUpdateViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}


- (void) viewWillAppear:(BOOL)animated {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"YYYY-MM-dd HH:mm:ss"];

    self.nameLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Name: %@", nil), self.firmware.name];
    self.versionLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Version: %@", nil), self.firmware.version];
    self.buildTimeLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Build time: %@", nil), [dateFormatter stringFromDate:self.firmware.buildTime]];
}


- (IBAction)downloadFirmware:(UIButton *)sender {
    NSLog( @"updating to firmware %@", self.firmware.name );

    // show a progress view
    self.inProgressAlert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Downloading firmware", nil)
                                                               message:NSLocalizedString(@"Downloading firmware data, please wait.", nil)
                                                        preferredStyle:UIAlertControllerStyleAlert];

    // when the dialog is up, then start downloading
    [self presentViewController:self.inProgressAlert animated:YES completion:^{
        // create a download task for downloading the index file
        NSURLSessionDataTask *downloadTask = [[NSURLSession sharedSession]
                                              dataTaskWithURL:self.firmware.url completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                                                  if ( error != nil ) {
                                                      NSLog( @"failed to download firmware index file");
                                                      [self showErrorMessage:NSLocalizedString(@"Failed to download firmware update data!", nil)];
                                                      return;
                                                  }

                                                  NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *) response;
                                                  if ( httpResponse == nil || httpResponse.statusCode != 200 ) {
                                                      if ( httpResponse ) {
                                                          NSLog( @"failed to download firmware index file, expected status 200, got: %ld", (long)httpResponse.statusCode );
                                                          [self showErrorMessage:[NSString stringWithFormat:NSLocalizedString(@"Failed to download firmware update data, status code: %ld", nil), (long)httpResponse.statusCode]];
                                                      }
                                                      else {
                                                          NSLog( @"failed to download firmware index file, no response" );
                                                          [self showErrorMessage:NSLocalizedString(@"Failed to download firmware update data, no response received!", nil)];
                                                      }

                                                      return;
                                                  }

                                                  NSLog( @"downloaded firmware, size: %lu bytes", (unsigned long)data.length);

                                                  // calculate the MD5 sum
                                                  NSString * md5Sum = [self md5:data];
                                                  if ( [self.firmware.md5 caseInsensitiveCompare:md5Sum] != NSOrderedSame ) {
                                                      NSLog( @"md5 sum mismatch, firmware: %@, calculated: %@", self.firmware.md5, md5Sum );
                                                      [self showErrorMessage:NSLocalizedString(@"Checksum mismatch on downloaded firmware!", nil)];
                                                      return;
                                                  }

                                                  self.firmwareData = data;
                                                  
                                                  NSLog( @"md5 sum ok, firmware: %@, calculated: %@", self.firmware.md5, md5Sum );
                                                  [self askForConfirmation];
                                              }];
        
        // start the download
        [downloadTask resume];
    }];
}


- (void) askForConfirmation {
    dispatch_async(dispatch_get_main_queue(), ^{
        // dismiss any old alert first
        if ( self.inProgressAlert ) {
            [self.inProgressAlert dismissViewControllerAnimated:YES completion:^{
                self.inProgressAlert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Confirm", nil)
                                                                           message:NSLocalizedString(@"Proceed with updating the firmware?", nil)
                                                                    preferredStyle:UIAlertControllerStyleAlert];
                UIAlertAction* proceedButton = [UIAlertAction
                                                actionWithTitle:NSLocalizedString(@"Proceed", nil)
                                                style:UIAlertActionStyleDefault
                                                handler:^(UIAlertAction * action) {
                                                    // user confirmed, proceed!
                                                    [self performUpdate];
                                                }];

                UIAlertAction* cancelButton = [UIAlertAction
                                                actionWithTitle:NSLocalizedString(@"Cancel", nil)
                                                style:UIAlertActionStyleCancel
                                                handler:nil];

                [self.inProgressAlert addAction:proceedButton];
                [self.inProgressAlert addAction:cancelButton];

                // when the dialog is up, then start downloading
                [self presentViewController:self.inProgressAlert animated:YES completion:nil];
            }];
        }
    });
}


- (void) performUpdate {
    NSLog( @"performing update" );

    // show a progress view
    self.inProgressAlert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Flashing firmware", nil)
                                                               message:NSLocalizedString(@"Flashing firmware it not yet implemented!", nil)
                                                        preferredStyle:UIAlertControllerStyleAlert];

    [self.inProgressAlert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Ok", nil)
                                                             style:UIAlertActionStyleDefault
                                                           handler:nil]];

    // when the dialog is up, then start downloading
    [self presentViewController:self.inProgressAlert animated:YES completion:nil];
}


- (void) showErrorMessage:(NSString *)message {
    dispatch_async(dispatch_get_main_queue(), ^{
        // dismiss any old alert first
        if ( self.inProgressAlert ) {
            [self.inProgressAlert dismissViewControllerAnimated:YES completion:nil];
            self.inProgressAlert = nil;
        }

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


- (NSString *) md5:(NSData *)input {
    // perform the MD5 digest
    unsigned char digest[16];
    CC_MD5( input.bytes, (unsigned int)input.length, digest );

    // convert to a hex string
    NSMutableString *output = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    for(int i = 0; i < CC_MD5_DIGEST_LENGTH; i++) {
        [output appendFormat:@"%02x", digest[i]];
    }
    
    return  output;
}

@end
