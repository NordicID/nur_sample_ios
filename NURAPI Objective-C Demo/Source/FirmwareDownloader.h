
#import <Foundation/Foundation.h>

#import "Firmware.h"

@protocol FirmwareDownloaderDelegate

- (void) firmwareMetaDataDownloaded:(FirmwareType)type firmwares:(NSArray *)firmwares;

- (void) firmwareMetaDataFailed:(FirmwareType)type error:(NSString *)error;

@end


@interface FirmwareDownloader : NSObject

@property (nonatomic, weak) id<FirmwareDownloaderDelegate> delegate;

- (instancetype) initWithDelegate:(id<FirmwareDownloaderDelegate>)delegate;

- (void) downloadIndexFiles;

@end
