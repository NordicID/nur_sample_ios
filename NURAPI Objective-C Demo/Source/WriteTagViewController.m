
#import <NurAPIBluetooth/Bluetooth.h>

#import "WriteTagViewController.h"
#import "WriteTagPopoverViewController.h"
#import "TagManager.h"

@interface WriteTagViewController ()

@property (nonatomic, strong) dispatch_queue_t dispatchQueue;

@end


@implementation WriteTagViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    // set up the queue used to async any NURAPI calls
    self.dispatchQueue = dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0 );
}


-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"TagPopover"]) {
        WriteTagPopoverViewController *vc = [segue destinationViewController];
        vc.delegate = self;
        vc.modalPresentationStyle = UIModalPresentationPopover;
        vc.popoverPresentationController.delegate = self;

        // center the up arrow from the popover on the "Select tag" label
        vc.popoverPresentationController.sourceRect = self.promptLabel.bounds;

        // get the clicked tag and pass to the vc for writing
        vc.writeTag = [TagManager sharedInstance].tags[ self.tableView.indexPathForSelectedRow.row ];
    }
}


-(UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller {
    return UIModalPresentationNone;
}


- (IBAction)refreshInventory {
    // if we do not have a current reader then we're coming here before having connected one. Don't do any NurAPI calls
    // in that case
    if ( ! [Bluetooth sharedInstance].currentReader ) {
        // prompt the user to connect a reader
        [self showMessagePopup:NSLocalizedString(@"No RFID reader connected!", nil) withTitle:NSLocalizedString(@"Error", nil) buttonTitle:NSLocalizedString(@"Error", nil) completion:nil];
        return;
    }

    // first clear all the tags
    [[TagManager sharedInstance] clear];
    [self.tableView reloadData];

    dispatch_async(self.dispatchQueue, ^{
        TagManager * tm = [TagManager sharedInstance];

        // clear the tags from the reader too
        NurApiClearTags( [Bluetooth sharedInstance].nurapiHandle );

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
                [self showMessagePopup:message
                             withTitle:NSLocalizedString(@"Error", nil)
                           buttonTitle:NSLocalizedString(@"Ok", nil)
                            completion:nil];
            });
            return;
        }

        int tagsAdded;
        error = NurApiFetchTags( [Bluetooth sharedInstance].nurapiHandle, 1, &tagsAdded );

        NSLog( @"found %d tags, total in reader memory: %d, added: %d", inventoryResponse.numTagsFound, inventoryResponse.numTagsMem, tagsAdded );

        // fetch all tags
        for ( int index = 0; index < inventoryResponse.numTagsMem; ++index ) {
            Tag * tag = [tm getTag:index];
            if ( tag ) {
                [tm addTag:tag];
            }
        }

        // dismiss the alert
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.tableView reloadData];
        } );
    } );
}


//******************************************************************************************
#pragma mark - Write Tag Popover View Controller Delegate
- (void) writeCompletedWithError:(int)error {
    NSLog( @"tag writing completed with error: %d", error );

    dispatch_async(dispatch_get_main_queue(), ^{
        // dismiss the popover
        [self dismissViewControllerAnimated:YES completion:^{
            NSString * title;
            NSString * message;

            // written ok?
            if ( error == NUR_NO_ERROR ) {
                // all ok
                [self refreshInventory];
//                [self showMessagePopup:NSLocalizedString(@"Tag written ok", nil)
//                             withTitle:NSLocalizedString(@"Status", nil)
//                           buttonTitle:NSLocalizedString(@"Ok", nil)
//                            completion:^{
//                                // refresh automatically when done
//                                [self refreshInventory];
//                            }];
                // we have a changed tag, make sure it's shown
                //[self.tableView reloadData];
            }
            else {
                // failed to write
                title = NSLocalizedString(@"Failed to write tag", nil);

                // extract the NURAPI error
                char buffer[256];
                NurApiGetErrorMessage( error, buffer, 256 );
                message = [NSString stringWithCString:buffer encoding:NSUTF8StringEncoding];
                NSLog( @"NURAPI error: %@", message );

                [self showMessagePopup:message
                             withTitle:NSLocalizedString(@"Failed to write tag", nil)
                           buttonTitle:NSLocalizedString(@"Ok", nil)
                            completion:nil];
            }
        }];
    });
}


- (UIAlertController *) showMessagePopup:(NSString *)message withTitle:(NSString *)title buttonTitle:(NSString *)buttonTitle completion:(void (^ __nullable)(void))completion {
    // show in an alert view
    UIAlertController * alert = [UIAlertController alertControllerWithTitle:title
                                                                    message:message
                                                             preferredStyle:UIAlertControllerStyleAlert];

    if ( buttonTitle ) {
        UIAlertAction* button = [UIAlertAction
                                 actionWithTitle:buttonTitle
                                 style:UIAlertActionStyleDefault
                                 handler:^(UIAlertAction * action) {
                                     // nothing special to do right now
                                 }];
        [alert addAction:button];
    }

    NSLog( @"presenting %@ %@", title, message );
    [self presentViewController:alert animated:YES completion:completion];
    return alert;
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
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"WriteTagCell" forIndexPath:indexPath];

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
    NSLog( @"selected tag for writing: %@", tag );
}

@end
