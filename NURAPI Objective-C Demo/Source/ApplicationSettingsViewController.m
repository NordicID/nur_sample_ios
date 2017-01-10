
#import "ApplicationSettingsViewController.h"
#import "AudioPlayer.h"
#import "ConnectionManager.h"

enum {
    kSoundEnabled = 0,
    kAutomaticReconnectEnabled = 1,
} ApplicationSettingType;


@implementation ApplicationSettingsViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.parentViewController.navigationItem.title = @"Application Settings";
}


//******************************************************************************************
#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}


- (NSString *) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return @"Sounds enabled";
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 2;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    // populate the cell
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ApplicationSettingCell" forIndexPath:indexPath];

    switch ( indexPath.row ) {
        case kSoundEnabled:
            cell.textLabel.text = @"Application sounds";
            cell.accessoryType = [AudioPlayer sharedInstance].soundsEnabled ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
            break;

        case kAutomaticReconnectEnabled:
            cell.textLabel.text = @"Automatically reconnect";
            cell.accessoryType = [ConnectionManager sharedInstance].reconnectMode == kAlwaysReconnect ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
            break;
    }
    
    return cell;
}


- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if ( indexPath.row == kSoundEnabled ) {
        // toggle the sounds
        AudioPlayer * ap = [AudioPlayer sharedInstance];
        ap.soundsEnabled = ap.soundsEnabled ? NO : YES;
    }
    else if ( indexPath.row == kAutomaticReconnectEnabled ) {
        [ConnectionManager sharedInstance].reconnectMode = [ConnectionManager sharedInstance].reconnectMode == kAlwaysReconnect ? kNeverReconnect : kAlwaysReconnect;
    }
    else {
        return;
    }

    // refresh
    [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
}


@end
