
#import <UIKit/UIKit.h>
#import <NurAPIBluetooth/Bluetooth.h>

@interface MainMenuViewController : UIViewController <UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, BluetoothDelegate>

@property (weak, nonatomic) IBOutlet UICollectionView * collectionView;
@property (weak, nonatomic) IBOutlet UIButton *scanButton;
@property (weak, nonatomic) IBOutlet UIButton *settingsButton;
@property (weak, nonatomic) IBOutlet UIButton *writeTagButton;
@property (weak, nonatomic) IBOutlet UIButton *infoButton;
@property (weak, nonatomic) IBOutlet UIButton *readBarcodeButton;
@property (weak, nonatomic) IBOutlet UIButton *locateButton;
@property (weak, nonatomic) IBOutlet UIButton *authButton;
@property (weak, nonatomic) IBOutlet UIButton *guideButton;
@property (weak, nonatomic) IBOutlet UILabel *connectedLabel;
@property (weak, nonatomic) IBOutlet UIImageView *batteryIconLabel;
@property (weak, nonatomic) IBOutlet UILabel *batteryLevelLabel;

@end