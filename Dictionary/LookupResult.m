//
//  LookupResult.m
//  Dictionary
//
//  Created by Forrest Ye on 6/25/13.
//
//

#import "LookupResult.h"
#import "Dictionary.h"

#define kDictionaryLookupResultBatchCount 3

@implementation LookupResult {
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

-(BOOL)guessing {
  return NO;
}

-(BOOL)lookingUpDefinition {
  return NO;
}

-(BOOL)hasCompletions {
  return [self lookingUpCompletions] == NO && [[self completions] count] > 0;
}

-(BOOL)hasGuesses {
  return [self guessing] == NO && [[self guesses] count] > 0;
}

-(BOOL)hasDefinition {
  return NO;
}

-(BOOL)partiallyDone {
  return [self hasCompletions] || [self hasDefinition] || [self hasGuesses];
}

-(BOOL)allDone {
  return [self guessing] == NO && [self lookingUpDefinition] == NO && [self lookingUpCompletions] == NO;
}

-(NSArray *)guesses {
  return @[];
}


-(void)startLookupCompletionsForSearchString:(NSString *)searchString {
  _lookingUpCompletions = YES;
  [__completionLookupOperationQueue cancelAllOperations];
  self.completions = @[];

  NSBlockOperation *operation = [[NSBlockOperation alloc] init];
  __weak NSBlockOperation *weakOperation = operation;

  [operation addExecutionBlock:^{
    NSMutableArray *results = [@[] mutableCopy];

    if ([__dictionary hasDefinitionForTerm:searchString]) {
      [results addObject:searchString];
    }

    if ([weakOperation isCancelled]) {
      return;
    }

    for (NSString *completion in [__dictionary completionsForTerm:searchString]) {
      if ([weakOperation isCancelled]) {
        break;
      }

      if (![results containsObject:completion] && [__dictionary hasDefinitionForTerm:completion]) {
        [results addObject:completion];
      }

      // send in batch
      if ([results count] % kDictionaryLookupResultBatchCount == 0) {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
          _lookingUpCompletions = NO;
          self.completions = results;
        }];
      }
    }

    if (![weakOperation isCancelled]) {
      [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        _lookingUpCompletions = NO;
        self.completions = results;
      }];
    }
  }];

  [__completionLookupOperationQueue addOperation:operation];
}

@end
