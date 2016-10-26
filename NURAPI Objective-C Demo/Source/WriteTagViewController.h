
#import <UIKit/UIKit.h>
#import <NurAPIBluetooth/Bluetooth.h>

@interface WriteTagViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, UIPopoverPresentationControllerDelegate, BluetoothDelegate>

@property (weak, nonatomic) IBOutlet UILabel *     promptLabel;
@property (weak, nonatomic) IBOutlet UITableView * tableView;

@end
