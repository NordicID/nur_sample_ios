
#import <UIKit/UIKit.h>
#import <NurAPIBluetooth/Bluetooth.h>

@interface InventoryViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, BluetoothDelegate>

@property (weak, nonatomic) IBOutlet UILabel *     tagsLabel;
@property (weak, nonatomic) IBOutlet UILabel *     elapsedTimeLabel;
@property (weak, nonatomic) IBOutlet UILabel *     tagsPerSecondLabel;
@property (weak, nonatomic) IBOutlet UILabel *     averageTagsPerSecondLabel;
@property (weak, nonatomic) IBOutlet UILabel *     maxTagsPerSecondLabel;
@property (weak, nonatomic) IBOutlet UITableView * tableView;
@property (weak, nonatomic) IBOutlet UIButton *    inventoryButton;
@property (weak, nonatomic) IBOutlet UIButton *    clearButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *shareButton;

@end
