//
//  SearchResult.h
//  medxnote
//
//  Created by Jan Nemecek on 28/11/17.
//  Copyright © 2017 Open Whisper Systems. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TSInteraction.h"
#import "TSThread.h"

@interface SearchResult : NSObject

@property TSThread *thread;
@property TSInteraction *interaction;

@end
