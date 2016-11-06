
#import <UIKit/UIKit.h>
#import <NurAPIBluetooth/Bluetooth.h>

#import "WriteTagPopoverViewController.h"

@interface WriteTagViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, UIPopoverPresentationControllerDelegate, BluetoothDelegate, WriteTagPopoverViewControllerDelegate>

@property (weak, nonatomic) IBOutlet UILabel *     promptLabel;
@property (weak, nonatomic) IBOutlet UITableView * tableView;

@end
