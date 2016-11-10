
#import "ApplicationSettingsViewController.h"
#import "AudioPlayer.h"

enum {
    kSoundEnabled = 0,
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
    return 1;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    // populate the cell
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ApplicationSettingCell" forIndexPath:indexPath];

    if ( indexPath.row == kSoundEnabled ) {
        cell.textLabel.text = @"Application sounds";
        cell.accessoryType = [AudioPlayer sharedInstance].soundsEnabled ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    }
    
    return cell;
}


- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if ( indexPath.row == kSoundEnabled ) {
        // toggle the sounds
        AudioPlayer * ap = [AudioPlayer sharedInstance];
        ap.soundsEnabled = ap.soundsEnabled ? NO : YES;

        [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
    }
}


@end
