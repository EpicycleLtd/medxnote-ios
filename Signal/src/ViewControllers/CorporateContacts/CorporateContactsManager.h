//
//  CorporateContactsManager.h
//  Medxnote
//
//  Created by Jan Nemecek on 5/7/18.
//  Copyright © 2018 Open Whisper Systems. All rights reserved.
//

#import <Foundation/Foundation.h>

@class LDAPContact;

@protocol CorporateContactsManagerDelegate

- (void)didReceiveContacts:(NSArray <LDAPContact *> *)contacts;

@end

@interface CorporateContactsManager : NSObject

@property (nonatomic, weak) id<CorporateContactsManagerDelegate> delegate;

- (instancetype)initWithLocalNumber:(NSString *)number;

@end
