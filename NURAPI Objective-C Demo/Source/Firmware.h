
#import <Foundation/Foundation.h>

/**
 * Types of available firmware updates.
 **/
typedef enum {
    kNurFirmware,
    kNurBootloader,
    kDeviceFirmware,
    kDeviceBootloader,
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
@property (nonatomic, assign) FirmwareType type;
@property (nonatomic, strong) NSArray *    hw;

// a value calculated from the version string that can be used to compare versions. Larger is newer
@property (nonatomic, assign, readonly) NSUInteger compareVersion;

- (instancetype) initWithName:(NSString *)name type:(FirmwareType)type version:(NSString *)version buildTime:(NSDate *)buildTime url:(NSURL *)url md5:(NSString *)md5 hw:(NSArray *)hw;

/**
 * Returns YES if this firmware is suitable for a device with the given hardware model.
 **/
- (BOOL) suitableForModel:(NSString *)model;

/**
 * Calculates a numeric value from the given version that can be used to compare versions of the given type. It can not be used
 * to compare versions of different firmware types. A larger value means a higher version.
 **/
+ (NSUInteger) calculateCompareVersion:(NSString *)version type:(FirmwareType)type;

+ (BOOL) extractMajor:(int *)major minor:(int *)minor build:(int *)build fromVersion:(NSString *)version;

/**
 * Returns the given type as a string that can be used in the UI.
 **/
+ (NSString *) getTypeString:(FirmwareType)type;

@end
