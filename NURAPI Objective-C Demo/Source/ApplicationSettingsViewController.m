
#import "ApplicationSettingsViewController.h"
#import "AudioPlayer.h"
#import "ConnectionManager.h"
#import "Firmware.h"

enum {
    kSoundEnabled = 0,
    kAutomaticReconnectEnabled = 1,
} ApplicationSettingType;


@implementation ApplicationSettingsViewController

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    self.parentViewController.navigationItem.title = NSLocalizedString(@"Application Settings", nil);
}


//******************************************************************************************
#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}


- (NSString *) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    switch ( section ) {
        case 0:
            return NSLocalizedString(@"General", @"Application settings section title");
        default:
            return NSLocalizedString(@"Firmware update URLs", @"Application settings section title");
    }
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch ( section ) {
        case 0:
            return 2;

        default:
            return 4;
    }
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    // populate the cell
    UITableViewCell *cell;
    NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];

    switch ( indexPath.section ) {
        case 0:
            cell = [tableView dequeueReusableCellWithIdentifier:@"ApplicationSettingCell" forIndexPath:indexPath];
            switch ( indexPath.row ) {
                case kSoundEnabled:
                    cell.textLabel.text = NSLocalizedString(@"Application sounds", nil);
                    cell.accessoryType = [AudioPlayer sharedInstance].soundsEnabled ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
                    break;

                case kAutomaticReconnectEnabled:
                    cell.textLabel.text = NSLocalizedString(@"Automatically reconnect", nil);
                    cell.accessoryType = [ConnectionManager sharedInstance].reconnectMode == kAlwaysReconnect ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
                    break;
            }
            break;

        default:
            cell = [tableView dequeueReusableCellWithIdentifier:@"ApplicationSettingCell2" forIndexPath:indexPath];
            switch ( indexPath.row ) {
                case kNurFirmware:
                    cell.textLabel.text = NSLocalizedString(@"Nur firmware URL", nil);
                    cell.detailTextLabel.text = [defaults stringForKey:@"NurFirmwareIndexUrl"];
                    break;

                case kNurBootloader:
                    cell.textLabel.text = NSLocalizedString(@"Nur bootloader URL", nil);
                    cell.detailTextLabel.text = [defaults stringForKey:@"NurBootloaderIndexUrl"];
                    break;

                case kDeviceFirmware:
                    cell.textLabel.text = NSLocalizedString(@"Device firmware URL", nil);
                    cell.detailTextLabel.text = [defaults stringForKey:@"DeviceFirmwareIndexUrl"];
                    break;

                case kDeviceBootloader:
                    cell.textLabel.text = NSLocalizedString(@"Device bootloader URL", nil);
                    cell.detailTextLabel.text = [defaults stringForKey:@"DeviceBootloaderIndexUrl"];
                    break;
            }
    }
    
    return cell;
}


- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if ( indexPath.section == 0 ) {
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
    }

    else {
        // handle editing of the URL:s
    }

    // refresh
    [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
}


@end
