
#import "MainMenuViewController.h"
#import "MainMenuCell.h"
#import "Tag.h"
#import "ConnectionManager.h"

@interface MainMenuViewController ()

@property (nonatomic, strong) dispatch_queue_t dispatchQueue;
@property (nonatomic, strong) NSTimer * timer;

// main menu data
@property (nonatomic, assign) UIEdgeInsets insets;
@property (nonatomic, assign) CGSize cellSize;
@property (nonatomic, strong) NSArray * iconNames;
@property (nonatomic, strong) NSArray * titles;
@property (nonatomic, strong) NSArray * segues;

@end


@implementation MainMenuViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    CGFloat top, left, bottom, right;
    CGFloat cellWidth, cellHeight;

    if ( UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ) {
        top = 20;
        left = 20;
        bottom = 10;
        right = 20;
        cellWidth = 240;
        cellHeight = 220;
    }
    else {
        top = 0;
        left = 20;
        bottom = 10;
        right = 20;
        cellWidth = 120;
        cellHeight = 140;
    }

    self.insets = UIEdgeInsetsMake( top, left, bottom, right );
    self.cellSize = CGSizeMake( cellWidth, cellHeight );

    self.iconNames = @[ @"MainMenuInventory",
                        @"MainMenuLocate",
                        @"MainMenuWrite",
                        @"MainMenuBarcode",
                        @"MainMenuSettings",
                        @"MainMenuInfo",
                        @"MainMenuGuide" ];
    self.titles    = @[ NSLocalizedString(@"Inventory", @"main menu"),
                        NSLocalizedString( @"Locate", @"main menu"),
                        NSLocalizedString(@"Write Tag", @"main menu"),
                        NSLocalizedString(@"Barcode", @"main menu"),
                        NSLocalizedString(@"Settings", @"main menu"),
                        NSLocalizedString(@"Info", @"main menu"),
                        NSLocalizedString(@"Quick Guide", @"main menu") ];
    self.segues    = @[ @"InventorySegue",
                        @"LocateSegue",
                        @"WriteTagSegue",
                        @"BarcodeSegue",
                        @"SettingsSegue",
                        @"InfoSegue",
                        @"QuickGuideSegue", ];

    // set up the queue used to async any NURAPI calls
    self.dispatchQueue = dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0 );
}


- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    // register for bluetooth events
    [[Bluetooth sharedInstance] registerDelegate:self];

    // connection already ok?
    if ( [ConnectionManager sharedInstance].currentReader != nil && self.timer == nil) {
        // start a timer that updates the battery level periodically
        self.timer = [NSTimer scheduledTimerWithTimeInterval:5.0 target:self selector:@selector(updateStatusInfo) userInfo:nil repeats:YES];
    }

    [self updateStatusInfo];
}


- (void) viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];

    // we no longer need bluetooth events
    [[Bluetooth sharedInstance] deregisterDelegate:self];

    // disable the timer
    if ( self.timer ) {
        [self.timer invalidate];
        self.timer = nil;
    }
}


- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [self.collectionView.collectionViewLayout invalidateLayout];
}


- (void) updateStatusInfo {
    [self updateConnectedLabel];
    [self updateBatteryLevel];
}


- (void) updateConnectedLabel {
    CBPeripheral * reader = [ConnectionManager sharedInstance].currentReader;

    if ( reader ) {
        self.connectedLabel.text = reader.name;
    }
    else {
        self.connectedLabel.text = @"no";
    }
}


- (void) updateBatteryLevel {
    // any current reader?
    if ( ! [ConnectionManager sharedInstance].currentReader ) {
        self.batteryLevelLabel.text = @"?";
        self.batteryLevelLabel.hidden = YES;
        self.batteryIconLabel.hidden = YES;
        return;
    }

    NSLog( @"checking battery status" );

    dispatch_async(self.dispatchQueue, ^{
        NUR_ACC_BATT_INFO batteryInfo;

        // get current settings
        int error = NurAccGetBattInfo( [Bluetooth sharedInstance].nurapiHandle, &batteryInfo, sizeof(NUR_ACC_BATT_INFO));

        dispatch_async(dispatch_get_main_queue(), ^{
            // the percentage is -1 if unknown
            if (error != NUR_NO_ERROR ) {
                // failed to get battery info
                char buffer[256];
                NurApiGetErrorMessage( error, buffer, 256 );
                NSString * message = [NSString stringWithCString:buffer encoding:NSUTF8StringEncoding];
                NSLog( @"failed to get battery info: %@", message );
                self.batteryLevelLabel.hidden = YES;
                self.batteryIconLabel.hidden = YES;
            }
            else if ( batteryInfo.percentage == -1 ) {
                self.batteryLevelLabel.hidden = YES;
                self.batteryIconLabel.hidden = YES;
            }
            else {
                self.batteryLevelLabel.hidden = NO;
                self.batteryIconLabel.hidden = NO;
                self.batteryLevelLabel.text = [NSString stringWithFormat:@"%d%%", batteryInfo.percentage];

                if ( batteryInfo.percentage <= 33 ) {
                    self.batteryIconLabel.image = [UIImage imageNamed:@"Battery-33"];
                }
                else if ( batteryInfo.percentage <= 66 ) {
                    self.batteryIconLabel.image = [UIImage imageNamed:@"Battery-66"];
                }
                else {
                    self.batteryIconLabel.image = [UIImage imageNamed:@"Battery-100"];
                }
            }
        });
    });
}


//****************************************************************************************************************
#pragma mark - Collection view delegate
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}


- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.titles.count;
}


- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    MainMenuCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"MainMenuCell" forIndexPath:indexPath];

    // populate the cell
    cell.title.text = self.titles[ indexPath.row ];
    cell.icon.image = [UIImage imageNamed:self.iconNames[ indexPath.row ]];

    // DEBUG
    //cell.backgroundColor = [UIColor redColor];
    return cell;
}


- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    [self performSegueWithIdentifier:self.segues[ indexPath.row] sender:nil];
}


//****************************************************************************************************************
#pragma mark - Collection view delegate flow layout
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    int itemsPerRow;
    if ( UIInterfaceOrientationIsPortrait([[UIApplication sharedApplication] statusBarOrientation]) ) {
        itemsPerRow = 2;
    }
    else {
        itemsPerRow = 3;
    }

    CGFloat paddingSpace = self.insets.left * (itemsPerRow + 1);
    CGFloat width = self.collectionView.frame.size.width;
    CGFloat availableWidth = width - paddingSpace;
    CGFloat widthPerItem = availableWidth / itemsPerRow;
    return CGSizeMake( widthPerItem, self.cellSize.height );
}


- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    return self.insets;
}


- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {
    return 0;
}


/*****************************************************************************************************************
 * Bluetooth delegate callbacks
 * The callbacks do not necessarily come on the main thread, so make sure everything that touches the UI is done on
 * the main thread only.
 **/
#pragma mark - Bluetooth delegate

- (void) readerConnectionOk {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSLog( @"connection ok, handle: %p", [Bluetooth sharedInstance].nurapiHandle );
        NSLog( @"MTU with write response: %lu", (unsigned long)[[Bluetooth sharedInstance].currentReader maximumWriteValueLengthForType:CBCharacteristicWriteWithResponse] );
        NSLog( @"MTU without write response: %lu", (unsigned long)[[Bluetooth sharedInstance].currentReader maximumWriteValueLengthForType:CBCharacteristicWriteWithoutResponse] );
        self.scanButton.enabled = YES;
        self.settingsButton.enabled = YES;
        self.writeTagButton.enabled = YES;
        self.infoButton.enabled = YES;
        self.readBarcodeButton.enabled = YES;

        // start a timer that updates the battery level periodically
        self.timer = [NSTimer scheduledTimerWithTimeInterval:5.0 target:self selector:@selector(updateBatteryLevel) userInfo:nil repeats:YES];
    });

    [self updateStatusInfo];
}


- (void) readerDisconnected {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSLog( @"reader disconnected" );

        // stop any old timeout timer that we may have
        if ( self.timer ) {
            [self.timer invalidate];
            self.timer = nil;
        }

        [self updateStatusInfo];
    });
}

- (void) readerConnectionFailed {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSLog( @"connection failed" );
        self.scanButton.enabled = NO;
        self.settingsButton.enabled = NO;
        self.writeTagButton.enabled = NO;
        self.infoButton.enabled = NO;
        self.readBarcodeButton.enabled = NO;
    });
}



@end
