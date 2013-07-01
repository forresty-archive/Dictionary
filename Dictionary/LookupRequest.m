//
//  LookupRequest.m
//  Dictionary
//
//  Created by Forrest Ye on 6/28/13.
//
//

#import "LookupRequest.h"
#import "Dictionary.h"
#import "LookupResponse.h"


@interface LookupRequest ()

@property NSOperationQueue *completionLookupOperationQueue;

@property Dictionary *dictionary;

@end


@implementation LookupRequest


- (instancetype)init {
  self = [super init];
  if (self) {

    _completionLookupOperationQueue = [[NSOperationQueue alloc] init];

    _dictionary = [Dictionary sharedInstance];
  }

  return self;
}


- (void)startLookingUpDictionaryWithTerm:(NSString *)term existingTerms:(NSArray *)existingTerms progressBlock:(DictionaryLookupProgress)block {
  [self startLookingUpDictionaryWithTerm:term existingTerms:existingTerms batchCount:5 progressBlock:block];
}


- (void)startLookingUpDictionaryWithTerm:(NSString *)term existingTerms:(NSArray *)existingTerms batchCount:(NSUInteger)batchCount progressBlock:(DictionaryLookupProgress)block {

  [self.completionLookupOperationQueue cancelAllOperations];

  NSBlockOperation *operation = [[NSBlockOperation alloc] init];
  __weak NSBlockOperation *weakOperation = operation;

  [operation addExecutionBlock:^{

    NSMutableArray *terms = [self filteredSearchResultForSearchString:term existingTerms:existingTerms];

    if (terms.count > 0) {
      block([LookupResponse responseWithProgressState:DictionaryLookupProgressStateHasPartialResults terms:terms]);
    } else {
      block([LookupResponse responseWithProgressState:DictionaryLookupProgressStateLookingUpCompletionsButNoResultYet terms:terms]);
    }

    [NSThread sleepForTimeInterval:0.3];

    if ([weakOperation isCancelled]) {
      return;
    }

    if ([self.dictionary hasDefinitionForTerm:term]) {
      [terms addObject:term];

      if (![weakOperation isCancelled]) {
        block([LookupResponse responseWithProgressState:DictionaryLookupProgressStateHasPartialResults terms:terms]);
      }
    }

    if ([weakOperation isCancelled]) {
      return;
    }

    for (NSString *completion in [self.dictionary completionsForTerm:term]) {
      if ([weakOperation isCancelled]) {
        break;
      }

      if ([self.dictionary hasDefinitionForTerm:completion]) {
        [terms addObject:completion];
      }

      // send in batch
      if ([terms count] % batchCount == 0) {
        block([LookupResponse responseWithProgressState:DictionaryLookupProgressStateHasPartialResults terms:terms]);
      }
    }

    if (![weakOperation isCancelled]) {
      if (terms.count > 0) {
        block([LookupResponse responseWithProgressState:DictionaryLookupProgressStateFinishedWithCompletions terms:terms]);
      } else {
        block([LookupResponse responseWithProgressState:DictionaryLookupProgressStateFoundNoCompletionsLookingUpGuessesButNoResultsYet terms:terms]);

        for (NSString *guess in [self.dictionary guessesForTerm:term]) {
          if ([weakOperation isCancelled]) {
            break;
          }

          if ([self.dictionary hasDefinitionForTerm:guess]) {
            [terms addObject:guess];
          }
        }

        if ([weakOperation isCancelled]) {
          return;
        }

        if (terms.count > 0) {
          block([LookupResponse responseWithProgressState:DictionaryLookupProgressStateFinishedWithGuesses terms:terms]);
        } else {
          block([LookupResponse responseWithProgressState:DictionaryLookupProgressStateFinishedWithNoResultsAtAll terms:terms]);
        }
      }
    }
  }];

  [self.completionLookupOperationQueue addOperation:operation];
}


# pragma mark - private


- (NSMutableArray *)filteredSearchResultForSearchString:(NSString *)searchString existingTerms:(NSArray *)existingTerms {
  NSMutableArray *result = [@[] mutableCopy];

  for (NSString *word in existingTerms) {
    if ([word hasPrefix:searchString]) {
      [result addObject:word];
    }
  }

  return result;
}


@end
