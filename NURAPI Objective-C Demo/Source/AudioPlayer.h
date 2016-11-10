
#import <Foundation/Foundation.h>

// the sounds that can be played
typedef enum {
    kBlep40ms,
    kBlep100ms,
    kBlep300ms,
    kBlipBlipBlip
} SoundType;

@interface AudioPlayer : NSObject

@property (nonatomic, assign) BOOL soundsEnabled;

+ (AudioPlayer *) sharedInstance;

- (void) playSound:(SoundType)sound;

@end
