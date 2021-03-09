
#import "SelectReaderViewController.h"
#import "MainMenuViewController.h"
#import "ConnectionManager.h"
#import "ThemeManager.h"
#import "Log.h"

@interface SelectReaderViewController ()

@property (nonatomic, strong) NSMutableDictionary * rssiMap;
@property (nonatomic, strong) UIAlertController *   alert;
@property (nonatomic, strong) CBPeripheral *        shouldConnectTo;

@end


@implementation SelectReaderViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.navigationItem.title = [ThemeManager sharedInstance].theme.applicationTitle;

    // set up the theme
    [self setupTheme];

    // map for UUID -> RRSI
    self.rssiMap = [NSMutableDictionary dictionary];

    // not connecting to any reader yet
    self.shouldConnectTo = nil;
}


- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    // register for bluetooth events, this can safely be called several times
    [[Bluetooth sharedInstance] registerDelegate:self];

    // can we start scanning?
    if ( [Bluetooth sharedInstance].state == CBManagerStatePoweredOn ) {
        // bluetooth is on, start scanning
        [[Bluetooth sharedInstance] startScanning];
    }

    // make sure we don't have any stale data in case this view is reshown without being recreated
    [self.tableView reloadData];

    // if we have a current reader allow it to be disconnected
    if ( [ConnectionManager sharedInstance].currentReader ) {
        // we can disconnect
        self.disconnectButton.hidden = NO;
    }
    else {
        self.disconnectButton.hidden = YES;
    }
}


- (void) viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];

    // we no longer need bluetooth events
    [[Bluetooth sharedInstance] deregisterDelegate:self];

    // clear the selection on the table. This is done automatically by a UITableViewController, but we need to
    // do it manually as we're a UIViewContoller only
    NSIndexPath * selected = [self.tableView indexPathForSelectedRow];
    if ( selected ) {
        [self.tableView deselectRowAtIndexPath:selected animated:YES];
    }

    [[Bluetooth sharedInstance] stopScanning];
}


- (IBAction) disconnectFromReader {
    [[Bluetooth sharedInstance] disconnectFromReader];
}


/******************************************************************************************
 * Table view datasource
 **/
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger count = [Bluetooth sharedInstance].readers.count;
    return count;
}


/******************************************************************************************
 * Table view delegate
 **/
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier = @"ReaderCell";

    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];

    // get the associated reader
    CBPeripheral * reader = [Bluetooth sharedInstance].readers[ indexPath.row ];

    cell.textLabel.text = reader.name;

    // the detail is the RSSI
    NSNumber * rssi = self.rssiMap[ reader.identifier.UUIDString ];
    if ( rssi == nil ) {
        rssi = @0;
    }

    cell.detailTextLabel.text = [NSString stringWithFormat:NSLocalizedString(@"RSSI: %@", nil), rssi];
    return cell;
}


- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    Bluetooth * bt = [Bluetooth sharedInstance];
    ConnectionManager * cm = [ConnectionManager sharedInstance];

    // get the associated reader
    CBPeripheral * reader = bt.readers[ indexPath.row ];

    // connecting to the same reader we're already connected to?

    // BUG: if we don't allow to connect to the same reader we can be stuck with a non working reader. This can happen if the
    // user is too slow to respond to the pairing request
    if ( reader == cm.currentReader ) {
        logDebug( @"selected the same reader, we're done" );
        [self.navigationController popViewControllerAnimated:YES];
        return;
    }

    // if we have an alert we're already connecting somewhere, don't do it twice
    if ( self.alert ) {
        return;
    }

    // show a status popup that has no ok/cancel buttons, it's shown as long as the saving takes
    self.alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Connecting", nil)
                                                     message:[NSString stringWithFormat:NSLocalizedString(@"Connecting to reader %@", nil), reader.name]
                                              preferredStyle:UIAlertControllerStyleAlert];
    [self presentViewController:self.alert animated:YES completion:nil];

    // stop scanning
    [bt stopScanning];

    // are we connected to a previous reader?
    if ( cm.currentReader ) {
        // we should connect to this new reader only after the old was properly disconnected
        self.shouldConnectTo = reader;

        logDebug( @"disconnecting from previous reader: %@", cm.currentReader );
        [bt disconnectFromReader];
    }
    else {
        // no current reader, so connect directly
        logDebug( @"connecting to selected reader: %@", reader );
        self.shouldConnectTo = nil;
        [bt connectToReader:reader];
    }
}


/*****************************************************************************************************************
 * Bluetooth delegate callbacks
 * The callbacks do not necessaily come on the main thread, so make sure everything that touches the UI is done on
 * the main thread only.
 **/
- (void) bluetoothStateChanged:(CBManagerState)state {
    dispatch_async( dispatch_get_main_queue(), ^{
        logDebug( @"bluetooth state: %ld", (long)state );

        // only scan if powered on and not already scanning
        if ( state != CBManagerStatePoweredOn || [Bluetooth sharedInstance].isScanning ) {
            return;
        }

        logDebug( @"bluetooth turned on, starting scan" );
        [[Bluetooth sharedInstance] startScanning];
    });
}


- (void) readerFound:(CBPeripheral *)reader rssi:(NSNumber *)rssi{
    dispatch_async( dispatch_get_main_queue(), ^{
        logDebug( @"reader found: %@", reader );

        // save our RSSI
        self.rssiMap[ reader.identifier.UUIDString] = rssi;

        [self.tableView reloadData];
    });
}


- (void) readerDisconnected {
    logDebug( @"disconnect from reader completed" );

    dispatch_async( dispatch_get_main_queue(), ^{
        self.disconnectButton.hidden = YES;
    });

    // do we have a reader that we should connect to? this means that we have disconnected from a previous reader
    // and can now proceed to connect to the new reader
    if ( self.shouldConnectTo ) {
        logDebug( @"proceeding with connection to new reader: %@", self.shouldConnectTo );
        [[Bluetooth sharedInstance] connectToReader:self.shouldConnectTo];
        self.shouldConnectTo = nil;
    }
    else {
        // no reader and nothing to connect to, start scanning again
        [[Bluetooth sharedInstance] startScanning];
    }
}

/*- (void) reader:(CBPeripheral *)reader rssiUpdated:(NSNumber *)rssi {
    logDebug( @"reader: %@, rssi: %@", reader, rssi );

    // save the RSSI
    self.rssiMap[ reader.identifier.UUIDString] = rssi;
    [self.tableView reloadData];
}*/


- (void) readerConnectionOk {
    // now we have a proper connection to the reader
    dispatch_async( dispatch_get_main_queue(), ^{
        logDebug( @"connection ok" );

        // get rid of the status popup and wait for the alert to be dismissed before we pop ourselves away
        [self.alert dismissViewControllerAnimated:YES completion:^{
            self.alert = nil;
            [self.navigationController popViewControllerAnimated:YES];
        }];
    });
}


- (void) readerConnectionFailed {
    dispatch_async( dispatch_get_main_queue(), ^{
        logError( @"failed to connect to reader" );

        // first always get rid of the status popup and wait for the alert to be dismissed before we pop ourselves away
        [self.alert dismissViewControllerAnimated:YES completion:^{
            self.alert = nil;
            // show in an alert view
            UIAlertController * errorAlert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Error", nil)
                                                                                 message:NSLocalizedString(@"Failed to connect to reader", nil)
                                                                          preferredStyle:UIAlertControllerStyleAlert];

            UIAlertAction* okButton = [UIAlertAction
                                       actionWithTitle:@"Ok"
                                       style:UIAlertActionStyleDefault
                                       handler:^(UIAlertAction * action) {
                                           // nothing special to do right now
                                       }];


            [errorAlert addAction:okButton];
            [self presentViewController:errorAlert animated:YES completion:nil];
            
        }];
    } );
}

@end
