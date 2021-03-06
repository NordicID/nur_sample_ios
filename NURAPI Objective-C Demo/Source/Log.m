
#import "Log.h"

void logDebug(NSString * format, ...) {
    va_list args;
    va_start(args, format);
    NSString * formatted = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);

    [[Log sharedInstance] debug:formatted];
}

void logError(NSString * format, ...) {
    va_list args;
    va_start(args, format);
    NSString * formatted = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);

    [[Log sharedInstance] error:formatted];
}


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
        self.logToFile = NO;
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
    if ( self.logToConsole ) {
        printf("%s", entry.UTF8String );
    }

    if ( self.logToFile ) {
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        NSString *fileName = [documentsDirectory stringByAppendingPathComponent:@"log.txt"];

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
}

@end
