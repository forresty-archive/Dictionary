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


- (void)startLookingUpDictionaryWithTerm:(NSString *)term batchCount:(NSUInteger)batchCount progressBlock:(DictionaryLookupProgress)block {

  [self.completionLookupOperationQueue cancelAllOperations];

  NSBlockOperation *operation = [[NSBlockOperation alloc] init];
  __weak NSBlockOperation *weakOperation = operation;

  NSMutableArray *terms = [@[] mutableCopy];

  [operation addExecutionBlock:^{

    [NSThread sleepForTimeInterval:0.3];

    if ([weakOperation isCancelled]) {
      return;
    }

    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
      block([LookupResponse responseWithProgressState:DictionaryLookupProgressStateLookingUpCompletionsButNoResultYet terms:terms]);
    }];

    if ([self.dictionary hasDefinitionForTerm:term]) {
      [terms addObject:term];

      if (![weakOperation isCancelled]) {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
          block([LookupResponse responseWithProgressState:DictionaryLookupProgressStateHasPartialResults terms:terms]);
        }];
      }
    }

    if ([weakOperation isCancelled]) {
      return;
    }

    for (NSString *completion in [self.dictionary completionsForTerm:term]) {
      if ([weakOperation isCancelled]) {
        break;
      }

      if (![term isEqualToString:completion] && [self.dictionary hasDefinitionForTerm:completion]) {
        [terms addObject:completion];
      }

      // send in batch
      if ([terms count] % batchCount == 3) {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
          block([LookupResponse responseWithProgressState:DictionaryLookupProgressStateHasPartialResults terms:terms]);
        }];
      }
    }

    if (![weakOperation isCancelled]) {
      [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        if (terms.count > 0) {
          block([LookupResponse responseWithProgressState:DictionaryLookupProgressStateFinishedWithCompletions terms:terms]);
        } else {
          block([LookupResponse responseWithProgressState:DictionaryLookupProgressStateFinishedWithNoResultsAtAll terms:terms]);
        }
      }];
    }
  }];

  [self.completionLookupOperationQueue addOperation:operation];
}


@end
