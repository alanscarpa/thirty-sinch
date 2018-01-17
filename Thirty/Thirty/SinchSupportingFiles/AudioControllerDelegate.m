#import "AudioControllerDelegate.h"

@interface AudioContollerDelegate ()
@property (atomic, readwrite) BOOL muted;
@end

@implementation AudioContollerDelegate

#pragma mark - SINAudioControllerDelegate

- (void)audioControllerMuted:(id<SINAudioController>)audioController {
  self.muted = YES;
}

- (void)audioControllerUnmuted:(id<SINAudioController>)audioController {
  self.muted = NO;
}

@end
