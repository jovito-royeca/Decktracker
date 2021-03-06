//
//  Constants.h
//  Decktracker
//
//  Created by Jovit Royeca on 8/2/14.
//  Copyright (c) 2014 Jovito Royeca. All rights reserved.
//

#ifndef Decktracker_Magic_h
#define Decktracker_Magic_h

#define kManaSymbols                   @[@"0", @"1", @"2", @"3", @"4", @"5", @"6", @"7", @"8", @"9", \
                                         @"10", @"11", @"12", @"13", @"14", @"15", @"16", @"17", \
                                         @"18", @"19", @"20", @"100", @"1000000", @"W", @"U", @"B", \
                                         @"R", @"G", @"S", @"X", @"Y", @"Z", @"WU", @"WB", @"UB", \
                                         @"UR", @"BR", @"BG", @"RG", @"RW", @"GW", @"GU", @"2W", \
                                         @"2U", @"2B", @"2R", @"2G", @"P", @"PW", @"PU", @"PB", \
                                         @"PR", @"PG", @"Infinity", @"H", @"HW", @"HU", @"HB", \
                                         @"HR", @"HG"]


#define kOtherSymbols                   @[@"T", @"Q", @"C", @"artifact", @"creature", \
                                         @"enchantment", @"instant", @"land", @"multiple", \
                                         @"planeswalker", @"sorcery", @"power", @"toughness", \
                                         @"chaosdice", @"planeswalk", @"forwardslash", @"tombstone"]

#define kImageSizes                     @[@"16", @"32", @"48", @"64", @"96"]

#define CARD_TYPES                      @[@"Artifact", @"Conspiracy", @"Creature", \
                                          @"Enchantment", @"Instant", @"Land", \
                                          @"Phenomenon", @"Plane", \
                                          @"Planeswalker", @"Scheme", @"Sorcery", \
                                          @"Tribal", @"Vanguard"]

#define CARD_TYPES_WITH_SYMBOL          @[@"Artifact", @"Creature", \
                                          @"Enchantment", @"Instant", @"Land", \
                                          @"Planeswalker", @"Sorcery"]


#define CARD_COLORS                      @[@"Black", @"Blue", \
                                           @"Green", @"Red", @"White"]

#define TCGPLAYER_PARTNER_KEY           @"DECKTRACKER"
#define TCGPLAYER_FETCH_STORAGE         24*3 // 3 days
#define PARSE_FETCH_STORAGE             24*3 // 3 days

#define EIGHTH_EDITION_RELEASE          @"2003-07-28" //@"YYYY-MM-dd"

// In-App Purchase
#define COLLECTIONS_IAP_PRODUCT_ID      @"Collections_ID"

typedef NS_ENUM(NSInteger, EditMode)
{
    EditModeNew,
    EditModeEdit
};

#define kCardInfoViewIdentifier          @"kCardInfoViewIdentifier"

#define kCardViewMode                    @"kCardViewMode"
#define kCardViewModeList                @"List"
#define kCardViewModeGrid2x2             @"2x2"
#define kCardViewModeGrid3x3             @"3x3"

// Keys
#define kAppID                           @"913992761"

#define kDropboxID                       @"v57bkxsnzi3gxt3"
#define kDropBoxSecret                   @"qbyj5znuytk3ljj"

#define kGoogleDriveID                   @"885791360366-rvgaob5mp4vpsghbilg7mrfqc1lsind8.apps.googleusercontent.com"
#define kGoogleDriveSecret               @"zqynI0KVtpRhl6JVd5RrSP82"
#define kGoogleDriveKeychain             @"Decktracker"
#define kGAITrackingID                   @"UA-53780226-1"

#define kParseID                         @"gWQ4zjHnoXHJK15ipFVgWLUSA979mqHaZ7sOlPU9"
#define kParseClientKey                  @"VVX6xrtslagHUKOSBXV3hj0B0i08izWSk53gSGem"
#define kParseDevelopID                  @"mKMQ9Hl7eGJJIwWb77WYyLfr7GpvsmuNKgGRRZyR"
#define kParseDevelopClientKey           @"lfho62cNW9M5HuEfhJ2HK7RuVKIlNmLfFo7bnyd5"


#define kTwitterKey                      @"M9SYMK8TAvUxFVpa6qVOAH8Bb"
#define kTwitterSecret                   @"xOlE7XZgtTeM8LVmXYZ5xtxvOZXBrupYNYLOzHtkIuZpCzEWBf"

#endif
