//
//  LookupResponse.h
//  Dictionary
//
//  Created by Forrest Ye on 7/1/13.
//
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, DictionaryLookupProgressState) {
  // idle, initial state
  DictionaryLookupProgressStateIdle,

  // started looking up completions, but no results yet
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



@interface LookupResponse : NSObject


@property (nonatomic) DictionaryLookupProgressState lookupState;

@property (nonatomic) NSArray *terms;

+ (LookupResponse *)responseWithProgressState:(DictionaryLookupProgressState)state terms:(NSArray *)terms;


@end
