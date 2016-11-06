
#import "LocateTagAntennaSelector.h"
#import "AverageBuffer.h"

@interface LocateTagAntennaSelector () {
    struct NUR_MODULESETUP setup;
    struct NUR_ANTENNA_MAPPING antennaMap[NUR_MAX_ANTENNAS_EX];
    int antennaMappingCount;
}

//@property (nonatomic, strong) dispatch_queue_t dispatchQueue;

@property (nonatomic, readwrite) AntennaType currentAntenna;
@property (nonatomic, strong) AverageBuffer * signalAverage;
@property (nonatomic, strong) NSMutableArray * antennaNames;

@property (nonatomic, assign) int mBackupSelectedAntenna;
@property (nonatomic, assign) int mBackupAntennaMask;
@property (nonatomic, assign) int mBackupTxLevel;

@property (nonatomic, assign) int mCrossDipoleAntMask;
@property (nonatomic, assign) int mCircularAntMask;
@property (nonatomic, assign) int mProximityAntMask;

@property (nonatomic, assign) BOOL mIsProximity;

@end


@implementation LocateTagAntennaSelector

- (instancetype)init {
    self = [super init];
    if (self) {
        self.currentAntenna = kUnknownAntenna;
        self.mCrossDipoleAntMask = 0;
        self.mCircularAntMask = 0;
        self.mProximityAntMask = 0;

        // average buffer of 3 values
        self.signalAverage = [[AverageBuffer alloc] initWithMaxSize:3 maxAge:0];

        // set up the queue used to async any NURAPI calls
        //self.dispatchQueue = dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0 );
    }

    return self;
}

/*
 - (int) getPhysicalAntennaMask { //(AntennaMapping []map, String ant)
 int mask = 0;
 for (int n=0; n < antennaMappingCount; n++) {
 if (map[n].name.startsWith(ant))
 mask |= (1 << map[n].antennaId);
 }
 return mask;
 }
 */

- (int) begin {
    NSLog( @"setting up antenna selector" );

    [self.signalAverage clear];

    //

    // run on the dispatch queue
    //dispatch_async(self.dispatchQueue, ^{
    // get tx level and antenna mask
    int mask = NUR_SETUP_TXLEVEL | NUR_SETUP_ANTMASKEX | NUR_SETUP_SELECTEDANT;
    int error = NurApiGetModuleSetup( [Bluetooth sharedInstance].nurapiHandle, mask, &setup, sizeof(struct NUR_MODULESETUP) );
    if ( error != NUR_NO_ERROR ) {
        NSLog( @"failed to get module setup, error: %d", error );
        return error;
    }

    // fetched ok, get antenna map
    error = NurApiGetAntennaMap( [Bluetooth sharedInstance].nurapiHandle, antennaMap, &antennaMappingCount, NUR_MAX_ANTENNAS_EX, sizeof(struct NUR_ANTENNA_MAPPING) );
    if ( error != NUR_NO_ERROR ) {
        NSLog( @"failed to get antenna map, error: %d", error );
        return error;
    }

    // convert all antenna names to NSStrings
    self.antennaNames = [NSMutableArray arrayWithCapacity:antennaMappingCount];
    for ( unsigned int index = 0; index < antennaMappingCount; ++index ) {
        [self.antennaNames addObject:[NSString stringWithCString:antennaMap[ index ].name encoding:NSASCIIStringEncoding]];
    }

    for ( NSString * name in self.antennaNames ) {
        NSLog( @"antenna: %@", name );
    }

    // find the masks for given named antennas
    for ( unsigned int index = 0; index < self.antennaNames.count; ++index ) {
        NSString * name = self.antennaNames[ index ];
        if ( [name hasPrefix:@"CrossDipole"] ) {
            self.mCrossDipoleAntMask |= 1 << antennaMap[ index ].antennaId;
        }
        else if ( [name hasPrefix:@"Circular"] ) {
            self.mCircularAntMask |= 1 << antennaMap[ index ].antennaId;
        }
        else if ( [name hasPrefix:@"Proximity"] ) {
            self.mProximityAntMask |= 1 << antennaMap[ index ].antennaId;
        }
    }

    NSLog( @"masks: cross: %d, circular: %d, prox: %d", self.mCrossDipoleAntMask, self.mCircularAntMask, self.mProximityAntMask );

    // save all current settings for later restoring
    self.mBackupTxLevel         = setup.txLevel;
    self.mBackupAntennaMask     = setup.antennaMaskEx;
    self.mBackupSelectedAntenna = setup.selectedAntenna;

    // set the tx level and antenna to auto select
    setup.txLevel = 0;
    setup.selectedAntenna = NUR_ANTENNAID_AUTOSELECT;
    mask = NUR_SETUP_SELECTEDANT | NUR_SETUP_TXLEVEL;
    error = NurApiSetModuleSetup( [Bluetooth sharedInstance].nurapiHandle, mask, &setup, sizeof(struct NUR_MODULESETUP) );
    if ( error != NUR_NO_ERROR ) {
        NSLog( @"failed to set tx level and antenna to auto selection, error: %d", error );
        return error;
    }

    [self selectCrossDipoleAntenna];

    NSLog( @"antenna selector set up ok" );

    return NUR_NO_ERROR;
}


- (void) stop {
    //  dispatch_async(self.dispatchQueue, ^{
    // restore old settings
    setup.selectedAntenna = self.mBackupSelectedAntenna;
    setup.antennaMaskEx = self.mBackupAntennaMask;
    setup.txLevel = self.mBackupTxLevel;

    NSLog( @"restoring old setup" );

    int mask = NUR_SETUP_TXLEVEL | NUR_SETUP_ANTMASKEX | NUR_SETUP_SELECTEDANT;
    int error = NurApiSetModuleSetup( [Bluetooth sharedInstance].nurapiHandle, mask, &setup, sizeof(struct NUR_MODULESETUP) );
    if ( error != NUR_NO_ERROR ) {
        NSLog( @"failed to restore old setup, error: %d", error );
        return;
    }

    NSLog( @"old setup restored ok" );
    //} );
}


- (int) signalStrength {
    return (int)self.signalAverage.avgValue;
}


- (void) selectCrossDipoleAntenna {
    if ( self.mCrossDipoleAntMask != 0 && self.currentAntenna != kCrossDipoleAntenna) {
        [self selectAntennaMask:self.mCrossDipoleAntMask];
        self.currentAntenna = kCrossDipoleAntenna;
    }
}


- (void) selectCircularAntenna {
    if ( self.mCircularAntMask != 0 && self.currentAntenna != kCircularAntenna ) {
        [self selectAntennaMask:self.mCircularAntMask];
        self.currentAntenna = kCircularAntenna;
    }
}


- (void) selectProximityAntenna {
    if (self.mProximityAntMask != 0 && self.currentAntenna != kProximityAntenna ) {
        [self selectAntennaMask:self.mProximityAntMask];
        self.currentAntenna = kProximityAntenna;
    }
}


- (void) selectAntennaMask:(int)antennaMask {
    // dispatch_async(self.dispatchQueue, ^{
    setup.antennaMaskEx = antennaMask;
    int error = NurApiSetModuleSetup( [Bluetooth sharedInstance].nurapiHandle, NUR_SETUP_ANTMASKEX, &setup, sizeof(struct NUR_MODULESETUP) );
    if ( error != NUR_NO_ERROR ) {
        NSLog( @"failed to set antenna mask to %d, error: %d", antennaMask, error );
        return;
    }

    NSLog( @"set antenna mask to: %d", antennaMask );
    //} );
}


- (int) adjust:(int)locateSignal {
    if (self.currentAntenna != kProximityAntenna ) {
        // rescale 0-100 to 0-95 as proximity makes up last 5%
        locateSignal = (int)(locateSignal * 0.95f);
    }
    else {
        // rescale 0-70 to 95-100
        locateSignal = 95 + (int)((float)locateSignal / 14);
        if (locateSignal > 100) {
            locateSignal = 100;
        }
    }
    //Log.d("TRACE", "locateSignal " + locateSignal);

    [self.signalAverage add:locateSignal];
    int avgSignal = (int)self.signalAverage.avgValue;

    if (locateSignal == 0) {
        [self selectCrossDipoleAntenna];
        return avgSignal;
    }

    switch ( self.currentAntenna ) {
        case kCrossDipoleAntenna:
            // If we get over 40% switch to Circular.
            // It is faster since there is only one antenna to do inventory on,
            // but The crossdipole has slightly better range.
            if (locateSignal > 40) {
                [self selectCircularAntenna];
            }
            break;

        case kCircularAntenna:
            // If we get under 35% switch to CrossDP
            if (locateSignal < 35) {
                [self selectCrossDipoleAntenna];
            }

            // If Circular gets over 95% we have ran out of sensitivity on that
            // antenna and it the proximity antenna is now useful.
            else if ( locateSignal >= 95 ) {
                [self selectProximityAntenna];
            }
            break;

        case kProximityAntenna:
            // Set Circular back on for the next pass
            if (locateSignal < 97) {
                [self selectCircularAntenna];
            }
            break;

        default:
            break;
    }

    return avgSignal;
}


@end
