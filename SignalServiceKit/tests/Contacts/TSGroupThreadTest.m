//
//  Copyright (c) 2017 Open Whisper Systems. All rights reserved.
//

#import <SignalServiceKit/TSGroupThread.h>
#import <XCTest/XCTest.h>

NS_ASSUME_NONNULL_BEGIN

@interface TSGroupThreadTest : XCTestCase

@end

@implementation TSGroupThreadTest

- (void)testHasSafetyNumbers
{
    TSGroupThread *groupThread = [TSGroupThread new];
    XCTAssertFalse(groupThread.hasSafetyNumbers);
}

@end

NS_ASSUME_NONNULL_END
