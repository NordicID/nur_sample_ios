
#import <UIKit/UIKit.h>

@interface SelectSettingViewController : UITableViewController

@property (nonatomic, strong) NSArray * alternatives;

//! the name of the setting being set
@property (nonatomic, strong) NSString * settingName;

//! the NURAPI setting that the alternatives refer to
@property (nonatomic, assign) enum NUR_MODULESETUP_FLAGS setting;

// dispatch queue used to save settings to NURAPI
@property (nonatomic, strong) dispatch_queue_t dispatchQueue;

@end
