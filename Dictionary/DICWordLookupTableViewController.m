//
//  DICWordLookupTableViewController.m
//  Dictionary
//
//  Created by Feng Ye on 11/18/11.
//  Copyright (c) 2011 @forresty. All rights reserved.
//

#import "DICWordLookupTableViewController.h"
#import "UIKit/UITextChecker.h"
#import "UIKit/UIReferenceLibraryViewController.h"
#import "MKiCloudSync.h"

static NSString *kDictionaryLookupHistory = @"kDictionaryLookupHistory";
static int kDictionaryLookupHistoryLimit = 15;
static int kDictionaryGuessCountLimit = 10;

@implementation DICWordLookupTableViewController

@synthesize searchBar, tableView, guessesArray, textChecker, mySearchDisplayController, exactMatch, guessing, guessOperationQueue;

- (id)init {
  self = [super init];
  
  if (self) {
    exactMatch = false;
    guessing = false;
    
    guessesArray = [[NSMutableArray alloc] init];
    guessOperationQueue = [[NSOperationQueue alloc] init];
    
    searchBar = [[UISearchBar alloc] initWithFrame:CGRectZero];
    searchBar.delegate = self;
    searchBar.autocapitalizationType = UITextAutocapitalizationTypeNone;
    [searchBar sizeToFit];
    
    tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    tableView.dataSource = self;
    tableView.delegate = self;
  }
  
  return self;
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
  [super viewDidLoad];
  
  mySearchDisplayController = [[UISearchDisplayController alloc] initWithSearchBar:searchBar contentsController:self];
  mySearchDisplayController.delegate = self;
  mySearchDisplayController.searchResultsDataSource = self;
  mySearchDisplayController.searchResultsDelegate = self;
  
  tableView.tableHeaderView = searchBar;
  tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
  tableView.frame = self.view.bounds;
  
  [self.view addSubview:self.tableView];
  
  [[NSNotificationCenter defaultCenter] addObserverForName:kMKiCloudSyncNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
    [tableView reloadData];
  }];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
  if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
    return YES;
  }
  else {
    return interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown;
  }
}

-(void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
  tableView.frame = self.view.bounds;
}

-(NSArray *)lookupHistory {
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  
  return [defaults objectForKey:kDictionaryLookupHistory];
}

-(void)setLookupHistory:(NSArray *)lookupHistory {
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  [defaults setObject:lookupHistory forKey:kDictionaryLookupHistory];
  [defaults synchronize];
}

-(NSInteger)tableView:(UITableView *)tView numberOfRowsInSection:(NSInteger)section {
  if (tView == self.searchDisplayController.searchResultsTableView) {
    if (exactMatch && section == 0) {
      return 1;
    }
    
    if (guessing) {
      return 1;
    }
    
    return [self.guessesArray count];
  } else if (tView == tableView) {
    return [[self lookupHistory] count] + 1;
  }
  
  return 0;
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tView {
  if (tView == self.searchDisplayController.searchResultsTableView) {
    
    if (exactMatch && ([guessesArray count] > 0 || guessing)) {
      return 2;
    }
    
    return 1;
  } else if (tView == tableView) {
    return 1;
  }
  
  return 0;
}

-(NSString *)tableView:(UITableView *)tView titleForHeaderInSection:(NSInteger)section {
  if (tView == self.searchDisplayController.searchResultsTableView) {
    
    if (exactMatch && section == 0) {
      return @"Match";
    } else if (guessing) {
      return @"Guessing...";
    } else if ([guessesArray count] == 0) {
      return @"No results";
    }
    
    return @"Did you mean?";
  } else if (tView == tableView) {
    return @"History";
  }
  
  return nil;
}

-(void)makeCellDefault:(UITableViewCell *)cell {
  cell.selectionStyle = UITableViewCellSelectionStyleBlue;
  cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
  cell.textLabel.textAlignment = UITextAlignmentLeft;
  cell.textLabel.font = [UIFont fontWithName:@"Baskerville" size:24];
}

-(void)makeCellDisabled:(UITableViewCell *)cell {
  [self makeCellDefault:cell];
  cell.textLabel.textColor = [UIColor grayColor];
  cell.selectionStyle = UITableViewCellSelectionStyleNone;
  cell.accessoryType = UITableViewCellAccessoryNone;
}

-(void)makeCellNormal:(UITableViewCell *)cell {
  [self makeCellDefault:cell];
  cell.textLabel.textColor = [UIColor blackColor];
}

-(void)makeCellHighlighted:(UITableViewCell *)cell {
  [self makeCellDefault:cell];
  cell.textLabel.textColor = [UIColor blueColor];
}

-(UITableViewCell *)tableView:(UITableView *)tView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  
  static NSString *kCellID = @"wordCellID";
  
  UITableViewCell *cell = [tView dequeueReusableCellWithIdentifier:kCellID];
  if (cell == nil) {
    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kCellID];
  }
  
  if (tView == self.searchDisplayController.searchResultsTableView) {
    if (exactMatch && indexPath.section == 0) {
      [self makeCellHighlighted:cell];
      cell.textLabel.text = searchBar.text;
    } else if (guessing) {
      [self makeCellDisabled:cell];
      cell.textLabel.text = @"Guessing...";
    } else {
      [self makeCellNormal:cell];
      cell.textLabel.text = [[guessesArray objectAtIndex:indexPath.row] description];
    }
  } else if (tView == tableView) {
    if ([[self lookupHistory] count] == 0) {
      [self makeCellDisabled:cell];
      cell.textLabel.text = @"No history";
    } else {
      [self makeCellNormal:cell];
      if (indexPath.row == [[self lookupHistory] count]) {
        cell.textLabel.textAlignment = UITextAlignmentCenter;
        cell.accessoryType = UITableViewCellAccessoryNone;
        cell.textLabel.font = [UIFont fontWithName:@"Helvetica" size:18];
        cell.textLabel.text = @"Clear History";
      } else {
        cell.textLabel.text = [[[self lookupHistory] objectAtIndex:indexPath.row] description];
      }
    }
  }
  
  return cell;
}

-(void)showDefinitionForTerm:(NSString *)term {
  NSMutableArray *lookupHistory = [[NSMutableArray alloc] init];
  [lookupHistory addObject:term];
  
  for (NSString *termInHistory in [self lookupHistory]) {
    if (![term isEqual:termInHistory] && [lookupHistory count] < kDictionaryLookupHistoryLimit) {
      [lookupHistory addObject:termInHistory];
    }
  }
  
  [self setLookupHistory:lookupHistory];
  
  [tableView performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:NO];
  
  //  NSLog(@"current history: %@", [lookupHistory description]);
  
  UIReferenceLibraryViewController *dicController = [[UIReferenceLibraryViewController alloc] initWithTerm:term];
  
  [self presentModalViewController:dicController animated:YES];
}

-(void)tableView:(UITableView *)tView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  [tView deselectRowAtIndexPath:indexPath animated:YES];
  
  if (tView == self.searchDisplayController.searchResultsTableView) {
    if (exactMatch && indexPath.section == 0) {
      [self showDefinitionForTerm:searchBar.text];
      
    } else if (guessing) {
      // guessing, do nothing
      return;
      
    } else {
      [self showDefinitionForTerm:[[guessesArray objectAtIndex:indexPath.row] description]];
    }
  } else if (tView == tableView) {
    if ([[self lookupHistory] count] == 0) {
      // do nothing
    } else {
      if (indexPath.row == [[self lookupHistory] count]) {
        // clear history
        NSMutableArray *indexPaths = [[NSMutableArray alloc] initWithCapacity:[[self lookupHistory] count]];
        for (int i = 0; i < [[self lookupHistory] count]; i++) {
          [indexPaths addObject:[NSIndexPath indexPathForRow:i inSection:0]];
        }
        //        NSLog(@"indexpaths %@", [indexPaths description]);
        [tableView beginUpdates];
        [tableView deleteRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationTop];
        [self setLookupHistory:[[NSArray alloc] init]];
        [tableView endUpdates];
        [tableView performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:NO];
      } else {
        [self showDefinitionForTerm:[[[self lookupHistory] objectAtIndex:indexPath.row] description]];
      }
    }
  }
}

-(BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString {
  [self.guessesArray removeAllObjects];
  
  //  NSLog(@"searching for %@", searchString);
  if ([UIReferenceLibraryViewController dictionaryHasDefinitionForTerm:searchString]) {
    exactMatch = YES;
  } else {
    exactMatch = NO;
  }
  
  guessing = YES;
  
  [guessOperationQueue cancelAllOperations];
  
  NSBlockOperation *guessOperation = [NSBlockOperation blockOperationWithBlock:^{
    textChecker = [[UITextChecker alloc] init];
    
    //    NSLog(@"operation working!!");
    
    [self.guessesArray removeAllObjects];
    
    if (!exactMatch) {
      NSArray *guesses = [self.textChecker guessesForWordRange:NSMakeRange(0, [searchString length]) inString:searchString language:@"en_US"];
      for (NSString *guess in guesses) {
        if ([guessesArray count] < kDictionaryGuessCountLimit &&
            ![guess isEqualToString:searchString] &&
            [UIReferenceLibraryViewController dictionaryHasDefinitionForTerm:guess]) {
          [guessesArray addObject:guess];
        }
      }
    }
    
    if ([guessesArray count] < kDictionaryGuessCountLimit) {
      NSArray *completions = [textChecker completionsForPartialWordRange:NSMakeRange(0, [searchString length]) inString:searchString language:@"en_US"];
      for (NSString *completion in completions) {
        if ([guessesArray count] < kDictionaryGuessCountLimit &&
            ![completion isEqualToString:searchString] &&
            ![guessesArray containsObject:completion] &&
            [UIReferenceLibraryViewController dictionaryHasDefinitionForTerm:completion]) {
          [guessesArray addObject:completion];
        }
      }
    }
  }];
  
  [guessOperation setCompletionBlock:^{
    guessing = NO;
    
    [self.searchDisplayController.searchResultsTableView performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:NO];
    
    //    NSLog(@"operation completed!");
  }];
  
  [guessOperationQueue addOperation:guessOperation];
  
  return exactMatch;
}

-(void)searchBarSearchButtonClicked:(UISearchBar *)sBar {
  NSString *term = nil;
  
  if (exactMatch) {    
    term = sBar.text;
  } 
  //  else if ([guessesArray count] > 0) {
  //    term = [guessesArray objectAtIndex:0];
  //  }
  
  if (term == nil) {
    return;
  }
  
  [self showDefinitionForTerm:term];
}

@end
