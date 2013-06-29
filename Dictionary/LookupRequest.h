//
//  LookupRequest.h
//  Dictionary
//
//  Created by Forrest Ye on 6/28/13.
//
//

#import <Foundation/Foundation.h>

typedef void(^DictionaryLookupPartialResult)(NSArray *partialResults);



@interface LookupRequest : NSObject


@property (nonatomic) BOOL lookingUpCompletions;

- (void)startLookingUpDictionaryWithTerm:(NSString *)term batchCount:(NSUInteger)batchCount progressBlock:(DictionaryLookupPartialResult)block;


@end
