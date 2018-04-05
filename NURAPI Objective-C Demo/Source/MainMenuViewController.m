
#import "MainMenuViewController.h"
#import "MainMenuCell.h"
#import "Tag.h"
#import "ConnectionManager.h"
#import "ThemeManager.h"
#import "Log.h"

/**
 * A single entry in the main menu.
 **/
@interface MainMenuEntry : NSObject

@property (nonatomic, strong) NSString * title;
@property (nonatomic, strong) NSString * iconName;
@property (nonatomic, strong) NSString * seque;
@property (nonatomic, assign) BOOL       enabled;
@property (nonatomic, assign) BOOL       alwaysEnabled;

- (instancetype) initWithTitle:(NSString *)title icon:(NSString *)icon segue:(NSString *)seque enabled:(BOOL)enabled alwaysEnabled:(BOOL)alwaysEnabled;

@end

@implementation MainMenuEntry

- (instancetype) initWithTitle:(NSString *)title icon:(NSString *)icon segue:(NSString *)seque enabled:(BOOL)enabled alwaysEnabled:(BOOL)alwaysEnabled {
    self = [super init];
    if (self) {
        self.title = title;
        self.iconName = icon;
        self.seque = seque;
        self.enabled = enabled;
        self.alwaysEnabled = alwaysEnabled;
    }
    return self;
}

@end


@interface MainMenuViewController () {
    // charging animation counter. increases for each time the charging icon is changed
    unsigned int chargingAnimationFrame;
}

@property (nonatomic, strong) dispatch_queue_t dispatchQueue;
@property (nonatomic, strong) NSTimer *        batteryTimer;

// main menu data
@property (nonatomic, assign) UIEdgeInsets insets;
@property (nonatomic, assign) CGSize       cellSize;
@property (nonatomic, strong) NSArray *    menuEntries;

@end

@implementation MainMenuViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.navigationItem.title = [ThemeManager sharedInstance].theme.applicationTitle;

    // set up the theme
    [self setupTheme];

    // set up the connection manager so that it's aware of everything that happens
    [[ConnectionManager sharedInstance] setup];
    [[ConnectionManager sharedInstance] applicationActivated];

    chargingAnimationFrame = 0;

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

    self.menuEntries = @[ [[MainMenuEntry alloc] initWithTitle:NSLocalizedString(@"Inventory", @"main menu") icon:@"MainMenuInventory" segue:@"InventorySegue" enabled:NO alwaysEnabled:NO],
                          [[MainMenuEntry alloc] initWithTitle:NSLocalizedString( @"Locate", @"main menu") icon:@"MainMenuLocate" segue:@"LocateSegue" enabled:NO alwaysEnabled:NO],
                          [[MainMenuEntry alloc] initWithTitle:NSLocalizedString(@"Write Tag", @"main menu") icon:@"MainMenuWrite" segue:@"WriteTagSegue" enabled:NO alwaysEnabled:NO],
                          [[MainMenuEntry alloc] initWithTitle:NSLocalizedString(@"Barcode", @"main menu") icon:@"MainMenuBarcode" segue:@"BarcodeSegue" enabled:NO alwaysEnabled:NO],
                          [[MainMenuEntry alloc] initWithTitle:NSLocalizedString(@"Settings", @"main menu") icon:@"MainMenuSettings" segue:@"SettingsSegue" enabled:NO alwaysEnabled:NO],
                          [[MainMenuEntry alloc] initWithTitle:NSLocalizedString(@"Info", @"main menu") icon:@"MainMenuInfo" segue:@"InfoSegue" enabled:NO alwaysEnabled:YES],
                          [[MainMenuEntry alloc] initWithTitle:NSLocalizedString(@"Quick Guide", @"main menu") icon:@"MainMenuGuide" segue:@"QuickGuideSegue" enabled:YES alwaysEnabled:YES] ];

    // set up the queue used to async any NURAPI calls
    self.dispatchQueue = dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0 );
}


- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    // register for reader events
    [[ConnectionManager sharedInstance] registerDelegate:self];

    [self updateMenuEntryState];

    // connection already ok?
    if ( [ConnectionManager sharedInstance].currentReader != nil && self.batteryTimer == nil) {
        // start a timer that updates the battery level periodically
        self.batteryTimer = [NSTimer scheduledTimerWithTimeInterval:5.0 target:self selector:@selector(updateBatteryLevel) userInfo:nil repeats:YES];
    }

    [self updateConnectedLabel];
    [self updateBatteryLevel];
}


- (void) viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];

    // we no longer need bluetooth events
    [[ConnectionManager sharedInstance] deregisterDelegate:self];

    // disable the timer
    if ( self.batteryTimer ) {
        [self.batteryTimer invalidate];
        self.batteryTimer = nil;
    }
}


- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [self.collectionView.collectionViewLayout invalidateLayout];
}


- (IBAction)shareLog:(UIBarButtonItem *)sender {
    // get the URL to the log file
    NSURL * logFileUrl = [[Log sharedInstance] getFileUrl];

    // set up the activity controller for sharing a single URL
    NSArray* sharedObjects = [NSArray arrayWithObjects:logFileUrl, nil];
    UIActivityViewController *activityViewController = [[UIActivityViewController alloc]
                                                        initWithActivityItems:sharedObjects applicationActivities:nil];

    activityViewController.popoverPresentationController.barButtonItem = self.shareButton;

    // when the activity is completed delete the temporary file
    activityViewController.completionWithItemsHandler = ^(NSString *activityType, BOOL completed, NSArray *returnedItems, NSError *activityError) {
        logDebug(@"activity: %@ - finished flag: %d", activityType, completed);
        //[[NSFileManager defaultManager] removeItemAtURL:fileURL error:nil];

        // show an error if there was one
        if ( activityError != nil ) {
            UIAlertController * alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Error Sharing Log File", nil)
                                                                            message:activityError.localizedDescription
                                                                     preferredStyle:UIAlertControllerStyleAlert];

            UIAlertAction* okButton = [UIAlertAction
                                       actionWithTitle:NSLocalizedString(@"Ok", nil)
                                       style:UIAlertActionStyleDefault
                                       handler:^(UIAlertAction * action) {
                                           // nothing special to do right now
                                       }];


            [alert addAction:okButton];
            [self presentViewController:alert animated:YES completion:nil];
        }
    };

    [self presentViewController:activityViewController animated:true completion:nil];
}

//- (void) updateStatusInfo {
//    [self updateConnectedLabel];
//    [self updateBatteryLevel];
//}


- (void) updateConnectedLabel {
    CBPeripheral * reader = [ConnectionManager sharedInstance].currentReader;

    if ( reader ) {
        self.connectedLabel.text = [NSString stringWithFormat:@"%@: %@", NSLocalizedString(@"Connected", @"connection status in main menu footer"), reader.name];
    }
    else {
        self.connectedLabel.text = NSLocalizedString(@"Not connected", @"connection status in main menu footer");
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

    logDebug( @"checking battery status" );

    dispatch_async(self.dispatchQueue, ^{
        NUR_ACC_BATT_INFO batteryInfo;

        // get current settings
        int error = NurAccGetBattInfo( [Bluetooth sharedInstance].nurapiHandle, &batteryInfo, sizeof(NUR_ACC_BATT_INFO));

        dispatch_async(dispatch_get_main_queue(), ^{
            int interval = 5;

            // the percentage is -1 if unknown
            if (error != NUR_NO_ERROR ) {
                // failed to get battery info
                char buffer[256];
                NurApiGetErrorMessage( error, buffer, 256 );
                NSString * message = [NSString stringWithCString:buffer encoding:NSUTF8StringEncoding];
                logError( @"failed to get battery info: %@", message );
                self.batteryLevelLabel.hidden = YES;
                self.batteryIconLabel.hidden = YES;
            }
            else if ( batteryInfo.flags & NUR_ACC_BATT_FL_CHARGING ) {
                logDebug(@"charging");
                self.batteryIconLabel.hidden = NO;

                // avoid showing a "-1"
                if ( batteryInfo.percentage < 0 ) {
                    self.batteryLevelLabel.hidden = YES;
                }
                else {
                    self.batteryLevelLabel.text = [NSString stringWithFormat:@"%d%%", batteryInfo.percentage];
                    self.batteryLevelLabel.hidden = NO;
                }

                interval = 1;

                // set up the charging icon
                chargingAnimationFrame++;
                switch ( chargingAnimationFrame % 3 ) {
                    case 0:
                        self.batteryIconLabel.image = [UIImage imageNamed:@"Battery-33"];
                        break;
                    case 1:
                        self.batteryIconLabel.image = [UIImage imageNamed:@"Battery-66"];
                        break;
                    default:
                        self.batteryIconLabel.image = [UIImage imageNamed:@"Battery-100"];
                        break;
                }
            }
            else {
                self.batteryIconLabel.hidden = NO;

                // avoid showing a "-1"
                if ( batteryInfo.percentage < 0 ) {
                    self.batteryLevelLabel.hidden = YES;
                }
                else {
                    self.batteryLevelLabel.text = [NSString stringWithFormat:@"%d%%", batteryInfo.percentage];
                    self.batteryLevelLabel.hidden = NO;
                }

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

            // set up a battery timer if we don't already have one
            if ( self.batteryTimer == nil ) {
                // start a timer that updates the battery level periodically
                self.batteryTimer = [NSTimer scheduledTimerWithTimeInterval:interval target:self selector:@selector(updateBatteryLevel) userInfo:nil repeats:YES];
            }
            else if ( fabs( self.batteryTimer.timeInterval - interval) > 2 ) {
                // the timer is running, but it's using the wrong interval
                [self.batteryTimer invalidate];
                self.batteryTimer = [NSTimer scheduledTimerWithTimeInterval:interval target:self selector:@selector(updateBatteryLevel) userInfo:nil repeats:YES];
            }
        });
    });
}


- (void) updateMenuEntryState {
    if ( [ConnectionManager sharedInstance].currentReader ) {
        // enable all entries
        for ( MainMenuEntry * entry in self.menuEntries ) {
            entry.enabled = YES;
        }
    }
    else {
        // disable all entries
        for ( MainMenuEntry * entry in self.menuEntries ) {
            if ( ! entry.alwaysEnabled ) {
                entry.enabled = NO;
            }
        }
    }
}


//****************************************************************************************************************
#pragma mark - Collection view delegate
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}


- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.menuEntries.count;
}


- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    MainMenuCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"MainMenuCell" forIndexPath:indexPath];

    MainMenuEntry * entry = self.menuEntries[ indexPath.row ];

    // populate the cell
    cell.title.text = entry.title;
    cell.icon.image = [UIImage imageNamed:entry.iconName];

    // DEBUG
    //cell.backgroundColor = [UIColor redColor];
    return cell;
}


- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    MainMenuEntry * entry = self.menuEntries[ indexPath.row ];

    // is the entry enabled?
    if ( entry.enabled == NO && entry.alwaysEnabled == NO ) {
        logDebug( @"entry disabled" );
        return;
    }

    [self performSegueWithIdentifier:entry.seque sender:nil];
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
 * Connection manager delegate callbacks
 * The callbacks do not necessarily come on the main thread, so make sure everything that touches the UI is done on
 * the main thread only.
 **/
#pragma mark - Connection manager delegate

- (void) connectingToReader:(CBPeripheral *)reader {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.connectedLabel.text = [NSString stringWithFormat:@"%@: %@", NSLocalizedString(@"Connecting to", @"connection status in main menu footer"), reader.name];
    });
}


- (void) readerConnectionOk {
    dispatch_async(dispatch_get_main_queue(), ^{
        logDebug( @"connection ok, handle: %p", [Bluetooth sharedInstance].nurapiHandle );
        logDebug( @"MTU with write response: %lu", (unsigned long)[[Bluetooth sharedInstance].currentReader maximumWriteValueLengthForType:CBCharacteristicWriteWithResponse] );
        logDebug( @"MTU without write response: %lu", (unsigned long)[[Bluetooth sharedInstance].currentReader maximumWriteValueLengthForType:CBCharacteristicWriteWithoutResponse] );

        // enable all entries
        for ( MainMenuEntry * entry in self.menuEntries ) {
            entry.enabled = YES;
        }

        [self updateConnectedLabel];
        [self updateBatteryLevel];
    });
}


- (void) readerDisconnected {
    dispatch_async(dispatch_get_main_queue(), ^{
        logDebug( @"reader disconnected" );

        [self updateMenuEntryState];

        // stop any old timeout timer that we may have
        if ( self.batteryTimer ) {
            [self.batteryTimer invalidate];
            self.batteryTimer = nil;
        }

        [self updateConnectedLabel];
        [self updateBatteryLevel];
    });
}


- (void) readerConnectionFailed {
    dispatch_async(dispatch_get_main_queue(), ^{
        logError( @"connection failed" );
        [self updateMenuEntryState];
    });
}



@end
