//
//  LookupResult.h
//  Dictionary
//
//  Created by Forrest Ye on 6/25/13.
//
//

#import <Foundation/Foundation.h>

@interface LookupResult : NSObject

-(NSString *)currentTerm;

-(BOOL)guessing;

-(NSArray *)guesses;

-(BOOL)lookingUpCompletions;

-(NSArray *)completions;

-(BOOL)lookingUpDefinition;

-(BOOL)hasDefinition;

-(BOOL)hasGuesses;

-(BOOL)hasCompletions;

-(BOOL)partiallyDone;

-(BOOL)allDone;

@end
