
#import <UIKit/UIKit.h>
#import <NurAPIBluetooth/Bluetooth.h>

@interface TuneViewController : UIViewController

//! dispatch queue used to save settings to NURAPI
@property (nonatomic, strong) dispatch_queue_t dispatchQueue;

//! the mask containing the enabled antennas
@property (nonatomic, assign) DWORD antennaMask;

@property (weak, nonatomic) IBOutlet UIButton *tuneButton;

@end
