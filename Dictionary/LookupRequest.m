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

- (void)startLookingUpDictionaryWithTerm:(NSString *)term progressBlock:(DictionaryLookupPartialResult)block {
  _lookingUpCompletions = YES;
  [__completionLookupOperationQueue cancelAllOperations];

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
          block(@[term]);
        }];
      }
    }

    if ([weakOperation isCancelled]) {
      return;
    }

    NSMutableArray *partialResults = [@[] mutableCopy];

    for (NSString *completion in [__dictionary completionsForTerm:term]) {
      if ([weakOperation isCancelled]) {
        break;
      }

      if (![term isEqualToString:completion] && [__dictionary hasDefinitionForTerm:completion]) {
        [partialResults addObject:completion];
      }

      // send in batch
      if ([partialResults count] >= kDictionaryLookupResultBatchCount) {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
          _lookingUpCompletions = NO;
          block(partialResults);
        }];
        partialResults = [@[] mutableCopy];
      }
    }

    if (![weakOperation isCancelled]) {
      [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        _lookingUpCompletions = NO;
        block(partialResults);
      }];
    }
  }];

  [__completionLookupOperationQueue addOperation:operation];
}





@end
