
#import "ReaderSettingCell.h"
#import "Log.h"

@implementation ReaderSettingCell

- (void) setSettingEnabled:(BOOL)settingEnabled {
    self.enabledSwitch.on = settingEnabled;
}


- (BOOL) settingEnabled {
    return self.enabledSwitch.on;
}


- (IBAction)valueChanged:(id)sender {
    logDebug( @"value now: %d", self.enabledSwitch.on );

    if ( self.delegate ) {
        [self.delegate setting:self.settingType hasChanged:self.enabledSwitch.on];
    }
}

@end
