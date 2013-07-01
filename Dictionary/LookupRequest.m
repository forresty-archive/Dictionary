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

    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
      LookupResponse *response = [[LookupResponse alloc] init];
      response.lookupState = DictionaryLookupProgressStateLookingUpCompletionsButNoResultYet;
      response.terms = terms;
      block(response);
    }];

    [NSThread sleepForTimeInterval:0.3];

    if ([weakOperation isCancelled]) {
      return;
    }

    if ([self.dictionary hasDefinitionForTerm:term]) {
      if (![weakOperation isCancelled]) {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
          [terms addObject:term];
          LookupResponse *response = [[LookupResponse alloc] init];
          response.lookupState = DictionaryLookupProgressStateHasPartialResults;
          response.terms = terms;
          block(response);
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
          LookupResponse *response = [[LookupResponse alloc] init];
          response.lookupState = DictionaryLookupProgressStateHasPartialResults;
          response.terms = terms;
          block(response);
        }];
      }
    }

    if (![weakOperation isCancelled]) {
      [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        LookupResponse *response = [[LookupResponse alloc] init];
        response.terms = terms;

        if (terms.count > 0) {
          response.lookupState = DictionaryLookupProgressStateFinishedWithCompletions;
        } else {
          response.lookupState = DictionaryLookupProgressStateFinishedWithNoResultsAtAll;
        }

        block(response);
      }];
    }
  }];

  [self.completionLookupOperationQueue addOperation:operation];
}


@end
