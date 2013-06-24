//
//  LookupResult.m
//  Dictionary
//
//  Created by Forrest Ye on 6/25/13.
//
//

#import "LookupResult.h"

@implementation LookupResult

-(NSString *)currentTerm {
  return @"";
}

-(BOOL)guessing {
  return NO;
}

-(BOOL)lookingUpCompletions {
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

-(NSArray *)completions {
  return @[];
}

@end
