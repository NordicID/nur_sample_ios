
#import <AVFoundation/AVFoundation.h>

#import "AudioPlayer.h"

@interface AudioPlayer ()

@property (nonatomic, strong) NSArray * players;

@end

@implementation AudioPlayer

+ (AudioPlayer *) sharedInstance {
    static AudioPlayer * instance = nil;
    static dispatch_once_t onceToken;

    dispatch_once( &onceToken, ^{
        instance = [[AudioPlayer alloc] init];
    });

    // return the instance
    return instance;
}


- (instancetype)init {
    self = [super init];
    if (self) {

        // cache a audio players for each sample
        self.players = @[
                         [[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"blep_40ms"
                                                                                                                             ofType:@"wav"]]
                                                                error:nil],
                         [[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"blep_100ms"
                                                                                                                             ofType:@"wav"]]
                                                                error:nil],
                         [[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"blep_300ms"
                                                                                                                             ofType:@"wav"]]
                                                                error:nil],
                         [[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"blipblipblip"
                                                                                                                             ofType:@"wav"]]
                                                                error:nil],
                         ];
    }

    return self;
}


- (void) playSound:(SoundType)sound {
    AVAudioPlayer * player = self.players[ sound ];
    if ( ! player.isPlaying ) {
        [player play];
    }
}

@end
