//
//  TSLDAPTokenRequest.m
//  Medxnote
//
//  Created by Jan Nemecek on 18/7/18.
//  Copyright © 2018 Open Whisper Systems. All rights reserved.
//

#import "TSLDAPTokenRequest.h"

@implementation TSLDAPTokenRequest

- (instancetype)init {
    self = [super initWithURL:[NSURL URLWithString:@"v1/accounts/token/ldap"]];
    self.HTTPMethod = @"GET";
    self.parameters = @{}.mutableCopy;
    return self;
}

@end
