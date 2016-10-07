
#import <UIKit/UIKit.h>
#import <NurAPIBluetooth/Bluetooth.h>

@interface ReadBarcodeViewController : UIViewController <BluetoothDelegate>

@property (weak, nonatomic) IBOutlet UILabel * status;
@property (weak, nonatomic) IBOutlet UILabel * barcode;

@end
