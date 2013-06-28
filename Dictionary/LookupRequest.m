//
//  LookupRequest.m
//  Dictionary
//
//  Created by Forrest Ye on 6/28/13.
//
//

#import "LookupRequest.h"
#import "Dictionary.h"

#define kDictionaryLookupResultBatchCount 3


@implementation LookupRequest {
@private
  __strong NSOperationQueue *__completionLookupOperationQueue;

  Dictionary *__dictionary;
}

- (instancetype)init {
  self = [super init];
  if (self) {
    _lookingUpCompletions = NO;

    __completionLookupOperationQueue = [[NSOperationQueue alloc] init];

    __dictionary = [Dictionary sharedInstance];
  }

  return self;
}

- (void)startLookingUpDictionaryWithTerm:(NSString *)term progress:(DictionaryPartialResult)progress {
  _lookingUpCompletions = YES;
  [__completionLookupOperationQueue cancelAllOperations];
//  self.completions = @[];

  NSBlockOperation *operation = [[NSBlockOperation alloc] init];
  __weak NSBlockOperation *weakOperation = operation;

  [operation addExecutionBlock:^{

    [NSThread sleepForTimeInterval:0.3];

    if ([weakOperation isCancelled]) {
      return;
    }

    if ([__dictionary hasDefinitionForTerm:term]) {
      if (![weakOperation isCancelled]) {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
          _lookingUpCompletions = NO;
//          self.completions = results;
          progress(@[term]);
        }];
      }
    }

    NSMutableArray *results = [@[] mutableCopy];

    if ([weakOperation isCancelled]) {
      return;
    }

    for (NSString *completion in [__dictionary completionsForTerm:term]) {
      if ([weakOperation isCancelled]) {
        break;
      }

      if (![term isEqualToString:completion] && [__dictionary hasDefinitionForTerm:completion]) {
        [results addObject:completion];
      }

      // send in batch
      if ([results count] % kDictionaryLookupResultBatchCount == 0) {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
          _lookingUpCompletions = NO;
//          self.completions = results;
          progress(results);
        }];
        results = [@[] mutableCopy];
      }
    }

    if (![weakOperation isCancelled]) {
      [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        _lookingUpCompletions = NO;
//        self.completions = results;
        progress(results);
      }];
    }
  }];

  [__completionLookupOperationQueue addOperation:operation];

}

@end
