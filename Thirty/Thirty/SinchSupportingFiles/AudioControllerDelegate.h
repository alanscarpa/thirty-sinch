#import <Foundation/Foundation.h>
#import <Sinch/Sinch.h>

@interface AudioContollerDelegate : NSObject <SINAudioControllerDelegate>
@property (atomic, readonly) BOOL muted;
@end
