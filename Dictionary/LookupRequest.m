//
//  LookupRequest.m
//  Dictionary
//
//  Created by Forrest Ye on 6/28/13.
//
//

#import "LookupRequest.h"
#import "Dictionary.h"


@interface LookupRequest ()

@property NSOperationQueue *completionLookupOperationQueue;

@property Dictionary *dictionary;

@end


@implementation LookupRequest


- (instancetype)init {
  self = [super init];
  if (self) {
    _lookingUpCompletions = NO;
    _hasResults = NO;

    _completionLookupOperationQueue = [[NSOperationQueue alloc] init];

    _dictionary = [Dictionary sharedInstance];
  }

  return self;
}


- (void)startLookingUpDictionaryWithTerm:(NSString *)term batchCount:(NSUInteger)batchCount progressBlock:(DictionaryLookupPartialResult)block {
  self.lookingUpCompletions = YES;
  self.hasResults = NO;

  [self.completionLookupOperationQueue cancelAllOperations];

  NSBlockOperation *operation = [[NSBlockOperation alloc] init];
  __weak NSBlockOperation *weakOperation = operation;

  [operation addExecutionBlock:^{

    [NSThread sleepForTimeInterval:0.3];

    if ([weakOperation isCancelled]) {
      return;
    }

    if ([self.dictionary hasDefinitionForTerm:term]) {
      if (![weakOperation isCancelled]) {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
          self.hasResults = YES;
          block(@[term]);
        }];
      }
    }

    if ([weakOperation isCancelled]) {
      return;
    }

    NSMutableArray *partialResults = [@[] mutableCopy];

    for (NSString *completion in [self.dictionary completionsForTerm:term]) {
      if ([weakOperation isCancelled]) {
        break;
      }

      if (![term isEqualToString:completion] && [self.dictionary hasDefinitionForTerm:completion]) {
        [partialResults addObject:completion];
      }

      // send in batch
      if ([partialResults count] >= batchCount) {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
          self.hasResults = YES;
          block(partialResults);
        }];
        partialResults = [@[] mutableCopy];
      }
    }

    if (![weakOperation isCancelled]) {
      [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        self.hasResults = YES;
        self.lookingUpCompletions = NO;
        block(partialResults);
      }];
    }
  }];

  [self.completionLookupOperationQueue addOperation:operation];
}


@end
