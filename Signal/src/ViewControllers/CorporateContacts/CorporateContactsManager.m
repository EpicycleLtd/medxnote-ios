//
//  CorporateContactsManager.m
//  Medxnote
//
//  Created by Jan Nemecek on 5/7/18.
//  Copyright © 2018 Open Whisper Systems. All rights reserved.
//

#import "CorporateContactsManager.h"
#import "LDAPContact.h"
#import "TSNetworkManager.h"
#import "TSLDAPTokenRequest.h"
#import <AFNetworking/AFNetworking.h>

@interface CorporateContactsManager ()

@property (nonatomic, strong) NSString *phoneNumber;
@property (nonatomic, strong) NSString *password;
@property (nonatomic, strong) AFHTTPSessionManager *sessionManager;
    
@property (nonatomic, strong) NSString *ldapToken;
@property (nonatomic, strong) NSString *cid;

@property (nonatomic, strong) NSArray <LDAPContact *> *contacts;

@end

@implementation CorporateContactsManager

- (instancetype)initWithLocalNumber:(NSString *)number {
    self = [super init];
    self.phoneNumber = number;
    self.password = [NSUUID UUID].UUIDString;
    self.contacts = @[];
    self.sessionManager = [[AFHTTPSessionManager alloc] initWithBaseURL:[NSURL URLWithString:@"https://openldap.s1z.info"]];
    self.sessionManager.requestSerializer = [AFJSONRequestSerializer serializer];
    [self.sessionManager.requestSerializer setAuthorizationHeaderFieldWithUsername:self.phoneNumber password:self.password];
    [self loadContacts];
    return self;
}

- (void)loadContacts {
    TSLDAPTokenRequest *request = [[TSLDAPTokenRequest alloc] init];
    [TSNetworkManager.sharedManager makeRequest:request
                                        success:^(NSURLSessionDataTask * _Nonnull task, id  _Nonnull responseObject) {
                                            NSDictionary *response = responseObject;
                                            self.ldapToken = response[@"token"];
                                            NSLog(@"SIGNAL TOKEN: %@", self.ldapToken);
                                            [self registerWithSignalToken:self.ldapToken];
                                        }
                                        failure:^(NSURLSessionDataTask * _Nonnull task, NSError * _Nonnull error) {
                                            NSLog(@"ERROR: %@", error.localizedDescription);
                                        }];
}

- (void)registerWithSignalToken:(NSString *)token {
    [self.sessionManager POST:[NSString stringWithFormat:@"json2ldap/registration/%@", token]
                   parameters:nil
                     progress:^(NSProgress * _Nonnull downloadProgress) {}
                      success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                          NSLog(@"LDAP REGISTRATION RESPONSE: %@", responseObject);
                          [self connectLdap];
                      }
                      failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                          NSLog(@"ERROR REGISTERING WITH LDAP: %@", error.localizedDescription);
                      }];
}
    
- (void)connectLdap {
    NSDictionary *params = @{
                             @"method": @"ldap.connect",
                             @"params": @{
                                     @"host": @"localhost",
                                     @"port": @(389),
                                     @"simpleBind" : @{
                                             @"DN": [NSString stringWithFormat:@"cn=%@,ou=users,dc=openldap,dc=medxnote,dc=com", [self.phoneNumber stringByReplacingOccurrencesOfString:@"+" withString:@"%2B"]],
                                             @"password": self.password
                                             }
                                     },
                             @"id": @(1),
                             @"jsonrpc": @"2.0"
                             };
    NSLog(@"CONNECTING WITH PARAMS: %@", params);
    [self.sessionManager POST:@"json2ldap/" parameters:params progress:^(NSProgress * _Nonnull uploadProgress) {
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        NSDictionary *response = responseObject;
        NSDictionary *result = response[@"result"];
        self.cid = result[@"CID"];
        NSLog(@"LDAP CONNECTION RESPONSE: %@", responseObject);
        [self loadLdapContacts];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"ERROR CONNECTING TO LDAP: %@", error.localizedDescription);
    }];
}
    
- (void)loadLdapContacts {
    NSDictionary *params = @{
                             @"method": @"ldap.search",
                             @"params": @{
                                     @"CID": self.cid,
                                     @"baseDN": @"ou=contacts,dc=openldap,dc=medxnote,dc=com",
                                     @"scope": @"SUBORDINATES",
                                     @"filter": @"(objectClass=medxOrgPerson)"
                                     },
                             @"id": @(1),
                             @"jsonrpc": @"2.0"
                             };
    NSLog(@"LOADING WITH PARAMS: %@", params);
    [self.sessionManager POST:@"json2ldap/" parameters:params progress:^(NSProgress * _Nonnull uploadProgress) {
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        NSDictionary *response = responseObject;
        NSArray *contactsJson = response[@"result"][@"matches"];
        NSMutableArray *results = [NSMutableArray new];
        for (NSDictionary *contactJson in contactsJson) {
            LDAPContact *contact = [[LDAPContact alloc] initWithDictionary:contactJson];
            [results addObject:contact];
        }
        self.contacts = results.copy;
        NSLog(@"LDAP CONTACTS RESPONSE: %@", self.contacts);
        [self.delegate didReceiveContacts:self.contacts];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"ERROR LOADING LDAP CONTACTS: %@", error.localizedDescription);
    }];
}

@end
