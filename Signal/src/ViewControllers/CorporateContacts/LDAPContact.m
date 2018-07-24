//
//  LDAPContact.m
//  Medxnote
//
//  Created by Jan Nemecek on 24/7/18.
//  Copyright © 2018 Open Whisper Systems. All rights reserved.
//

#import "LDAPContact.h"

@implementation LDAPContact

- (instancetype)initWithDictionary:(NSDictionary *)json {
    self = [super init];
    if (self) {
        self.isPinned = [[(NSString *)[(NSArray *)json[@"pinned"] firstObject] lowercaseString] boolValue];
        self.displayName = (NSString *)[(NSArray *)json[@"displayName"] firstObject];
        self.firstName = (NSString *)[(NSArray *)json[@"firstName"] firstObject];
        self.lastName = (NSString *)[(NSArray *)json[@"lastName"] firstObject];
        self.hospitalName = (NSString *)[(NSArray *)json[@"hospitalName"] firstObject];
        self.dn = (NSString *)json[@"DN"];
        
        if (json[@"clientNumber"])
            self.clientNumber = (NSString *)[(NSArray *)json[@"clientNumber"] firstObject];
        if (json[@"position"])
            self.position = (NSString *)[(NSArray *)json[@"position"] firstObject];
        if (json[@"speciality"])
            self.speciality = (NSString *)[(NSArray *)json[@"speciality"] firstObject];
        if (json[@"subSpeciality"])
            self.subSpeciality = (NSString *)[(NSArray *)json[@"subSpeciality"] firstObject];
        if (json[@"team"])
            self.team = (NSString *)[(NSArray *)json[@"team"] firstObject];
        if (json[@"letters"])
            self.letters = (NSString *)[(NSArray *)json[@"letters"] firstObject];
        if (json[@"division"])
            self.division = (NSString *)[(NSArray *)json[@"division"] firstObject];
        if (json[@"salutation"])
            self.salutation = (NSString *)[(NSArray *)json[@"salutation"] firstObject];
        if (json[@"userDefinedData"])
            self.userDefinedData = (NSString *)[(NSArray *)json[@"userDefinedData"] firstObject];
    }
    return self;
}

@end
