//
//  DICWordLookupTableViewController.m
//  Dictionary
//
//  Created by Feng Ye on 11/18/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "DICWordLookupTableViewController.h"

#import "UIKit/UITextChecker.h"
#import "UIKit/UIReferenceLibraryViewController.h"

static NSString *kDictionaryLookupHistory = @"kDictionaryLookupHistory";
static int kDictionaryLookupHistoryLimit = 10;

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
    [searchBar sizeToFit];
    
    tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
    
    tableView.dataSource = self;
    tableView.delegate = self;
  }
  
  return self;
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
  [super viewDidLoad];
  
  searchBar.delegate = self;
  
  mySearchDisplayController = [[UISearchDisplayController alloc] initWithSearchBar:searchBar contentsController:self];
  mySearchDisplayController.delegate = self;
  mySearchDisplayController.searchResultsDataSource = self;
  mySearchDisplayController.searchResultsDelegate = self;
  
  tableView.tableHeaderView = searchBar;

  tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
  tableView.frame = self.view.bounds;
  
  [self.view addSubview:self.tableView];
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

-(NSInteger)tableView:(UITableView *)tView numberOfRowsInSection:(NSInteger)section {
  if (tView == self.searchDisplayController.searchResultsTableView) {
    if (exactMatch && section == 0) {
      return 1;
    }
    
    if (guessing) {
      return 1;
    }
    
    return [self.guessesArray count];
  }
  
  return 0;
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tView {
  if (tView == self.searchDisplayController.searchResultsTableView) {
    
    if (exactMatch && ([guessesArray count] > 0 || guessing)) {
      return 2;
    }
    
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
  }
  
  return nil;
}

-(UITableViewCell *)tableView:(UITableView *)tView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  if (tView != self.searchDisplayController.searchResultsTableView) {
    return nil;
  }
  
  static NSString *kCellID = @"wordCellID";
	
	UITableViewCell *cell = [tView dequeueReusableCellWithIdentifier:kCellID];
	if (cell == nil)
	{
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kCellID];
    cell.textLabel.font = [UIFont fontWithName:@"Baskerville" size:24];
	}
	
//	cell.textLabel.text = [self.guessesArray objectAtIndex:indexPath.row];
  if (exactMatch && indexPath.section == 0) {
    cell.textLabel.textColor = [UIColor blueColor];
    cell.selectionStyle = UITableViewCellSelectionStyleBlue;
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell.textLabel.text = searchBar.text;
  } else if (guessing) {
    cell.textLabel.textColor = [UIColor grayColor];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.accessoryType = UITableViewCellAccessoryNone;
    cell.textLabel.text = @"Guessing...";
  } else {
    cell.textLabel.textColor = [UIColor blackColor];
    cell.selectionStyle = UITableViewCellSelectionStyleBlue;
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell.textLabel.text = [[guessesArray objectAtIndex:indexPath.row] description];
  }
  
	return cell;
}

-(NSArray *)lookupHistory {
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  
  return [defaults objectForKey:kDictionaryLookupHistory];
}

-(void)showDefinitionForTerm:(NSString *)term {
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  NSMutableArray *lookupHistory = [[NSMutableArray alloc] init];
  [lookupHistory addObject:term];
  
  for (NSString *termInHistory in [self lookupHistory]) {
    if (![term isEqual:termInHistory] && [lookupHistory count] < kDictionaryLookupHistoryLimit) {
      [lookupHistory addObject:termInHistory];
    }
  }

  [defaults setObject:lookupHistory forKey:kDictionaryLookupHistory];
  [defaults synchronize];
  NSLog(@"current history: %@", [lookupHistory description]);
  
  UIReferenceLibraryViewController *dicController = [[UIReferenceLibraryViewController alloc] initWithTerm:term];
  
  [self presentModalViewController:dicController animated:YES];
}

-(void)tableView:(UITableView *)tView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  [tView deselectRowAtIndexPath:indexPath animated:YES];
  
  if (exactMatch && indexPath.section == 0) {
    [self showDefinitionForTerm:searchBar.text];
    
  } else if (guessing) {
    // guessing, do nothing
    return;
    
  } else {
    [self showDefinitionForTerm:[[guessesArray objectAtIndex:indexPath.row] description]];
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
    
    NSArray *guesses = [self.textChecker guessesForWordRange:NSMakeRange(0, [searchString length]) inString:searchString language:@"en_US"];
  
    [self.guessesArray removeAllObjects];
    
    for (NSString *guess in guesses) {
      if ([UIReferenceLibraryViewController dictionaryHasDefinitionForTerm:guess]) {
        [guessesArray addObject:guess];
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
