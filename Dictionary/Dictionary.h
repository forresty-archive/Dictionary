//
//  Dictionary.h
//  Dictionary
//
//  Created by Forrest Ye on 6/24/13.
//
//

#import <Foundation/Foundation.h>

@interface Dictionary : NSObject

+(instancetype)sharedDictionary;

-(BOOL)hasDefinitionForTerm:(NSString *)term;

-(NSArray *)guessesForTerm:(NSString *)term;

-(NSArray *)completionsForTerm:(NSString *)term;

-(NSArray *)lookupHistory;

-(void)clearLookupHistory;

-(void)addToLookupHistory:(NSString *)term;

@end
