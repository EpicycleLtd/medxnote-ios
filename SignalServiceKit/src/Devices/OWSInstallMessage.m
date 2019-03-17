//
//  OWSInstallMessage.m
//  SignalServiceKit
//
//  Created by Jan Nemeček on 3/17/19.
//

#import "OWSInstallMessage.h"
#import "NSDate+OWS.h"
#import "OWSSignalServiceProtos.pb.h"
#import "SignalRecipient.h"

@implementation OWSInstallMessage

#pragma mark - TSOutgoingMessage overrides

- (BOOL)shouldSyncTranscript
{
    return NO;
}

- (BOOL)isSilent
{
    // Avoid "phantom messages" for "recipient read receipts".
    
    return YES;
}

- (NSData *)buildPlainTextData:(SignalRecipient *)recipient
{
    OWSAssert(recipient);
    
    OWSSignalServiceProtosContentBuilder *contentBuilder = [OWSSignalServiceProtosContentBuilder new];
    contentBuilder.installMessage = [self buildMessage];
    return [[contentBuilder build] data];
}

- (OWSSignalServiceProtosInstallMessage *)buildMessage
{
    OWSSignalServiceProtosInstallMessageBuilder *builder = [OWSSignalServiceProtosInstallMessageBuilder new];
    [builder setType:OWSSignalServiceProtosInstallMessageTypeGroupRequest];
    
    return [builder build];
}

#pragma mark - TSYapDatabaseObject overrides

- (BOOL)shouldBeSaved
{
    return NO;
}

- (NSString *)debugDescription
{
    return [NSString stringWithFormat:@"%@ for current user", self.logTag];
}

@end
