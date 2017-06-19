
#import <NurAPIBluetooth/Bluetooth.h>

#import "TagManager.h"
#import "Tag.h"

@interface TagManager ()

@property (nonatomic, strong, readwrite) NSMutableArray * tags;
@property (nonatomic, strong) NSMutableSet *              tagIds;

@end

@implementation TagManager {
    pthread_mutex_t mutex;
}

+ (TagManager *) sharedInstance {
    static TagManager * instance = nil;
    static dispatch_once_t onceToken;

    dispatch_once( &onceToken, ^{
        instance = [[TagManager alloc] init];
    });

    // return the instance
    return instance;
}


- (instancetype)init {
    self = [super init];
    if (self) {
        self.tags = [NSMutableArray array];
        self.tagIds = [NSMutableSet set];

        pthread_mutex_init(&mutex, NULL);
    }

    return self;
}


- (Tag *) getTag:(int)tagIndex {
    struct NUR_TAG_DATA tagData;
    int error = NurApiGetTagData( [Bluetooth sharedInstance].nurapiHandle, tagIndex, &tagData );
    if (error != NUR_NO_ERROR) {
        // failed to fetch tag
        return nil;
    }

    return [[Tag alloc] initWithEpc:[NSData dataWithBytes:tagData.epc length:tagData.epcLen]
                          frequency:tagData.freq
                               rssi:tagData.rssi
                         scaledRssi:tagData.scaledRssi
                          timestamp:tagData.timestamp
                            channel:tagData.channel
                          antennaId:tagData.antennaId];
}


- (BOOL) addTag:(Tag *)tag {
    [self lock];

    if ( tag && ! [self.tagIds containsObject:tag.hex ] ) {
        // a new tag
        [self.tags addObject:tag];
        [self.tagIds addObject:tag.hex];

        [self unlock];
        return YES;
    }

    // find our tag
    for ( Tag * old in self.tags ) {
        if ( [tag.hex isEqualToString:old.hex] ) {
            // found the old one
            old.foundCount++;
            old.lastFound = [NSDate date];
            break;
        }
    }

    [self unlock];
    return NO;
}


- (void) clear {
    [self lock];

    // simply clear all the tags we have
    [self.tags removeAllObjects];
    [self.tagIds removeAllObjects];

    [self unlock];
}


- (void) lock {
    pthread_mutex_lock(&mutex);
}


- (void) unlock {
    pthread_mutex_unlock(&mutex);
}


@end
