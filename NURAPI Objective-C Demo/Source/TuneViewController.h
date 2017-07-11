
#import <UIKit/UIKit.h>
#import <NurAPIBluetooth/Bluetooth.h>

@interface TuneViewController : UIViewController // <BluetoothDelegate>

@property (weak, nonatomic) IBOutlet UIButton *tuneButton;
@property (weak, nonatomic) IBOutlet UITextView *resultText;

@end
