
#import <Foundation/Foundation.h>
#import <NurAPIBluetooth/Bluetooth.h>

/**
 * Simple wrapper class for data related to a single scanned tag.
 **/
@interface Tag : NSObject

@property (nonatomic, strong, readonly) NSData *    epc;
@property (nonatomic, strong, readonly) NSString *  hex;
@property (nonatomic, assign, readonly) DWORD       frequency;
@property (nonatomic, assign, readonly) signed char rssi;
@property (nonatomic, assign, readonly) char        scaledRssi;
@property (nonatomic, assign, readonly) DWORD       timestamp;
@property (nonatomic, assign, readonly) BYTE        channel;
@property (nonatomic, assign, readonly) BYTE        antennaId;

- (instancetype) initWithEpc:(NSData *)epc frequency:(DWORD)frequency rssi:(signed char)rssi scaledRssi:(char)scaledRssi timestamp:(DWORD)timestamp channel:(BYTE)channel antennaId:(BYTE)antennaId;

@end
