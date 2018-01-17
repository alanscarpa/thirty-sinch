#import <CallKit/CallKit.h>
#import <Foundation/Foundation.h>

@protocol SINClient;
@protocol SINCall;

@interface SINCallKitProvider : NSObject <CXProviderDelegate>

- (instancetype)initWithClient:(id<SINClient>)client;

- (void)reportNewIncomingCall:(id<SINCall>)call;

- (void)reportCallEnded:(id<SINCall>)call;

- (BOOL)callExists:(id<SINCall>)call;

- (id<SINCall>)currentEstablishedCall;

@end
