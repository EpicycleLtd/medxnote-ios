//
//  Copyright (c) 2017 Open Whisper Systems. All rights reserved.
//

#import <UIKit/UIKit.h>

// Any view controller which wants to be able cancel back button
// presses and back gestures should implement this protocol.
@protocol OWSNavigationView <NSObject>

// shouldCancelNavigationBack will be called if the back button was pressed or
// if a back gesture was performed but not if the view is popped programmatically.
- (BOOL)shouldCancelNavigationBack;

@end

#pragma mark -

// This navigation controller subclass should be used anywhere we might
// want to cancel back button presses or back gestures due to, for example,
// unsaved changes.
@interface OWSNavigationController : UINavigationController

@property (nonatomic, assign) BOOL rotationEnabled;

@end
