
#import "WriteTagViewController.h"
#import "WriteTagPopoverViewController.h"
#import "TagManager.h"


@implementation WriteTagViewController

- (void)viewDidLoad {
    [super viewDidLoad];
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

//******************************************************************************************
#pragma mark - Write Tag Popover View Controller Delegate
- (void) writeCompletedWithError:(int)error {
    NSLog( @"tag writing completed with error: %d", error );

    NSString * title;
    NSString * message;

    // written ok?
    if ( error == NUR_NO_ERROR ) {
        // all ok
        title = @"Status";
        message = @"Tag written ok";

        // we have a changed tag, make sure it's shown
        [self.tableView reloadData];
    }
    else {
        // failed to write
        title = @"Failed to write tag";

        // extract the NURAPI error
        char buffer[256];
        NurApiGetErrorMessage( error, buffer, 256 );
        message = [NSString stringWithCString:buffer encoding:NSUTF8StringEncoding];

        NSLog( @"NURAPI error: %@", message );
    }

    // show in an alert view
    UIAlertController * alert = [UIAlertController alertControllerWithTitle:title
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

    cell.textLabel.text = tag.hex;

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
