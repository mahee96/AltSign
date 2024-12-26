//
//  ALTCertificateRequest.h
//  AltSign
//
//  Created by Riley Testut on 5/21/19.
//  Copyright © 2019 Riley Testut. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ALTCertificateRequest : NSObject

@property (nonatomic, copy, readonly, nonnull) NSData *data;
@property (nonatomic, copy, readonly, nonnull) NSData *privateKey;

// Can't mark init nullable without warnings, so use factory method instead.
+ (nullable instancetype)newRequest NS_SWIFT_NAME(ALTCertificateRequest.makeRequest());

- (instancetype)init NS_UNAVAILABLE;

@end
