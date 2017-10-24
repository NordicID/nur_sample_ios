
#import <UIKit/UIKit.h>
#import <NurAPIBluetooth/Bluetooth.h>

#import "UIViewController+Theme.h"

@interface SelectReaderViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, BluetoothDelegate>

@property (strong, nonatomic) IBOutlet UITableView * tableView;
@property (weak, nonatomic) IBOutlet UIButton *      disconnectButton;

@end

