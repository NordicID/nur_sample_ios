
#import <Foundation/Foundation.h>

/**
 * Types of available firmware updates.
 **/
typedef enum {
    kReaderFirmware,
    kNurRfidFirmware
} FirmwareType;


/**
 * Container for a single remote downloadable firmware object.
 *
 * "name": "NUR-L2-application-v5.10-A",
 * "version": "5.10-A",
 * "buildtime": "1489051206",
 * "url": "https://raw.githubusercontent.com/NordicID/nur_firmware/master/NUR-L2-application-v5.10/NUR-L2-application-v5.10-A.bin",
 * "md5": "18c1e04cb192e0c9683af91aeeec615a",
 * "hw": [ "NUR-05WL2", "NUR-10W" ]
 **/
@interface Firmware : NSObject

@property (nonatomic, strong) NSString *   name;
@property (nonatomic, strong) NSString *   version;
@property (nonatomic, strong) NSDate *     buildTime;
@property (nonatomic, strong) NSURL *      url;
@property (nonatomic, strong) NSString *   md5;
@property (nonatomic, strong) NSArray *    hw;
@property (nonatomic, assign) FirmwareType firmwareType;

@end
