
#import <UIKit/UIKit.h>
#import <NurAPIBluetooth/Bluetooth.h>

@interface LocateViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, BluetoothDelegate>

@property (weak, nonatomic) IBOutlet UITableView * tableView;

@end