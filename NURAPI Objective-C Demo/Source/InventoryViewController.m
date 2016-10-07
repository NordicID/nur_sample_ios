
#import "InventoryViewController.h"
#import "Tag.h"
#import "TagViewController.h"
#import "UIButton+BackgroundColor.h"

@interface InventoryViewController ()
@property (nonatomic, strong) NSMutableSet *   foundTagIds;
@property (nonatomic, strong) NSMutableArray * foundTags;
@property (nonatomic, strong) dispatch_queue_t dispatchQueue;
@end


@implementation InventoryViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    // set up the queue used to async any NURAPI calls
    self.dispatchQueue = dispatch_queue_create("com.nordicid.bluetooth-demo.nurapi-queue", DISPATCH_QUEUE_SERIAL);

    self.foundTagIds = [NSMutableSet set];
    self.foundTags = [NSMutableArray array];
}


- (void)viewWillAppear:(BOOL)animated {
    [self.inventoryButton setBackgroundColor:[UIColor colorWithRed:246/255.0 green:139/255.0 blue:31/255.0 alpha:1.0] forState:UIControlStateNormal];
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


- (IBAction)toggleInventory:(UIButton *)sender {
    dispatch_async(self.dispatchQueue, ^{
        if ( NurApiIsInventoryStreamRunning( [Bluetooth sharedInstance].nurapiHandle ) ) {
            // update the button label on the main queue
            dispatch_async(dispatch_get_main_queue(), ^{
                self.inventoryButton.titleLabel.text = @"Start";
            } );

            int error = NurApiStopInventoryStream( [Bluetooth sharedInstance].nurapiHandle );
            if ( error != NUR_NO_ERROR ) {
                NSLog( @"failed to stop inventory stream" );
                [self showErrorMessage:error];
                return;
            }
        }
        else {
            NSLog( @"starting inventory stream" );

            // update the button label on the main queue
            dispatch_async(dispatch_get_main_queue(), ^{
                self.inventoryButton.titleLabel.text = @"Stop";
            } );

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
        }
    } );
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
    // get all tags
    for ( int index = 0; index < [self getTagCount]; ++index ) {
        Tag * tag = [self getTag:index];
        if ( tag && ! [self.foundTagIds containsObject:tag.hex ] ) {
            [self.foundTags addObject:tag];
            [self.foundTagIds addObject:tag.hex];

            NSLog( @"tag %lu found: %@\n", (unsigned long)self.foundTags.count, tag );

            self.tagsLabel.text = [NSString stringWithFormat:@"Tags found: %lu", (unsigned long)self.foundTags.count];

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
    UIAlertController * errorView = [UIAlertController alertControllerWithTitle:@"Error"
                                                                        message:message
                                                                 preferredStyle:UIAlertControllerStyleAlert];
    [self presentViewController:errorView animated:YES completion:nil];
}


- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    TagViewController * destination = [segue destinationViewController];
    NSIndexPath *indexPath = [sender isKindOfClass:[NSIndexPath class]] ? (NSIndexPath*)sender : [self.tableView indexPathForSelectedRow];

    destination.tag = self.foundTags[ indexPath.row ];
}



//******************************************************************************************
#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.foundTags.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"TagCell" forIndexPath:indexPath];

    // get the associated tag
    Tag * tag = self.foundTags[ indexPath.row ];

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
                    NSLog( @"stream stopped, tags found: %lu\n", (unsigned long)self.foundTags.count );
                    self.inventoryButton.titleLabel.text = @"Start";
                }
            });
        }
            break;

        default:
            break;
    }
}


@end
