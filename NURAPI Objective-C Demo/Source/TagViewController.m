
#import "TagViewController.h"
#import "LocateTagViewController.h"
#import "UIButton+BackgroundColor.h"

@implementation TagViewController

- (void)viewWillAppear:(BOOL)animated {
    [self.locateTagButton setBackgroundColor:[UIColor colorWithRed:246/255.0 green:139/255.0 blue:31/255.0 alpha:1.0] forState:UIControlStateNormal];
    [super viewWillAppear:animated];
}


- (IBAction) locateTag {
    // is the tag too short to locate?
    if ( self.tag.epc.length == 0 ) {
        // too short tag
        UIAlertController * alert = [UIAlertController alertControllerWithTitle:@"Error"
                                                                        message:@"The tag EPC length is 0, can not locate!"
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
            cell.textLabel.text = @"Tag";
            NSString * hex = self.tag.hex;
            cell.detailTextLabel.text = hex.length == 0 ? @"<empty tag>" : hex;
        }
            break;
            
        case 1:
            cell.textLabel.text = @"Channel";
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%d", self.tag.channel];
            break;

        case 2:
            cell.textLabel.text = @"RSSI";
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%d", self.tag.rssi];
            break;

        case 3:
            cell.textLabel.text = @"Scaled RSSI";
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%d", self.tag.scaledRssi];
            break;

        case 4:
            cell.textLabel.text = @"Timestamp";
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%d", self.tag.timestamp];
            break;

        case 5:
            cell.textLabel.text = @"Frequency";
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%d", self.tag.frequency];
            break;

        case 6:
            cell.textLabel.text = @"Antenna Id";
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%d", self.tag.antennaId];
            break;

        case 7:
            cell.textLabel.text = @"Found count";
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%d", self.tag.foundCount];
            break;

        case 8:
            NSLog( @"%d %d", self.tag.foundCount, self.rounds );
            cell.textLabel.text = @"Found %";
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%.0f", ((double)self.tag.foundCount / (double)self.rounds) * 100];
            break;
    }

    return cell;
}

@end
