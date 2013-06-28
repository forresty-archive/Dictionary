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

@property BOOL lookingUpCompletions;

- (void)startLookingUpDictionaryWithTerm:(NSString *)term progressBlock:(DictionaryLookupPartialResult)block;

@end
