
#import <UIKit/UIKit.h>
#import <NurAPIBluetooth/Bluetooth.h>

@interface SelectReaderViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, BluetoothDelegate>

@property (strong, nonatomic) IBOutlet UILabel *     statusLabel;
@property (strong, nonatomic) IBOutlet UITableView * tableView;

@end

