//
//  DictionaryTests.m
//  DictionaryTests
//
//  Created by Feng Ye on 11/18/11.
//  Copyright (c) 2011 @forresty. All rights reserved.
//

#import "DictionaryTests.h"
#import "Dictionary.h"

@implementation DictionaryTests {
@private
  Dictionary *_dictionary;
}

- (void)setUp {
  [super setUp];

  _dictionary = [Dictionary sharedInstance];
}

- (void)tearDown {
  // Tear-down code here.

  [super tearDown];
}

//- (void)testHasDefinitionForTerm {
//  NSAssert([_dictionary hasDefinitionForTerm:@"hello"], @"sanity test");
//}
//
//- (void)testGuessesForTerm {
//  NSArray *guesses = [_dictionary guessesForTerm:@"helo"];
//  NSAssert([guesses count] > 0, @"should have guesses");
//  NSAssert([guesses containsObject:@"hello"], @"sanity test");
//}
//
//- (void)testCompletionsForTerm {
//  NSArray *completions = [_dictionary completionsForTerm:@"histo"];
//  NSAssert([completions count] > 0, @"should have completions");
//  NSAssert([completions containsObject:@"history"], @"should include the term history");
//}
//
//- (void)testCompletionsForTermShouldIncludeTheTermItself {
//  NSArray *completions = [_dictionary completionsForTerm:@"history"];
//  NSLog(@"completions: %@", completions);
//  NSAssert([completions containsObject:@"history"], @"should include the term history");
//}


- (void)testAddCache {
//  NSMutableSet *terms = [NSMutableSet set];
//
//  for (int i=0; i < 26; i++) {
//    unsigned char c1 = 'a' + i;
//    [terms addObject:[NSString stringWithFormat:@"%c", c1]];
//    for (int j=0; j < 26; j++) {
//      unsigned char c2 = 'a' + j;
//      [terms addObject:[NSString stringWithFormat:@"%c%c", c1, c2]];
//      for (int k=0; k < 26; k++) {
//        unsigned char c3 = 'a' + k;
//        [terms addObject:[NSString stringWithFormat:@"%c%c%c", c1, c2, c3]];
//      }
//    }
//  }
//
//  NSLog(@"terms count %d", terms.count);

  NSMutableSet *terms = [[_dictionary validTermsCache] copy];

  [self addCacheWithCollection:terms];
}

- (void)addCacheWithCollection:(id)terms {
  int count = 0;
  for (NSString *term in terms) {
    @autoreleasepool {
      for (NSString *completion in [_dictionary completionsForTerm:term]) {
        [_dictionary hasDefinitionForTerm:completion];
      }
      for (NSString *guess in [_dictionary guessesForTerm:term]) {
        [_dictionary hasDefinitionForTerm:guess];
      }

      count++;

      if (count % 1000 == 0) {
        NSLog(@"%d / %d terms processed", count, [terms count]);
        [_dictionary saveCache];
      }
    }
  }

  [_dictionary saveCache];
  NSLog(@"file at %@", [_dictionary validTermsCacheFilePath]);
}

@end

