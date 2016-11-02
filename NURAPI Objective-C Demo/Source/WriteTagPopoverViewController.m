
#import "WriteTagPopoverViewController.h"
#import "UIButton+BackgroundColor.h"

@interface WriteTagPopoverViewController ()

@property (nonatomic, strong) dispatch_queue_t dispatchQueue;

@end

@implementation WriteTagPopoverViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // set up the queue used to async any NURAPI calls
    self.dispatchQueue = dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0 );

    self.oldEpcLabel.text = self.writeTag.hex;
    self.epcEdit.text = self.writeTag.hex;
}


- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    [self.writeButton setBackgroundColor:[UIColor colorWithRed:246/255.0 green:139/255.0 blue:31/255.0 alpha:1.0] forState:UIControlStateNormal];
}


- (IBAction) performTagWriting {
    const char *chars = [self.epcEdit.text UTF8String];

    NSLog( @"writing new tag: %@", self.epcEdit.text );

    dispatch_async(self.dispatchQueue, ^{
        // convert the hex string like "112233..." to 12 bytes
        unsigned char newEpc[12];
        char byteChars[3] = {'\0','\0','\0'};

        int charIndex = 0, resultIndex = 0;
        while( charIndex < self.epcEdit.text.length ) {
            byteChars[0] = chars[charIndex++];
            byteChars[1] = chars[charIndex++];
            unsigned long wholeByte = strtoul(byteChars, NULL, 16);
            newEpc[resultIndex++] = wholeByte & 0xff;
        }

        // create a data container from the 12 bytes
        NSData * newEpcData = [NSData dataWithBytes:newEpc length:12];

        unsigned char * oldEpc = (unsigned char *)self.writeTag.epc.bytes;

        // mostly hardocded data, but named for ease of reading
        DWORD password = 0;
        BOOL secured = 0;
        DWORD epcBufferLen = 12;
        int newEpcBufferLen = 12;
        BYTE wrBank = 1;
        DWORD wrAddress = 2;

        // perform the real tag writing
        int error = NurApiWriteTagByEPC( [Bluetooth sharedInstance].nurapiHandle, password, secured, oldEpc, epcBufferLen, wrBank, wrAddress, newEpcBufferLen, newEpc );

        //BYTE buffer[256];
        //int error = NurApiReadTagByEPC( [Bluetooth sharedInstance].nurapiHandle, password, secured, oldEpc, epcBufferLen, 2, 0, 8, buffer);

        //struct NUR_TRIGGERREAD_DATA singleData;
        //int error = NurApiScanSingle( [Bluetooth sharedInstance].nurapiHandle, 1000, &singleData );

        NSLog( @"started tag write: error: %d", error );

        // show the error or update the button label on the main queue
        dispatch_async(dispatch_get_main_queue(), ^{
            if ( error != NUR_NO_ERROR ) {
                NSLog( @"failed to write tag" );
                [self showErrorMessage:error];
                return;
            }

            // write the data back to the tag
            self.writeTag.epc = newEpcData;
            self.oldEpcLabel.text = self.writeTag.hex;
        } );
    } );

    /*
    int NURAPICONV NurApiWriteTagByEPC(HANDLE hApi, DWORD passwd, BOOL secured, BYTE *epcBuffer, DWORD epcBufferLen, BYTE wrBank, DWORD wrAddress, int wrByteCount, BYTE *wrBuffer);

    missä

    hApi = API handle
    passwd, secured = 0 (ei käytetä salasanaa)
    epcBuffer = tämänhetkinen EPC
    epcBufferLen = 12
    wrBank = 1 (bank EPC)
    wrAddress = 2 (word i.e. 16-bit address; EPC alkaa bittiosoitteesta 32 eli word osoite 2, 32 / 16 = 2)
    wrByteCount = 12 (kirjoitettavan buffering eli uuden EPC:n mitta)
    wrBuffer = osoitin kirjoitettavaan data eli tässä uusi EPC
*/
}


- (void) showErrorMessage:(int)error {
    // extract the NURAPI error
    char buffer[256];
    NurApiGetErrorMessage( error, buffer, 256 );
    NSString * message = [NSString stringWithCString:buffer encoding:NSUTF8StringEncoding];

    NSLog( @"NURAPI error: %@", message );

    // show in an alert view
    UIAlertController * alert = [UIAlertController alertControllerWithTitle:@"Failed to write tag"
                                                                    message:message
                                                             preferredStyle:UIAlertControllerStyleAlert];

    UIAlertAction* okButton = [UIAlertAction
                               actionWithTitle:@"Ok"
                               style:UIAlertActionStyleDefault
                               handler:^(UIAlertAction * action) {
                                   // nothing special to do right now
                               }];


    [alert addAction:okButton];
    [self presentViewController:alert animated:YES completion:nil];
}


//******************************************************************************************
#pragma mark - Text field delegate

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    NSString *newString = [self.epcEdit.text stringByReplacingCharactersInRange:range withString:string];

    // the length must be 24
    if ( newString.length != 24 ) {
        self.epcEdit.textColor = [UIColor redColor];
        self.writeButton.enabled = NO;
        return YES;
    }

    // a set of non hex character
    NSCharacterSet* nonHex = [[NSCharacterSet characterSetWithCharactersInString: @"0123456789ABCDEFabcdef"] invertedSet];
    NSRange nonHexRange = [newString rangeOfCharacterFromSet: nonHex];
    BOOL isHex = (nonHexRange.location == NSNotFound);

    // are all chacacters hex?
    if ( ! isHex ) {
        self.epcEdit.textColor = [UIColor redColor];
        self.writeButton.enabled = NO;
        return YES;
    }

    // length is ok and all are hex
    self.epcEdit.textColor = [UIColor blackColor];
    self.writeButton.enabled = YES;
    return YES;
}

@end
