
#import "Log.h"

@interface Log()

@property (nonatomic, strong) NSFileHandle * fileHandle;
@property (nonatomic, strong) NSDateFormatter * dateFormatter;

@end

@implementation Log

+ (Log *) sharedInstance {
    static Log * instance = nil;
    static dispatch_once_t onceToken;

    dispatch_once( &onceToken, ^{
        instance = [[Log alloc] init];
    });

    return instance;
}


- (instancetype)init {
    self = [super init];
    if (self) {
        self.logToConsole = YES;
        self.dateFormatter = [[NSDateFormatter alloc] init];
        [self.dateFormatter setDateFormat:@"YYYY-MM-dd HH:mm:ss.SSS"];
    }

    return self;
}


- (void) debug:(NSString *)message {
    NSString * entry = [NSString stringWithFormat:@"%@ debug %@\n", [self.dateFormatter stringFromDate:[NSDate date]], message];
    [self addEntry:entry];
}


- (void) error:(NSString *)message {
    NSString * entry = [NSString stringWithFormat:@"%@ error %@\n", [self.dateFormatter stringFromDate:[NSDate date]], message];
    [self addEntry:entry];
}


- (NSURL *) getFileUrl {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSURL *documentsDirectoryUrl = [NSURL fileURLWithPath:documentsDirectory isDirectory:YES];
    return [documentsDirectoryUrl URLByAppendingPathComponent:@"log.txt"];
}


- (void) addEntry:(NSString *)entry {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *fileName = [documentsDirectory stringByAppendingPathComponent:@"log.txt"];

    if ( self.logToConsole ) {
        printf("%s", entry.UTF8String );
    }

    NSFileHandle *fileHandle = [NSFileHandle fileHandleForWritingAtPath:fileName];
    if (fileHandle){
        [fileHandle seekToEndOfFile];
        [fileHandle writeData:[entry dataUsingEncoding:NSUTF8StringEncoding]];
        [fileHandle closeFile];
    }
    else{
        [entry writeToFile:fileName
                atomically:NO
                  encoding:NSStringEncodingConversionAllowLossy
                     error:nil];
    }
}

@end
