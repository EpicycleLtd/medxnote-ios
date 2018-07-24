//
//  LDAPContact.h
//  Medxnote
//
//  Created by Jan Nemecek on 24/7/18.
//  Copyright © 2018 Open Whisper Systems. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LDAPContact : NSObject

@property (nonatomic, assign) BOOL isPinned;
@property (nonatomic, strong) NSString *displayName;
@property (nonatomic, strong) NSString *firstName;
@property (nonatomic, strong) NSString *lastName;
@property (nonatomic, strong) NSString *hospitalName;
@property (nonatomic, strong) NSString *dn;

// optional
@property (nonatomic, strong) NSString *clientNumber;
@property (nonatomic, strong) NSString *position;
@property (nonatomic, strong) NSString *speciality;
@property (nonatomic, strong) NSString *subSpeciality;
@property (nonatomic, strong) NSString *team;
@property (nonatomic, strong) NSString *letters;
@property (nonatomic, strong) NSString *division;
@property (nonatomic, strong) NSString *salutation;
@property (nonatomic, strong) NSString *userDefinedData;

- (instancetype)initWithDictionary:(NSDictionary *)json;

@end
