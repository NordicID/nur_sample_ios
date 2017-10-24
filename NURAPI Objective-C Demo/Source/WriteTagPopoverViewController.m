
#import "WriteTagPopoverViewController.h"
#import "AudioPlayer.h"

@interface WriteTagPopoverViewController ()

@property (nonatomic, strong) dispatch_queue_t dispatchQueue;

@end

@implementation WriteTagPopoverViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    // set up the theme
    [self setupTheme];

    // set up the queue used to async any NURAPI calls
    self.dispatchQueue = dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0 );

    self.oldEpcLabel.text = self.writeTag.hex;
    self.epcEdit.text = self.writeTag.hex;
}


- (IBAction) performTagWriting {
    // data for the new tag
    const char *chars = [self.epcEdit.text cStringUsingEncoding:NSASCIIStringEncoding];
    unsigned int charCount = (unsigned int)strlen(chars); 
    unsigned int newEpcLength = charCount / 2;

    // play a short blip
    [[AudioPlayer sharedInstance] playSound:kBlep100ms];

    dispatch_async(self.dispatchQueue, ^{
        // copy the old characters to make sure they survive
        char oldChars[NUR_MAX_EPC_LENGTH];
        strncpy( oldChars, chars, NUR_MAX_EPC_LENGTH );

        // get the previous TX level so that we can restore it later. It should be at maximum when writing tags
        struct NUR_MODULESETUP setup;
        int error = NurApiGetModuleSetup( [Bluetooth sharedInstance].nurapiHandle, NUR_SETUP_TXLEVEL, &setup, sizeof(struct NUR_MODULESETUP) );
        if ( error != NUR_NO_ERROR ) {
            [self.delegate writeCompletedWithError:error];
            return;
        }

        int oldTxLevel = setup.txLevel;
        NSLog( @"current tx level: %d", oldTxLevel );

        // set the TX level to 0 (maximum)
        if ( setup.txLevel != 0 ) {
            setup.txLevel = 0;
            error = NurApiSetModuleSetup( [Bluetooth sharedInstance].nurapiHandle, NUR_SETUP_TXLEVEL, &setup, sizeof(struct NUR_MODULESETUP) );
            if ( error != NUR_NO_ERROR ) {
                [self.delegate writeCompletedWithError:error];
                return;
            }
        }

        // EPC buffer, filled with 0
        unsigned char newEpc[NUR_MAX_EPC_LENGTH];
        memset( newEpc, 0, NUR_MAX_EPC_LENGTH);

        // convert the hex string like "112233..." to bytes
        char byteChars[3] = {'\0','\0','\0'};
        int resultIndex = 0;
        for ( int charIndex = 0; charIndex < charCount; charIndex += 2 ) {
            byteChars[0] = oldChars[charIndex ];
            byteChars[1] = oldChars[charIndex + 1];
            unsigned long wholeByte = strtoul(byteChars, NULL, 16);
            newEpc[resultIndex++] = wholeByte & 0xff;
        }

        unsigned char * oldEpc = (unsigned char *)self.writeTag.epc.bytes;
        int oldEpcLength = (int)self.writeTag.epc.length;

//        for ( int index = 0; index < oldEpcLength; index++ ) {
//            NSLog( @"old %d = %d", index, oldEpc[index] );
//        }
//        for ( int index = 0; index < newEpcLength; index++ ) {
//            NSLog( @"new %d = %d", index, newEpc[index] );
//        }

        // mostly hardocded data, but named for ease of reading
        DWORD password = 0;
        BOOL secured = 0;

        NSLog( @"old length: %d", oldEpcLength );
        NSLog( @"new length: %d", newEpcLength );

        // perform the real tag writing
        error = NurApiWriteEPCByEPC([Bluetooth sharedInstance].nurapiHandle, password, secured, oldEpc, oldEpcLength, newEpc, newEpcLength);
        //error = NurApiWriteTagByEPC( [Bluetooth sharedInstance].nurapiHandle, password, secured, oldEpc, oldEpcLength, wrBank, wrAddress, paddedEpcLength + 2, newEpc );
        if ( error != NUR_NO_ERROR ) {
            NSLog( @"failed to write tag" );
            [self.delegate writeCompletedWithError:error];
            return;
        }

        // update the internal tag too
        self.writeTag.epc = [NSData dataWithBytes:newEpc length:newEpcLength];
        //NSLog( @"tag new epc: %@", self.writeTag.hex );

        // restore the TX level
        if ( setup.txLevel != oldTxLevel ) {
            setup.txLevel = oldTxLevel;
            NSLog( @"restoring previous tx level: %d", oldTxLevel );

            error = NurApiSetModuleSetup( [Bluetooth sharedInstance].nurapiHandle, NUR_SETUP_TXLEVEL, &setup, sizeof(struct NUR_MODULESETUP) );
            if ( error != NUR_NO_ERROR ) {
                [self.delegate writeCompletedWithError:error];
                return;
            }
        }

        // we're done, written ok
        NSLog( @"write and restore completed ok" );
        [self.delegate writeCompletedWithError:NUR_NO_ERROR];
    } );
}


//******************************************************************************************
#pragma mark - Text field delegate

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    NSString *newString = [self.epcEdit.text stringByReplacingCharactersInRange:range withString:string];

    // the length must be ]0..MAX_EPC] and divisible by 4 (s0 that the final bytes are divisible by 2)
    if ( newString.length == 0 || newString.length > NUR_MAX_EPC_LENGTH * 2 || newString.length % 4 != 0 ) {
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
