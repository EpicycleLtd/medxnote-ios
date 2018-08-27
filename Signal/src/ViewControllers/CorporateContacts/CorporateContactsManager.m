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

NSString *const kLdapCidKey = @"ldapCid";
NSString *const kLdapPasswordKey = @"ldapPassword";

@interface CorporateContactsManager ()

@property (nonatomic, strong) NSString *phoneNumber;
@property (nonatomic, strong) NSString *password;
@property (nonatomic, strong) AFHTTPSessionManager *sessionManager;
    
@property (nonatomic, strong) NSString *ldapToken;
@property (nonatomic, strong) NSString *cid;

@end

@implementation CorporateContactsManager

- (instancetype)initWithLocalNumber:(NSString *)number {
    self = [super init];
    self.phoneNumber = number;
    self.password = [NSUserDefaults.standardUserDefaults objectForKey:kLdapPasswordKey];
    if (!self.password)
        self.password = [NSUUID UUID].UUIDString;
    _cid = [NSUserDefaults.standardUserDefaults objectForKey:kLdapCidKey];
    self.sessionManager = [[AFHTTPSessionManager alloc] initWithBaseURL:[NSURL URLWithString:@"https://openldap.s1z.info"]];
    self.sessionManager.requestSerializer = [AFJSONRequestSerializer serializer];
    [self.sessionManager.requestSerializer setAuthorizationHeaderFieldWithUsername:self.phoneNumber password:self.password];
    [self registerSignalToken];
    NSArray *cached = [self cachedContacts];
    if (cached)
        [self.delegate didReceiveContacts:cached];
    
    return self;
}

- (void)setCid:(NSString *)cid {
    if (!cid) {
        // regenerate password on cid update
        self.password = [NSUUID UUID].UUIDString;
    }
    _cid = cid;
    [self onCidUpdate];
}

- (void)onCidUpdate {
    [NSUserDefaults.standardUserDefaults setObject:self.password forKey:kLdapPasswordKey];
    [NSUserDefaults.standardUserDefaults setObject:self.cid forKey:kLdapCidKey];
    [NSUserDefaults.standardUserDefaults synchronize];
}

- (void)registerSignalToken {
    if (self.cid) {
        [self connectLdap];
        return;
    }
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
    if (self.cid) {
        [self connectLdap];
        return;
    }
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
        NSLog(@"LDAP CONNECTION RESPONSE: %@", responseObject);
        if (!response[@"result"]) {
            // TODO: add retry count here so it doesn't reconnect indefinitely
            [self registerSignalToken];
            return;
        }
        NSDictionary *result = response[@"result"];
        self.cid = result[@"CID"];
        [self onCidUpdate];
        [self loadLdapContacts];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"ERROR CONNECTING TO LDAP: %@", error.localizedDescription);
    }];
}
    
- (void)loadLdapContacts {
    if (!self.cid) {
        [self connectLdap];
        return;
    }
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
        if (!response[@"result"]) {
            // attempt reconnection without a stored CID so we get a new one
            if (self.cid) {
                self.cid = nil;
                [self registerSignalToken];
            }
            return;
        }
        NSArray *contactsJson = response[@"result"][@"matches"];
        // cache locally
        [self storeContactsJson:contactsJson];
        NSMutableArray *results = [NSMutableArray new];
        for (NSDictionary *contactJson in contactsJson) {
            LDAPContact *contact = [[LDAPContact alloc] initWithDictionary:contactJson];
            [results addObject:contact];
        }
        NSLog(@"LDAP CONTACTS RESPONSE: %@", results);
        [self.delegate didReceiveContacts:results.copy];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"ERROR LOADING LDAP CONTACTS: %@", error.localizedDescription);
    }];
}

#pragma mark - Cache

- (void)storeContactsJson:(NSArray <NSDictionary *> *)contactsJson {
    [NSUserDefaults.standardUserDefaults setObject:contactsJson forKey:@"ldap_contacts"];
    [NSUserDefaults.standardUserDefaults synchronize];
}

- (NSArray <LDAPContact *> *)cachedContacts {
    NSArray *contactsJson = [NSUserDefaults.standardUserDefaults objectForKey:@"ldap_contacts"];
    if (!contactsJson)
        return nil;
    NSMutableArray *results = [NSMutableArray new];
    for (NSDictionary *contactJson in contactsJson) {
        LDAPContact *contact = [[LDAPContact alloc] initWithDictionary:contactJson];
        [results addObject:contact];
    }
    return results.copy;
}

@end
