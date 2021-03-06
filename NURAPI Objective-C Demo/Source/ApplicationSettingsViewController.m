
#import "ApplicationSettingsViewController.h"
#import "AudioPlayer.h"
#import "ConnectionManager.h"
#import "Firmware.h"

enum {
    kSoundEnabled = 0,
    kAutomaticReconnectEnabled = 1,
} ApplicationSettingType;

@interface ApplicationSettingsViewController() {
    BOOL advancedOptionsShown;
}

@property (nonatomic, strong) NSDictionary * indexFileUrls;

@end


@implementation ApplicationSettingsViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    // set up the theme
    [self setupTheme];

    // load the meta data plist from the bundle
    NSString* path = [[NSBundle mainBundle] pathForResource:@"MetaData" ofType:@"plist"];
    NSDictionary *metadata = [[NSDictionary alloc] initWithContentsOfFile: path];
    self.indexFileUrls = @{ @(kNurFirmware): [NSURL URLWithString:[metadata objectForKey:@"nurFirmwareIndexUrl"]],
                            @(kNurBootloader): [NSURL URLWithString:[metadata objectForKey:@"nurBootloaderIndexUrl"]],
                            @(kDeviceFirmware): [NSURL URLWithString:[metadata objectForKey:@"deviceFirmwareIndexUrl"]],
                            @(kDeviceBootloader): [NSURL URLWithString:[metadata objectForKey:@"deviceBootloaderIndexUrl"]]};

    // no advanced options by default
    advancedOptionsShown = NO;
}


- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    self.parentViewController.navigationItem.title = NSLocalizedString(@"Application Settings", nil);
}


//******************************************************************************************
#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;

    // uncomment this to enable the advanced options that show the firmware update URL:s
    //return advancedOptionsShown ? 3 : 2;
}


- (NSString *) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    switch ( section ) {
        case 0:
            return NSLocalizedString(@"General", @"Application settings section title");
        case 1:
            return NSLocalizedString(@"Advanced options", @"Application settings section title");
        default:
            return NSLocalizedString(@"Firmware update URLs", @"Application settings section title");
    }
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch ( section ) {
        case 0:
            return 2;

        case 1:
            return 1;

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

        case 1:
            cell = [tableView dequeueReusableCellWithIdentifier:@"ApplicationSettingCell" forIndexPath:indexPath];
            cell.textLabel.text = NSLocalizedString(@"Show advanced options", nil);
            cell.accessoryType = advancedOptionsShown ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
            break;

        default:
            // TODO: this uses the old URL:s from defaults. They are now in MetaData.plist. See FirmwareDownloader.h for
            // how they are loaded now

            cell = [tableView dequeueReusableCellWithIdentifier:@"ApplicationSettingCell2" forIndexPath:indexPath];
            switch ( indexPath.row ) {
                case kNurFirmware:
                    cell.textLabel.text = NSLocalizedString(@"Nur firmware URL", nil);
                    cell.detailTextLabel.text = self.indexFileUrls[ @(kNurFirmware) ];
                    break;

                case kNurBootloader:
                    cell.textLabel.text = NSLocalizedString(@"Nur bootloader URL", nil);
                    cell.detailTextLabel.text = self.indexFileUrls[ @(kNurBootloader) ];
                    break;

                case kDeviceFirmware:
                    cell.textLabel.text = NSLocalizedString(@"Device firmware URL", nil);
                    cell.detailTextLabel.text = self.indexFileUrls[ @(kDeviceFirmware) ];
                    break;

                case kDeviceBootloader:
                    cell.textLabel.text = NSLocalizedString(@"Device bootloader URL", nil);
                    cell.detailTextLabel.text = self.indexFileUrls[ @(kDeviceBootloader) ];
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

        // refresh
        [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
    }

    else if ( indexPath.section == 1 ) {
        // toggle advanced options and reload everything
        advancedOptionsShown = advancedOptionsShown ? NO : YES;
        [tableView reloadData];
    }

    else {
        // handle editing of the URL:s
    }
}


@end
