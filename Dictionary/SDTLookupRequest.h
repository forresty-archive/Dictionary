//
//  LookupRequest.h
//  Dictionary
//
//  Created by Forrest Ye on 6/28/13.
//
//

#import <Foundation/Foundation.h>

@class SDTLookupResponse;

typedef void(^DictionaryLookupProgress)(SDTLookupResponse* response);


@interface SDTLookupRequest : NSObject


- (void)startLookingUpDictionaryWithTerm:(NSString *)term existingTerms:(NSArray *)existingTerms batchCount:(NSUInteger)batchCount progressBlock:(DictionaryLookupProgress)block;

- (void)startLookingUpDictionaryWithTerm:(NSString *)term existingTerms:(NSArray *)existingTerms progressBlock:(DictionaryLookupProgress)block;

@end
