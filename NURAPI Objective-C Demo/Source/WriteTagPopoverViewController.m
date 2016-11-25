
#import "WriteTagPopoverViewController.h"
#import "UIButton+BackgroundColor.h"
#import "AudioPlayer.h"

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
    // data for the new tag
    const char *chars = [self.epcEdit.text UTF8String];
    unsigned int newEpcLength = (unsigned int)self.epcEdit.text.length;

    NSLog( @"writing new tag: %@", self.epcEdit.text );

    // play a short blip
    [[AudioPlayer sharedInstance] playSound:kBlep100ms];

    dispatch_async(self.dispatchQueue, ^{
        // get the previous TX level so that we can restore it later. It should be at maximum when writing tags
        struct NUR_MODULESETUP setup;
        int error = NurApiGetModuleSetup( [Bluetooth sharedInstance].nurapiHandle, NUR_SETUP_TXLEVEL, &setup, sizeof(struct NUR_MODULESETUP) );
        if ( error != NUR_NO_ERROR ) {
            dispatch_async(dispatch_get_main_queue(), ^{
                NSLog( @"failed to get current tx level" );
                [self dismissViewControllerAnimated:YES completion:nil];
                [self.delegate writeCompletedWithError:error];
            } );

            return;
        }

        int oldTxLevel = setup.txLevel;
        NSLog( @"current tx level: %d", oldTxLevel );

        // set the TX level to 0 (maximum)
        setup.txLevel = 0;
        error = NurApiSetModuleSetup( [Bluetooth sharedInstance].nurapiHandle, NUR_SETUP_TXLEVEL, &setup, sizeof(struct NUR_MODULESETUP) );
        if ( error != NUR_NO_ERROR ) {
            dispatch_async(dispatch_get_main_queue(), ^{
                NSLog( @"failed to set new tx level" );
                [self dismissViewControllerAnimated:YES completion:nil];
                [self.delegate writeCompletedWithError:error];
            } );

            return;
        }


        // convert the hex string like "112233..." to 12 bytes
        unsigned char newEpc[NUR_MAX_EPC_LENGTH];
        char byteChars[3] = {'\0','\0','\0'};
        int charIndex = 0, resultIndex = 0;
        while( charIndex < newEpcLength ) {
            byteChars[0] = chars[charIndex++];
            byteChars[1] = chars[charIndex++];
            unsigned long wholeByte = strtoul(byteChars, NULL, 16);
            newEpc[resultIndex++] = wholeByte & 0xff;
        }

        unsigned char * oldEpc = (unsigned char *)self.writeTag.epc.bytes;
        int oldEpcLength = (int)self.writeTag.epc.length;

        // mostly hardocded data, but named for ease of reading
        DWORD password = 0;
        BOOL secured = 0;
        BYTE wrBank = 1;
        DWORD wrAddress = 2;

        NSLog( @"writing new tag" );

        // perform the real tag writing
        error = NurApiWriteTagByEPC( [Bluetooth sharedInstance].nurapiHandle, password, secured, oldEpc, oldEpcLength, wrBank, wrAddress, newEpcLength, newEpc );
        if ( error != NUR_NO_ERROR ) {
            dispatch_async(dispatch_get_main_queue(), ^{
                NSLog( @"failed to write tag" );
                [self dismissViewControllerAnimated:YES completion:nil];
                [self.delegate writeCompletedWithError:error];
            } );

            return;
        }

        // update the internal tag too
        self.writeTag.epc = [NSData dataWithBytes:newEpc length:newEpcLength];

        // restore the TX level
        setup.txLevel = oldTxLevel;
        NSLog( @"restoring previous tx level: %d", oldTxLevel );

        error = NurApiSetModuleSetup( [Bluetooth sharedInstance].nurapiHandle, NUR_SETUP_TXLEVEL, &setup, sizeof(struct NUR_MODULESETUP) );
        if ( error != NUR_NO_ERROR ) {
            dispatch_async(dispatch_get_main_queue(), ^{
                NSLog( @"failed to restore old tx level" );
                [self dismissViewControllerAnimated:YES completion:nil];
                [self.delegate writeCompletedWithError:error];
            } );

            return;
        }

        // we're done, written ok
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog( @"write and restore completed ok" );
            [self dismissViewControllerAnimated:YES completion:nil];
            [self.delegate writeCompletedWithError:NUR_NO_ERROR];
        } );
    } );
}


//******************************************************************************************
#pragma mark - Text field delegate

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    NSString *newString = [self.epcEdit.text stringByReplacingCharactersInRange:range withString:string];

    // the length must be ]0..MAX_EPC]
    if ( newString.length == 0 || newString.length > NUR_MAX_EPC_LENGTH * 2 || newString.length % 2 == 1 ) {
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


- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

@end
