

#import "InventoryViewController.h"
#import "AudioPlayer.h"
#import "Tagmanager.h"
#import "TagViewController.h"
#import "UIButton+BackgroundColor.h"

@interface InventoryViewController ()

@property (nonatomic, strong) dispatch_queue_t dispatchQueue;
@property (nonatomic, strong) NSTimer *        timer;
@property (nonatomic, strong) NSDate *         startTime;
@end


@implementation InventoryViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    // set up the queue used to async any NURAPI calls
    self.dispatchQueue = dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0 );
}


- (void)viewWillAppear:(BOOL)animated {
    [self.inventoryButton setBackgroundColor:[UIColor colorWithRed:246/255.0 green:139/255.0 blue:31/255.0 alpha:1.0] forState:UIControlStateNormal];
    [self.clearButton setBackgroundColor:[UIColor colorWithRed:246/255.0 green:139/255.0 blue:31/255.0 alpha:1.0] forState:UIControlStateNormal];
    [super viewWillAppear:animated];
}


- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    // register for bluetooth events
    [[Bluetooth sharedInstance] registerDelegate:self];
}


- (void) viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];

    // we no longer need bluetooth events
    [[Bluetooth sharedInstance] deregisterDelegate:self];
}


- (IBAction)toggleInventory {
    // if we do not have a current reader then we're coming here before having connected one. Don't do any NurAPI calls
    // in that case
    if ( ! [Bluetooth sharedInstance].currentReader ) {
        NSLog( @"no current reader connected, aborting inventory" );
        return;
    }

    dispatch_async(self.dispatchQueue, ^{
        if ( NurApiIsInventoryStreamRunning( [Bluetooth sharedInstance].nurapiHandle ) ) {
            // stop stream
            NSLog( @"stopping inventory stream" );
            
            int error = NurApiStopInventoryStream( [Bluetooth sharedInstance].nurapiHandle );
            if ( error != NUR_NO_ERROR ) {
                NSLog( @"failed to stop inventory stream" );
                [self showErrorMessage:error];
                return;
            }

            // update the button label on the main queue
            dispatch_async(dispatch_get_main_queue(), ^{
                self.inventoryButton.titleLabel.text = @"Start";

                if ( self.timer ) {
                    [self.timer invalidate];
                }

                self.timer = nil;
                self.startTime = nil;
            } );
        }
        else {
            NSLog( @"starting inventory stream" );

            // default scanning parameters
            int rounds = 0;
            int q = 0;
            int session = 0;

            int error = NurApiStartInventoryStream( [Bluetooth sharedInstance].nurapiHandle, rounds, q, session );
            if ( error != NUR_NO_ERROR ) {
                NSLog( @"failed to start inventory stream" );
                [self showErrorMessage:error];
                return;
            }

            // update the button label on the main queue
            dispatch_async(dispatch_get_main_queue(), ^{
                self.inventoryButton.titleLabel.text = @"Stop";
                // start a timer that updates the elapsed time
                self.timer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(updateLabels) userInfo:nil repeats:YES];
                self.startTime = [NSDate date];
            } );
        }
    } );
}


- (IBAction)clearInventory {
    // simply clear all the tags
    [[TagManager sharedInstance] clear];
    [self.tableView reloadData];

    // clear all labels
    self.tagsLabel.text = @"0";
    self.elapsedTimeLabel.text = @"unique tags in 0 seconds";
    self.averageTagsPerSecondLabel.text = @"0";
    self.tagsPerSecondLabel.text = @"0";
    self.maxTagsPerSecondLabel.text = @"0";
}


- (void) updateLabels {
    NSTimeInterval seconds;

    if ( self.startTime ) {
        seconds = -[self.startTime timeIntervalSinceNow];
    }
    else {
        seconds = 0;
    }

    // found tags
    self.tagsLabel.text = [NSString stringWithFormat:@"%lu", (unsigned long)[TagManager sharedInstance].tags.count];

    // elapsed time
    self.elapsedTimeLabel.text = [NSString stringWithFormat:@"unique tags in %.1f seconds", seconds];

    // average tags/s
    if ( seconds > 0 ) {
        double tagsPerSecond = (double)[TagManager sharedInstance].tags.count / seconds;
        self.averageTagsPerSecondLabel.text = [NSString stringWithFormat:@"%.1f", tagsPerSecond];
    }

}


- (int) getTagCount {
    int tagCount;
    int error = NurApiGetTagCount( [Bluetooth sharedInstance].nurapiHandle, &tagCount );
    if (error != NUR_NO_ERROR) {
        // failed to fetch tag count
        NSLog( @"failed to fetch tag count" );
        [self showErrorMessage:error];
        return -1;
    }

    return tagCount;
}


- (Tag *) getTag:(int)tagIndex {
    struct NUR_TAG_DATA tagData;
    int error = NurApiGetTagData( [Bluetooth sharedInstance].nurapiHandle, tagIndex, &tagData );
    if (error != NUR_NO_ERROR) {
        // failed to fetch tag
        [self showErrorMessage:error];
        return nil;
    }

    return [[Tag alloc] initWithEpc:[NSData dataWithBytes:tagData.epc length:tagData.epcLen]
                          frequency:tagData.freq
                               rssi:tagData.rssi
                         scaledRssi:tagData.scaledRssi
                          timestamp:tagData.timestamp
                            channel:tagData.channel
                          antennaId:tagData.antennaId];
}


- (void) tagFound {
    TagManager * tm = [TagManager sharedInstance];

    // get all tags
    for ( int index = 0; index < [self getTagCount]; ++index ) {
        Tag * tag = [self getTag:index];
        if ( tag ) {
            [tm addTag:tag];

//        }
//        && ! [self.foundTagIds containsObject:tag.hex ] ) {
//            [self.foundTags addObject:tag];
//            [self.foundTagIds addObject:tag.hex];

            NSLog( @"tag %lu found: %@\n", (unsigned long)tm.tags.count, tag );

            // play a short blip
            [[AudioPlayer sharedInstance] playSound:kBlep40ms];
            
            // update the table
            [self.tableView reloadData];
        }
    }
}


- (void) showErrorMessage:(int)error {
    // extract the NURAPI error
    char buffer[256];
    NurApiGetErrorMessage( error, buffer, 256 );
    NSString * message = [NSString stringWithCString:buffer encoding:NSUTF8StringEncoding];

    NSLog( @"NURAPI error: %@", message );

    // show in an alert view
    UIAlertController * alert = [UIAlertController alertControllerWithTitle:@"Error"
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


- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    TagViewController * destination = [segue destinationViewController];
    NSIndexPath *indexPath = [sender isKindOfClass:[NSIndexPath class]] ? (NSIndexPath*)sender : [self.tableView indexPathForSelectedRow];

    destination.tag = [TagManager sharedInstance].tags[ indexPath.row ];
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
    Tag * tag = [TagManager sharedInstance].tags[ indexPath.row ];

    cell.textLabel.text = tag.hex;

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
            NSLog( @"Tag data from inventory stream, tags added: %d %@", inventoryStream->tagsAdded, inventoryStream->stopped == TRUE ? @"stream stopped" : @"" );

            // run on the main thread
            dispatch_async(dispatch_get_main_queue(), ^{
                [self tagFound];

                // is the stream done?
                if ( inventoryStream->stopped == TRUE ) {
                    NSLog( @"stream stopped, tags found: %lu\n", (unsigned long)[TagManager sharedInstance].tags.count );
                    self.inventoryButton.titleLabel.text = @"Start";
                    if ( self.timer ) {
                        [self.timer invalidate];
                    }

                    self.timer = nil;
                    self.startTime = nil;
                    [self updateLabels];
                }
            });
        }
            break;

            // trigger pressed or released?
        case NUR_NOTIFICATION_IOCHANGE: {
            struct NUR_IOCHANGE_DATA *iocData = (struct NUR_IOCHANGE_DATA *)data;
            if (iocData->source == NUR_ACC_TRIGGER_SOURCE) {
                NSLog( @"trigger changed, dir: %d", iocData->dir );
                if (iocData->dir == 0) {
                    [self toggleInventory];
                }
            }
        }

        default:
            break;
    }
}


@end
