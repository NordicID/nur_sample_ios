
#import "LocateViewController.h"
#import "LocateTagViewController.h"
#import "TagManager.h"
#import "Log.h"


@interface LocateViewController ()

@property (nonatomic, strong) dispatch_queue_t dispatchQueue;

@end


@implementation LocateViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    // set up the theme
    [self setupTheme];

    // set up the queue used to async any NURAPI calls
    self.dispatchQueue = dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0 );
}


- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    LocateTagViewController * destination = [segue destinationViewController];
    NSIndexPath *indexPath = [sender isKindOfClass:[NSIndexPath class]] ? (NSIndexPath*)sender : [self.tableView indexPathForSelectedRow];
    destination.tag = [TagManager sharedInstance].tags[ indexPath.row ];
}


- (IBAction)refreshInventory {
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

    // show a status popup that has no ok/cancel buttons, it's shown as long as the saving takes
    UIAlertController * inProgressAlert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Refreshing", nil)
                                                                              message:NSLocalizedString(@"Refreshing list of tags...", nil)
                                                                       preferredStyle:UIAlertControllerStyleAlert];
    [self presentViewController:inProgressAlert animated:YES completion:nil];

    // first clear all the tags
    [[TagManager sharedInstance] clear];
    [self.tableView reloadData];

    dispatch_async(self.dispatchQueue, ^{
        TagManager * tm = [TagManager sharedInstance];

        // perform a simple inventory round
        struct NUR_INVENTORY_RESPONSE inventoryResponse;
        int error = NurApiSimpleInventory( [Bluetooth sharedInstance].nurapiHandle, &inventoryResponse );
        if ( error != NUR_NO_ERROR ) {
            // extract the NURAPI error
            char buffer[256];
            NurApiGetErrorMessage( error, buffer, 256 );
            NSString * message = [NSString stringWithCString:buffer encoding:NSUTF8StringEncoding];

            // failed to do inventory, show error on UI thread
            dispatch_async( dispatch_get_main_queue(), ^{
                [inProgressAlert dismissViewControllerAnimated:YES completion:nil];
                [self showMessagePopup:message
                             withTitle:NSLocalizedString(@"Error", nil)
                           buttonTitle:NSLocalizedString(@"Ok", nil)];
            });

            return;
        }

        int tagsAdded;
        error = NurApiFetchTags( [Bluetooth sharedInstance].nurapiHandle, 1, &tagsAdded );

        logDebug( @"found %d tags, total in reader memory: %d, added: %d", inventoryResponse.numTagsFound, inventoryResponse.numTagsMem, tagsAdded );

        // fetch all tags
        for ( int index = 0; index < inventoryResponse.numTagsMem; ++index ) {
            Tag * tag = [tm getTag:index];
            if ( tag ) {
                [tm addTag:tag];
            }
        }

        // dismiss the alert
        dispatch_async(dispatch_get_main_queue(), ^{
            [inProgressAlert dismissViewControllerAnimated:YES completion:nil];
            [self.tableView reloadData];
        } );
    } );
}


- (void) showMessagePopup:(NSString *)message withTitle:(NSString *)title buttonTitle:(NSString *)buttonTitle {
    // show in an alert view
    UIAlertController * alert = [UIAlertController alertControllerWithTitle:title
                                                                    message:message
                                                             preferredStyle:UIAlertControllerStyleAlert];

    if ( buttonTitle ) {
        UIAlertAction* okButton = [UIAlertAction
                                   actionWithTitle:NSLocalizedString(@"Ok", nil)
                                   style:UIAlertActionStyleDefault
                                   handler:^(UIAlertAction * action) {
                                       // nothing special to do right now
                                   }];


        [alert addAction:okButton];
    }

    [self presentViewController:alert animated:YES completion:nil];
}


/******************************************************************************************
 * Table view datasource
 **/
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [TagManager sharedInstance].tags.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"LocateTagCell" forIndexPath:indexPath];

    // get the associated tag
    Tag * tag = [TagManager sharedInstance].tags[ indexPath.row ];

    NSString * hex = tag.hex;
    cell.textLabel.text = hex.length == 0 ? NSLocalizedString(@"<empty tag>", nil) : hex;

    return cell;
}


/******************************************************************************************
 * Table view delegate
 **/

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    Tag * tag = [TagManager sharedInstance].tags[ indexPath.row ];
    logDebug( @"selected tag: %@", tag );

    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    // is the tag too short to locate?
    if ( tag.epc.length == 0 ) {
        // too short tag
        UIAlertController * alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Error", nil)
                                                                        message:NSLocalizedString(@"The tag EPC length is 0, can not locate!", nil)
                                                                 preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction
                          actionWithTitle:@"Ok"
                          style:UIAlertActionStyleDefault
                          handler:^(UIAlertAction * action) {
                              // nothing special to do right now
                          }]];
        [self presentViewController:alert animated:YES completion:nil];
    }
    else {
        [self performSegueWithIdentifier:@"LocateTagSegue" sender:nil];
    }
}

@end
