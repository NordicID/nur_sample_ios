

#import "InventoryViewController.h"
#import "AudioPlayer.h"
#import "TagManager.h"
#import "TagViewController.h"
#import "AverageBuffer.h"
#import "UIViewController+ErrorMessage.h"

@interface InventoryViewController ()

@property (nonatomic, strong) dispatch_queue_t dispatchQueue;
@property (nonatomic, strong) dispatch_queue_t audioDispatchQueue;
@property (nonatomic, strong) NSTimer *        timer;
@property (nonatomic, strong) NSDate *         startTime;
@property (nonatomic, strong) AverageBuffer *  averageBuffer;
@property (nonatomic, assign) unsigned int     totalTagsRead;
@property (nonatomic, assign) double           tagsPerSecond;
@property (nonatomic, assign) double           averageTagsPerSecond;
@property (nonatomic, assign) double           maxTagsPerSecond;
@property (nonatomic, assign) unsigned int     inventoryRoundsDone;
@property (nonatomic, assign) NSUInteger       lastRoundUniqueTags;
@property (nonatomic, assign) NSTimeInterval   elapsedSeconds;

@end


#define TAGS_PER_SEC_OVERTIME 2.0

@implementation InventoryViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    // set up the theme
    [self setupTheme];

    // clear all statistics
    [self clearData];

    // set up the queue used to async any NURAPI calls
    self.dispatchQueue = dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0 );
    self.audioDispatchQueue = dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_LOW, 0 );

    // initially the share button is hidden, nothing to share
    self.shareButton.enabled = NO;

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appMovedToForeground) name:UIApplicationWillEnterForegroundNotification object:nil];
}


- (void) appMovedToForeground {
    // fix the button to have the correct text in case the user has left the view and come back
    dispatch_async(self.dispatchQueue, ^{
        BOOL isStreamRunning = NurApiIsInventoryStreamRunning( [Bluetooth sharedInstance].nurapiHandle );
        dispatch_async(dispatch_get_main_queue(), ^{
            if ( isStreamRunning ) {
                [self.inventoryButton setTitle:NSLocalizedString(@"Stop", nil) forState:UIControlStateNormal];
            }
            else {
                [self.inventoryButton setTitle:NSLocalizedString(@"Start", nil) forState:UIControlStateNormal];
            }
        });
    });
}


- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    // register for bluetooth events
    [[Bluetooth sharedInstance] registerDelegate:self];

}


- (void) viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];

    // always re-enable the idle timer when we leave
    [UIApplication sharedApplication].idleTimerDisabled = YES;

    // we no longer need bluetooth events
    [[Bluetooth sharedInstance] deregisterDelegate:self];

    // make sure no stream is running when we leave the view
    if ( [Bluetooth sharedInstance].currentReader ) {
        dispatch_async(self.dispatchQueue, ^{
            [self stopStream];
        } );
    }
}


- (void) clearData {
    self.averageBuffer = [[AverageBuffer alloc] initWithMaxSize:1000 maxAge:TAGS_PER_SEC_OVERTIME];
    self.totalTagsRead = 0;
    self.tagsPerSecond = 0;
    self.averageTagsPerSecond = 0;
    self.maxTagsPerSecond = 0;
    self.inventoryRoundsDone = 0;
    self.elapsedSeconds = 0;
    self.lastRoundUniqueTags = 0;
}


- (IBAction)shareInventory:(UIBarButtonItem *)sender {
    logDebug( @"in" );

    // DEBUG: fill the tag storage with lots of tags to test sharing large collections
    /*for ( int index = 0; index < 10000; index++) {
        @autoreleasepool {
        unsigned char epcBytes[2]; // = { 0x0, 0x1, 0x2, 0x3, 0x4, 0x5, 0x6, 0x7, 0x8, 0x9 };
        epcBytes[0] = index & 0xff;
        epcBytes[1] = (index >> 8) & 0xff;
        NSData * epc = [NSData dataWithBytes:epcBytes length:10];
        Tag * tag = [[Tag alloc] initWithEpc:epc frequency:10000 rssi:-50 scaledRssi:-45 timestamp:12345 channel:1 antennaId:2];
        [[TagManager sharedInstance] addTag:tag];
        }
    }*/

    NSString * content = @"";

    NSDateFormatter * dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"YYYY-MM-dd HH:mm:ss"];

    [[TagManager sharedInstance] lock];

    // create a CSV string with one tag per line
    for ( Tag * tag in [TagManager sharedInstance].tags ) {
        @autoreleasepool {
            content = [content stringByAppendingFormat:@"%@,%@,%@,%d\n",
                       [dateFormatter stringFromDate:tag.firstFound],
                       [dateFormatter stringFromDate:tag.lastFound],
                       tag.hex,
                       (int)tag.rssi];
        }
    }

    [[TagManager sharedInstance] unlock];

    // save to a temporary file
    NSString * filename = [NSString stringWithFormat:@"Inventory %@.csv", [dateFormatter stringFromDate:[NSDate date]]];
    NSURL *tmpDirURL = [NSURL fileURLWithPath:NSTemporaryDirectory() isDirectory:YES];
    NSURL *fileURL = [tmpDirURL URLByAppendingPathComponent:filename];

    NSError * error = nil;
    [content writeToURL:fileURL atomically:YES encoding:NSUTF8StringEncoding error:&error];
    if ( error != nil ) {
        // failed to save the content to a temporary file
        logError( @"failed to save CSV file: %@", error.localizedDescription );
        return;
    }

    logDebug( @"saved CSV to: %@", fileURL );

    // set up the activity controller for sharing a single URL
    NSArray* sharedObjects = [NSArray arrayWithObjects:fileURL, nil];
    UIActivityViewController *activityViewController = [[UIActivityViewController alloc]
                                                        initWithActivityItems:sharedObjects applicationActivities:nil];

    activityViewController.popoverPresentationController.barButtonItem = self.shareButton;

    // when the activity is completed delete the temporary file
    activityViewController.completionWithItemsHandler = ^(NSString *activityType, BOOL completed, NSArray *returnedItems, NSError *activityError) {
        logDebug(@"activity: %@ - finished flag: %d", activityType, completed);
        [[NSFileManager defaultManager] removeItemAtURL:fileURL error:nil];

        // show an error if there was one
        if ( activityError != nil ) {
            UIAlertController * alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Error Sharing CSV File", nil)
                                                                            message:activityError.localizedDescription
                                                                     preferredStyle:UIAlertControllerStyleAlert];

            UIAlertAction* okButton = [UIAlertAction
                                       actionWithTitle:NSLocalizedString(@"Ok", nil)
                                       style:UIAlertActionStyleDefault
                                       handler:^(UIAlertAction * action) {
                                           // nothing special to do right now
                                       }];


            [alert addAction:okButton];
            [self presentViewController:alert animated:YES completion:nil];
        }
    };

    [self presentViewController:activityViewController animated:true completion:nil];
}


- (IBAction)toggleInventory {
    // if we do not have a current reader then we're coming here before having connected one. Don't do any NurAPI calls
    // in that case
    if ( ! [Bluetooth sharedInstance].currentReader ) {
        // prompt the user to connect a reader
        UIAlertController * alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Error", nil)
                                                                        message:NSLocalizedString(@"No RFID reader connected!", nil)
                                                                 preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction
                          actionWithTitle:NSLocalizedString(@"Ok", nil)
                          style:UIAlertActionStyleDefault
                          handler:^(UIAlertAction * action) {
                              // nothing special to do right now
                          }]];
        [self presentViewController:alert animated:YES completion:nil];
        return;
    }

    // kill any old timer
    if ( self.timer ) {
        [self.timer invalidate];
        self.timer = nil;
    }

    dispatch_async(self.dispatchQueue, ^{
        if ( NurApiIsInventoryStreamRunning( [Bluetooth sharedInstance].nurapiHandle ) ) {
            [self stopStream];
        }
        else {
            [self startStream];
        }
    } );
}


/**
 * Used to test a case where an EXA51 was crashing with these particular parameters,
 **/
- (void) hardcodedTest {
    BYTE sMask[112];
    BYTE rdBuffer[192];
   int error = NurApiReadSingulatedTag32( [Bluetooth sharedInstance].nurapiHandle,
                                         0, //DWORD passwd,
                                         0, //BOOL secured,
                                         1, //BYTE sBank,
                                         32, //DWORD sAddress,
                                         112, //int sMaskBitLength,
                                         sMask, //BYTE *sMask,
                                         3, //BYTE rdBank,
                                         0, //DWORD rdAddress,
                                         192, //int rdByteCount,
                                         rdBuffer //BYTE *rdBuffer
                                         );

    logDebug( @"hardcodedTest: error: %d", error );

    // show the error or update the button label on the main queue
    dispatch_async(dispatch_get_main_queue(), ^{
        if ( error != NUR_NO_ERROR ) {
            logError( @"failed to start inventory stream" );
            [self showNurApiErrorMessage:error];
            return;
        }
    } );
}


- (void) startStream {
    logDebug( @"starting inventory stream" );

    // fetch module setup and set the NUR_OPFLAGS_INVSTREAM_ZEROS op flag. This makes the module
    // also report zero tag inventory rounds and makes the audio beeps work nicer
    struct NUR_MODULESETUP setup;
    int error = NurApiGetModuleSetup( [Bluetooth sharedInstance].nurapiHandle, NUR_SETUP_OPFLAGS, &setup, sizeof(struct NUR_MODULESETUP) );
    if ( error != NUR_NO_ERROR ) {
        logError( @"failed to get module setup for setting op flags" );
        return;
    }

    setup.opFlags |= NUR_OPFLAGS_INVSTREAM_ZEROS;

    error = NurApiSetModuleSetup( [Bluetooth sharedInstance].nurapiHandle, NUR_SETUP_OPFLAGS, &setup, sizeof(struct NUR_MODULESETUP) );
    if ( error != NUR_NO_ERROR ) {
        logError( @"failed to set module setup setting for op flags" );
        return;
    }


    // default scanning parameters
    int rounds = 0;
    int q = 0;
    int session = 0;
    error = NurApiStartInventoryStream( [Bluetooth sharedInstance].nurapiHandle, rounds, q, session );

    // show the error or update the button label on the main queue
    dispatch_async(dispatch_get_main_queue(), ^{
        if ( error != NUR_NO_ERROR ) {
            logError( @"failed to start inventory stream" );
            [self showNurApiErrorMessage:error];
            return;
        }

        // disable the idle timer, ie screen saver while the stream is running
        [UIApplication sharedApplication].idleTimerDisabled = YES;

        // clear all statistics data as we now started again
        [self clearData];

        [self.inventoryButton setTitle:NSLocalizedString(@"Stop", nil) forState:UIControlStateNormal];

        // no sharing while we're doing an inventory
        self.shareButton.enabled = NO;

        // start a timer that updates the elapsed time
        self.timer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(updateLabels) userInfo:nil repeats:YES];
        self.startTime = [NSDate date];

        /**
         * Set up a background task for playing "beep" sounds as long as we're running an inventory stream.
         * Unique tags will trigger a beep and more tags give more urgent beeps.
         **/
        if ( [AudioPlayer sharedInstance].soundsEnabled ) {
            dispatch_async( self.audioDispatchQueue, ^(void) {
                while ( self.timer ) {
                    NSTimeInterval sleepTime = 0.01;

                    // if we have unique tags then play a sound and sleep as long as the sound plays
                    if ( self.lastRoundUniqueTags > 0 ) {
                        sleepTime = 100 - self.lastRoundUniqueTags;

                        // sleep at least 40 ms
                        if (sleepTime < 40) {
                            sleepTime = 40;
                        }

                        sleepTime /= 1000.0;

                        // play the real sound
                        [[AudioPlayer sharedInstance] playSound:kBlep40ms];
                    }
                    
                    [NSThread sleepForTimeInterval:sleepTime];
                }
            } );
        }
    } );
}


- (void) stopStream {
    // precautions
    if ( ! NurApiIsInventoryStreamRunning( [Bluetooth sharedInstance].nurapiHandle ) ) {
        return;
    }

    // stop stream
    logDebug( @"stopping inventory stream" );

    int error = NurApiStopInventoryStream( [Bluetooth sharedInstance].nurapiHandle );

    // show the error or update the button label on the main queue
    dispatch_async(dispatch_get_main_queue(), ^{
        // re-enable the idle timer for the screen saver
        [UIApplication sharedApplication].idleTimerDisabled = YES;

        if ( error != NUR_NO_ERROR ) {
            logError( @"failed to stop inventory stream" );
            [self showNurApiErrorMessage:error];
            return;
        }

        [self.inventoryButton setTitle:NSLocalizedString(@"Start", nil) forState:UIControlStateNormal];
        self.startTime = nil;

        if ( self.timer ) {
            [self.timer invalidate];
            self.timer = nil;
        }

        // do we have any tags?
        if ( [TagManager sharedInstance].tags.count > 0 ) {
            logDebug( @"enabling sharing button" );
            self.shareButton.enabled = YES;
        }
    } );
}


- (void) continueStream {
    logDebug( @"continuing stream" );

    // default scanning parameters
    int rounds = 0;
    int q = 0;
    int session = 0;

    int error = NurApiStartInventoryStream( [Bluetooth sharedInstance].nurapiHandle, rounds, q, session );

    // show the error or update the button label on the main queue
    dispatch_async(dispatch_get_main_queue(), ^{
        if ( error != NUR_NO_ERROR ) {
            logError( @"failed to start inventory stream" );
            [self showNurApiErrorMessage:error];
            return;
        }
    } );
}


- (IBAction)clearInventory {
    // simply clear all the tags
    [[TagManager sharedInstance] clear];
    [self.tableView reloadData];

    // and all statistics
    [self clearData];

    // clear all labels
    self.tagsLabel.text = @"0";
    self.elapsedTimeLabel.text = NSLocalizedString(@"unique tags in 0 seconds", nil);
    self.averageTagsPerSecondLabel.text = @"0";
    self.tagsPerSecondLabel.text = @"0";
    self.maxTagsPerSecondLabel.text = @"0";
}


- (void) updateLabels {
    // if we have a timer running then update the elapsed seconds. if not we use the last value
/*    if ( self.startTime ) {
        self.elapsedSeconds = -[self.startTime timeIntervalSinceNow];
    }*/

    // found tags
    self.tagsLabel.text = [NSString stringWithFormat:@"%lu", (unsigned long)[TagManager sharedInstance].tags.count];

    self.elapsedTimeLabel.text = [NSString stringWithFormat:NSLocalizedString(@"unique tags in %.1f seconds", nil), self.elapsedSeconds];
    self.tagsPerSecondLabel.text = [NSString stringWithFormat:@"%.1f", self.tagsPerSecond];
    self.averageTagsPerSecondLabel.text = [NSString stringWithFormat:@"%.1f", self.averageTagsPerSecond];
    self.maxTagsPerSecondLabel.text = [NSString stringWithFormat:@"%.1f", self.maxTagsPerSecond];
}


- (void) tagsFound:(NSArray *)tags added:(int)tagsAdded {
    // do we need to update the table?
    if ( tags.count > 0 ) {
        [self.tableView reloadData];
    }

    [self.averageBuffer add:tagsAdded];

    self.totalTagsRead += tagsAdded;

    self.tagsPerSecond = self.averageBuffer.sumValue / TAGS_PER_SEC_OVERTIME;

    // the shown elapsed time is only incremented when tags are found
    if ( tags.count > 0 ) {
        self.elapsedSeconds = -[self.startTime timeIntervalSinceNow];
    }

    // TODO: is this the above "stopping elapsed seconds" or a real time since the start (as below)?
    NSTimeInterval elapsedSeconds = -[self.startTime timeIntervalSinceNow];

    if ( elapsedSeconds > 1 ) {
        self.averageTagsPerSecond = self.totalTagsRead / elapsedSeconds;
    }
    else {
        self.averageTagsPerSecond = self.tagsPerSecond;
    }

    if ( self.tagsPerSecond > self.maxTagsPerSecond ) {
        self.maxTagsPerSecond = self.tagsPerSecond;
    }

    logDebug( @"added tags: %lu, total: %lu", (unsigned long)tags.count, (unsigned long)[TagManager sharedInstance].tags.count );
}


- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // stop the stream first, no reasont to run the stream behind the scenes
    [self stopStream];

    TagViewController * destination = [segue destinationViewController];
    NSIndexPath *indexPath = [sender isKindOfClass:[NSIndexPath class]] ? (NSIndexPath*)sender : [self.tableView indexPathForSelectedRow];

    [[TagManager sharedInstance] lock];
    destination.tag = [TagManager sharedInstance].tags[ indexPath.row ];
    [[TagManager sharedInstance] unlock];

    destination.rounds = self.inventoryRoundsDone;
    logDebug( @"rounds: %d", self.inventoryRoundsDone );
}



//******************************************************************************************
#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [TagManager sharedInstance].tags.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"TagCell" forIndexPath:indexPath];

    // get the associated tag
    [[TagManager sharedInstance] lock];
    Tag * tag = [TagManager sharedInstance].tags[ indexPath.row ];
    [[TagManager sharedInstance] unlock];

    NSString * hex = tag.hex;
    cell.textLabel.text = hex.length == 0 ? NSLocalizedString(@"<empty tag>", nil) : hex;
    cell.detailTextLabel.text = [NSString stringWithFormat:NSLocalizedString(@"RSSI: %d", nil), tag.rssi];
    
    return cell;
}


//******************************************************************************************
#pragma mark - Table view delegate

- (void) tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
    [self performSegueWithIdentifier:@"ShowTagSegue" sender:indexPath];
}


//*****************************************************************************************************************
#pragma mark - Bluetooth delegate

- (void) notificationReceived:(DWORD)timestamp type:(int)type data:(LPVOID)data length:(int)length {
    switch ( type ) {
        case NUR_NOTIFICATION_INVENTORYSTREAM: {
            const struct NUR_INVENTORYSTREAM_DATA *inventoryStream = (const struct NUR_INVENTORYSTREAM_DATA *)data;
            logDebug( @"tag data from inventory stream, tags added: %d", inventoryStream->tagsAdded);

            self.inventoryRoundsDone += inventoryStream->roundsDone;

            // lock the tag storage
            int error = NurApiLockTagStorage( [Bluetooth sharedInstance].nurapiHandle, TRUE);
            if (error != NUR_NO_ERROR) {
                logError( @"failed to lock tag storage" );
                return;
            }

            // get the number of tags in the tag storage
            int tagCount;
            error = NurApiGetTagCount( [Bluetooth sharedInstance].nurapiHandle, &tagCount );
            if (error != NUR_NO_ERROR) {
                logError( @"failed to fetch tag count" );

                // unlock and abort
                NurApiLockTagStorage( [Bluetooth sharedInstance].nurapiHandle, FALSE);
                return;
            }

            // if no tags then we're done here
            if ( tagCount == 0 ) {
                error = NurApiLockTagStorage( [Bluetooth sharedInstance].nurapiHandle, FALSE);
                if (error != NUR_NO_ERROR) {
                    logError( @"failed to unlock tag storage" );
                }

                return;
            }

            // fetch all tags at the same time into an allocated buffer
            struct NUR_TAG_DATA_EX * tagDataBuffer = (struct NUR_TAG_DATA_EX *)malloc(tagCount * sizeof(struct NUR_TAG_DATA_EX));
            error = NurApiGetAllTagDataEx([Bluetooth sharedInstance].nurapiHandle, tagDataBuffer, &tagCount, sizeof(struct NUR_TAG_DATA_EX));
            if (error != NUR_NO_ERROR) {
                logError( @"failed to fetch all tags from tag storage" );

                // unlock and abort
                NurApiLockTagStorage( [Bluetooth sharedInstance].nurapiHandle, FALSE);
                return;
            }

            logDebug( @"fetched %d tags from tag storage", tagCount);

            // clear the tags
            error = NurApiClearTags( [Bluetooth sharedInstance].nurapiHandle );
            if (error != NUR_NO_ERROR) {
                logError( @"failed to clear read tags from tag storage" );
            }

            error = NurApiLockTagStorage( [Bluetooth sharedInstance].nurapiHandle, FALSE);
            if (error != NUR_NO_ERROR) {
                logError( @"failed to unlock tag storage" );
            }

            NSMutableArray * newTags = [NSMutableArray new];
            TagManager * tm = [TagManager sharedInstance];

            // fetch all new tags
            for ( int index = 0; index < tagCount; ++index ) {
                struct NUR_TAG_DATA_EX tagData = tagDataBuffer[index];
                Tag * tag =  [[Tag alloc] initWithEpc:[NSData dataWithBytes:tagData.epc length:tagData.epcLen]
                                            frequency:tagData.freq
                                                 rssi:tagData.rssi
                                           scaledRssi:tagData.scaledRssi
                                            timestamp:tagData.timestamp
                                              channel:tagData.channel
                                            antennaId:tagData.antennaId];

                BOOL isTagNew = [tm addTag:tag];

                // play a short blip if the tag was new
                if ( isTagNew ) {
                    [newTags addObject:tag];
                    logDebug( @"found new tag: %@", tag );
                }
            }

            // did the stream stop by itself? it will stop after 25 seconds or so, but keep it running
            if ( inventoryStream->stopped ) {
                [self continueStream];
            }

            // save the number of unique tags for the audio thread
            self.lastRoundUniqueTags = newTags.count;

            // run on the main thread
            dispatch_async(dispatch_get_main_queue(), ^{
                [self tagsFound:newTags added:inventoryStream->tagsAdded];
            });
        }
            break;

            // trigger pressed or released?
        case NUR_NOTIFICATION_IOCHANGE: {
            struct NUR_IOCHANGE_DATA *iocData = (struct NUR_IOCHANGE_DATA *)data;
            if (iocData->source == NUR_ACC_TRIGGER_SOURCE) {
                logDebug( @"trigger changed, dir: %d", iocData->dir );
                if (iocData->dir == 0) {
                    [self toggleInventory];
                }
            }
        }
            break;

        default:
            break;
    }
}


@end
