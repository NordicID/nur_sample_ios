
#import <UIKit/UIKit.h>
#import <NurAPIBluetooth/Bluetooth.h>
#import "UIViewController+Theme.h"

@interface LocateViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, BluetoothDelegate>

@property (weak, nonatomic) IBOutlet UITableView * tableView;
@property (weak, nonatomic) IBOutlet UIButton *    refreshButton;

@end
