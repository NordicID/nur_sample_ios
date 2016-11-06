
#import <Foundation/Foundation.h>
#import <NurAPIBluetooth/Bluetooth.h>

typedef enum {
    kUnknownAntenna,
    kCrossDipoleAntenna,
    kCircularAntenna,
    kProximityAntenna
} AntennaType;


@interface LocateTagAntennaSelector : NSObject

@property (nonatomic, readonly) AntennaType currentAntenna;
@property (nonatomic, readonly) int         signalStrength;

- (int) begin;
- (void) stop;
- (int) adjust:(int)locateSignal;

@end
