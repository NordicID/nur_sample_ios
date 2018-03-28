
#import "TagViewController.h"
#import "LocateTagViewController.h"
#import "Log.h"

@implementation TagViewController


- (IBAction) locateTag {
    // is the tag too short to locate?
    if ( self.tag.epc.length == 0 ) {
        // too short tag
        UIAlertController * alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Error", nil)
                                                                        message:NSLocalizedString(@"The tag EPC length is 0, can not locate!", nil)
                                                                 preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction
                          actionWithTitle:NSLocalizedString(@"Ok", nil)
                          style:UIAlertActionStyleDefault
                          handler:^(UIAlertAction * action) {
                              // nothing special to do right now
                          }]];
        [self presentViewController:alert animated:YES completion:nil];
    }
    else {
        [self performSegueWithIdentifier:@"LocateTagSegue2" sender:nil];
    }
}


- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    LocateTagViewController * destination = [segue destinationViewController];
    destination.tag = self.tag;
}


//******************************************************************************************
#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 9;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"TagCell" forIndexPath:indexPath];

    switch ( indexPath.row ) {
        case 0: {
            cell.textLabel.text = NSLocalizedString(@"Tag", nil);
            NSString * hex = self.tag.hex;
            cell.detailTextLabel.text = hex.length == 0 ? NSLocalizedString(@"<empty tag>", nil) : hex;
        }
            break;
            
        case 1:
            cell.textLabel.text = NSLocalizedString(@"Channel", nil);
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%d", self.tag.channel];
            break;

        case 2:
            cell.textLabel.text = NSLocalizedString(@"RSSI", nil);
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%d", self.tag.rssi];
            break;

        case 3:
            cell.textLabel.text = NSLocalizedString(@"Scaled RSSI", nil);
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%d", self.tag.scaledRssi];
            break;

        case 4:
            cell.textLabel.text = NSLocalizedString(@"Timestamp", nil);
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%d", self.tag.timestamp];
            break;

        case 5:
            cell.textLabel.text = NSLocalizedString(@"Frequency", nil);
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%d", self.tag.frequency];
            break;

        case 6:
            cell.textLabel.text = NSLocalizedString(@"Antenna Id", nil);
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%d", self.tag.antennaId];
            break;

        case 7:
            cell.textLabel.text = NSLocalizedString(@"Found count", nil);
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%d", self.tag.foundCount];
            break;

        case 8:
            logDebug( @"%d %d", self.tag.foundCount, self.rounds );
            cell.textLabel.text = NSLocalizedString(@"Found %", nil);
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%.0f", ((double)self.tag.foundCount / (double)self.rounds) * 100];
            break;
    }

    return cell;
}

@end
