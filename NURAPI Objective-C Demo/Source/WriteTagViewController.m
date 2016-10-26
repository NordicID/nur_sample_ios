
#import "WriteTagViewController.h"
#import "WriteTagPopoverViewController.h"
#import "TagManager.h"


@implementation WriteTagViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    // TEST DATA
//    for ( unsigned char index = 0; index < 5; ++index ) {
//        unsigned char data[] = { index, 0x1, 0x2, 0x3, 0x4, 0x5, 0x6, 0x7, 0x8, 0x9, 0xa, 0xb };
//        NSData * epc = [NSData dataWithBytes:data length:12];
//        [[TagManager sharedInstance] addTag:[[Tag alloc] initWithEpc:epc frequency:0 rssi:0 scaledRssi:0 timestamp:0 channel:0 antennaId:0]];
//    }
}


-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"TagPopover"]) {
        WriteTagPopoverViewController *vc = [segue destinationViewController];
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
