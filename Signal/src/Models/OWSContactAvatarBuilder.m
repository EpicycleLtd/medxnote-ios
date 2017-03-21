//
//  Copyright (c) 2017 Open Whisper Systems. All rights reserved.
//

#import "OWSContactAvatarBuilder.h"
#import "OWSContactsManager.h"
#import "TSContactThread.h"
#import "TSGroupThread.h"
#import "TSThread.h"
#import "UIColor+OWS.h"
#import "UIFont+OWS.h"
#import <JSQMessagesViewController/JSQMessagesAvatarImageFactory.h>

NS_ASSUME_NONNULL_BEGIN

@interface OWSContactAvatarBuilder ()

@property (nonatomic, readonly) OWSContactsManager *contactsManager;
@property (nonatomic, readonly) NSString *signalId;
@property (nonatomic, readonly) NSString *contactName;

@end

@implementation OWSContactAvatarBuilder

- (instancetype)initWithContactId:(NSString *)contactId
                             name:(NSString *)name
                  contactsManager:(OWSContactsManager *)contactsManager
{
    self = [super init];
    if (!self) {
        return self;
    }

    _signalId = contactId;
    _contactName = name;
    _contactsManager = contactsManager;

    return self;
}


- (instancetype)initWithThread:(TSContactThread *)thread contactsManager:(OWSContactsManager *)contactsManager
{
    return [self initWithContactId:thread.contactIdentifier name:thread.name contactsManager:contactsManager];
}

- (nullable UIImage *)buildSavedImage
{
    return [self.contactsManager imageForPhoneIdentifier:self.signalId];
}

- (NSRange)makeRangeFrom:(NSUInteger)first to:(NSUInteger)last {
    OWSAssert(last >= first);
    
    return NSMakeRange(first, last + 1 - first);
}

- (UIImage *)buildDefaultImage
{
    UIImage *cachedAvatar = [self.contactsManager.avatarCache objectForKey:self.signalId];
    if (cachedAvatar) {
        return cachedAvatar;
    }

    NSMutableString *initials = [NSMutableString string];

    NSRange rangeOfLetters = [self.contactName rangeOfCharacterFromSet:[NSCharacterSet letterCharacterSet]];
    if (rangeOfLetters.location != NSNotFound) {
        // Contact name contains letters, so it's probably not just a phone number.
        // Make an image from the contact's initials
        
        // We onl
        NSMutableCharacterSet *excludeAlphanumeric = [[NSCharacterSet alphanumericCharacterSet].invertedSet mutableCopy];
        // Remove Emoji. alphanumericCharacterSet unfortunately contains emoji.
        //
        // To be complete, we should filter (almost) all of the emoji listed in
        // the unicode standard's latest emoji list:
        //
        // http://www.unicode.org/Public/emoji/
        //
        // Dingbats: 2700–27BF
        [excludeAlphanumeric addCharactersInRange:[self makeRangeFrom:0x2700 to:0x27BF]];
        // Ornamental Dingbats: 1F650–1F67F
        [excludeAlphanumeric addCharactersInRange:[self makeRangeFrom:0x1F650 to:0x1F67F]];
        // Emoticons: 1F600–1F64F
        [excludeAlphanumeric addCharactersInRange:[self makeRangeFrom:0x1F600 to:0x1F64F]];
        // Miscellaneous Symbols: 2600–26FF
        [excludeAlphanumeric addCharactersInRange:[self makeRangeFrom:0x2600 to:0x26FF]];
        // Miscellaneous Symbols and Pictographs: 1F300–1F5FF
        [excludeAlphanumeric addCharactersInRange:[self makeRangeFrom:0x1F300 to:0x1F5FF]];
        // Supplemental Symbols and Pictographs: 1F900–1F9FF
        [excludeAlphanumeric addCharactersInRange:[self makeRangeFrom:0x1F900 to:0x1F9FF]];
        // Transport and Map Symbols: 1F680–1F6FF
        [excludeAlphanumeric addCharactersInRange:[self makeRangeFrom:0x1F680 to:0x1F6FF]];

        NSArray *words =
            [self.contactName componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        for (NSString *word in words) {
            NSString *trimmedWord = [word stringByTrimmingCharactersInSet:excludeAlphanumeric];
            if (trimmedWord.length > 0) {
                NSString *firstLetter = [trimmedWord substringToIndex:1];
                [initials appendString:[firstLetter uppercaseString]];
            }
        }

        NSRange stringRange = { 0, MIN([initials length], (NSUInteger)3) }; // Rendering max 3 letters.
        initials = [[initials substringWithRange:stringRange] mutableCopy];
    }

    if (initials.length == 0) {
        // We don't have a name for this contact, so we can't make an "initials" image
        [initials appendString:@"#"];
    }

    UIColor *backgroundColor = [UIColor backgroundColorForContact:self.signalId];
    UIImage *image = [[JSQMessagesAvatarImageFactory avatarImageWithUserInitials:initials
                                                                 backgroundColor:backgroundColor
                                                                       textColor:[UIColor whiteColor]
                                                                            font:[UIFont ows_boldFontWithSize:36.0]
                                                                        diameter:100] avatarImage];
    [self.contactsManager.avatarCache setObject:image forKey:self.signalId];
    return image;
}


@end

NS_ASSUME_NONNULL_END
