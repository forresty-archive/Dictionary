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

- (void)testHasDefinitionForTerm {
  NSAssert([_dictionary hasDefinitionForTerm:@"hello"], @"sanity test");
}

- (void)testGuessesForTerm {
  NSArray *guesses = [_dictionary guessesForTerm:@"helo"];
  NSAssert([guesses count] > 0, @"should have guesses");
  NSAssert([guesses containsObject:@"hello"], @"sanity test");
}

- (void)testCompletionsForTerm {
  NSArray *completions = [_dictionary completionsForTerm:@"histo"];
  NSAssert([completions count] > 0, @"should have completions");
  NSAssert([completions containsObject:@"history"], @"should include the term history");
}

- (void)testCompletionsForTermShouldIncludeTheTermItself {
  NSArray *completions = [_dictionary completionsForTerm:@"history"];
  NSLog(@"completions: %@", completions);
  NSAssert([completions containsObject:@"history"], @"should include the term history");
}

@end

