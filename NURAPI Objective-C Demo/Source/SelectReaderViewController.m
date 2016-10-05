
#import "SelectReaderViewController.h"
#import "ReaderViewController.h"

@implementation SelectReaderViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}


- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    // are we connected to a previous reader?
    if ( [Bluetooth sharedInstance].currentReader ) {
        [[Bluetooth sharedInstance] disconnectFromReader];
    }
    
    // register for bluetooth events, this can safely be called several times
    [[Bluetooth sharedInstance] registerDelegate:self];
}


- (void) viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];

    // we no longer need bluetooth events
    [[Bluetooth sharedInstance] deregisterDelegate:self];
}


- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    ReaderViewController * destination = [segue destinationViewController];
    destination.reader = [Bluetooth sharedInstance].readers[ self.tableView.indexPathForSelectedRow.row ];
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

- (NSString *) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return @"Available readers";
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier = @"ReaderCell";

    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];

    // get the associated reader
    CBPeripheral * reader = [Bluetooth sharedInstance].readers[ indexPath.row ];

    cell.textLabel.text = reader.name;
    cell.detailTextLabel.text = reader.identifier.UUIDString;
    return cell;
}


- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // get the associated reader
    CBPeripheral * reader = [Bluetooth sharedInstance].readers[ indexPath.row ];
    NSLog( @"connecting to reader: %@", reader );
    [[Bluetooth sharedInstance] connectToReader:reader];
}


/*****************************************************************************************************************
 * Bluetooth delegate callbacks
 * The callbacks do not necessaily come on the main thread, so make sure everything that touches the UI is done on
 * the main thread only.
 **/
- (void) bluetoothTurnedOn {
    dispatch_async( dispatch_get_main_queue(), ^{
        NSLog( @"bluetooth turned on" );
        [[Bluetooth sharedInstance] startScanning];
        self.statusLabel.text = @"Scanning for readers...";
    });
}


- (void) readerFound:(CBPeripheral *)reader {
    dispatch_async( dispatch_get_main_queue(), ^{
        NSLog( @"reader found: %@", reader );
        [self.tableView reloadData];
    });
}


- (void) readerConnectionOk {
    dispatch_async( dispatch_get_main_queue(), ^{
        NSLog( @"connection ok" );
        // now we can show the reader view controller
        [self performSegueWithIdentifier:@"ShowReaderSegue" sender:nil];
    });
}


- (void) readerConnectionFailed {
    dispatch_async( dispatch_get_main_queue(), ^{
        NSLog( @"connection failed" );
    });
}


@end
