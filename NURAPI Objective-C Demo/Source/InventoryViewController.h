
#import <UIKit/UIKit.h>
#import <NurAPIBluetooth/Bluetooth.h>

@interface InventoryViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, BluetoothDelegate>

@property (weak, nonatomic) IBOutlet UILabel *     tagsLabel;
@property (weak, nonatomic) IBOutlet UITableView * tableView;
@property (weak, nonatomic) IBOutlet UIButton *    inventoryButton;

@end
