//
//  LookupRequest.h
//  Dictionary
//
//  Created by Forrest Ye on 6/28/13.
//
//

#import <Foundation/Foundation.h>

typedef void(^DictionaryLookupPartialResult)(NSArray *partialResults);

typedef NS_ENUM(NSUInteger, DictionaryLookupProgressState) {
  // start looking up completions, but no results yet
  DictionaryLookupProgressStateLookingUpCompletionsButNoResultYet,

  // still working on term completions, some results are found
  DictionaryLookupProgressStateHasPartialResults,

  // found no completions, looking up guesses, but no results yet
  DictionaryLookupProgressStateFoundNoCompletionsLookingUpGuessesButNoResultsYet,

  // finished, completions found
  DictionaryLookupProgressStateFinishedWithCompletions,

  // finished, can not find completions, but found guesses
  DictionaryLookupProgressStateFinishedWithGuesses,

  // finished, but no completions or guesses were found
  DictionaryLookupProgressStateFinishedWithNoResultsAtAll
};



@interface LookupRequest : NSObject


@property (nonatomic) BOOL lookingUpCompletions;

@property (nonatomic) BOOL hasResults;

- (void)startLookingUpDictionaryWithTerm:(NSString *)term batchCount:(NSUInteger)batchCount progressBlock:(DictionaryLookupPartialResult)block;


@end
