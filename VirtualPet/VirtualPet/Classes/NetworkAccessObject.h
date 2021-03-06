//
//  NerworkAccessObject.h
//  VirtualPet
//
//  Created by Ezequiel on 11/26/14.
//  Copyright (c) 2014 Ezequiel. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^Success)(NSURLSessionDataTask*, id);
typedef void (^Failure)(NSURLSessionDataTask*, NSError*);

extern NSString* const CODE_IDENTIFIER;

@interface NetworkAccessObject : NSObject

- (void) doGETPetInfo: (Success) block;
- (void) doGETPetInfoByCode: (NSString*) code withBlock: (Success) block;
- (void) doGETPetList: (Success) block;
- (void) doPOSTPetUpdate: (Success) block;
- (void) cancelCurrentTask;

@end
