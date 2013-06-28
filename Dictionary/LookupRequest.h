//
//  LookupRequest.h
//  Dictionary
//
//  Created by Forrest Ye on 6/28/13.
//
//

#import <Foundation/Foundation.h>

typedef void(^DictionaryPartialResult)(NSArray *partialResults);

@interface LookupRequest : NSObject

//@property NSArray *completions;
@property BOOL lookingUpCompletions;

- (void)startLookingUpDictionaryWithTerm:(NSString *)term progress:(DictionaryPartialResult)progress;

@end
