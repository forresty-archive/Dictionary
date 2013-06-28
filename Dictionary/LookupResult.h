//
//  LookupResult.h
//  Dictionary
//
//  Created by Forrest Ye on 6/25/13.
//
//

#import <Foundation/Foundation.h>

@interface LookupResult : NSObject

@property NSString *term;

@property NSArray *completions;

@property BOOL lookingUpCompletions;

-(BOOL)guessing;

-(NSArray *)guesses;

-(BOOL)lookingUpCompletions;

-(BOOL)lookingUpDefinition;

-(BOOL)hasDefinition;

-(BOOL)hasGuesses;

-(BOOL)hasCompletions;

-(BOOL)partiallyDone;

-(BOOL)allDone;

- (void)startLookupCompletionsForSearchString:(NSString *)searchString;

@end
