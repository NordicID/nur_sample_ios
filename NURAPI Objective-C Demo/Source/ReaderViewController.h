
#import <UIKit/UIKit.h>
#import <NurAPIBluetooth/Bluetooth.h>

@interface ReaderViewController : UIViewController <BluetoothDelegate>

@property (nonatomic, weak) CBPeripheral *     reader;
@property (weak, nonatomic) IBOutlet UIButton *scanButton;
@property (weak, nonatomic) IBOutlet UIButton *settingsButton;
@property (weak, nonatomic) IBOutlet UIButton *writeTagButton;
@property (weak, nonatomic) IBOutlet UIButton *infoButton;

@end
