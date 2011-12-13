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
    [searchBar sizeToFit];
    
    tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, 320, 460) style:UITableViewStyleGrouped];
    
    
    tableView.dataSource = self;
    tableView.delegate = self;
//    
    
  }
  
  return self;
}

- (void)didReceiveMemoryWarning
{
  // Releases the view if it doesn't have a superview.
  [super didReceiveMemoryWarning];
    
  // Release any cached data, images, etc that aren't in use.
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

  
  [self.view addSubview:self.tableView];

  NSLog(@"viewDidLoad completed");
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
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
    } else if ([guessesArray count] == 0) {
      return @"No result";
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
	}
	
//	cell.textLabel.text = [self.guessesArray objectAtIndex:indexPath.row];
  if (exactMatch && indexPath.section == 0) {
    cell.textLabel.textColor = [UIColor blackColor];
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

-(void)tableView:(UITableView *)tView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  UIReferenceLibraryViewController *dicController;
  
  [tView deselectRowAtIndexPath:indexPath animated:YES];
  
  if (exactMatch && indexPath.section == 0) {
    dicController = [[UIReferenceLibraryViewController alloc] initWithTerm:searchBar.text];
  } else if (guessing) {
    // guessing, do nothing
    return;
  } else {
    dicController = [[UIReferenceLibraryViewController alloc] initWithTerm:[[guessesArray objectAtIndex:indexPath.row] description]];
  }
  
  [self presentModalViewController:dicController animated:YES];
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
    
    for (NSString *guess in guesses) {
      if ([UIReferenceLibraryViewController dictionaryHasDefinitionForTerm:guess]) {
        [guessesArray addObject:guess];
      }
    }
  }];
  
  [guessOperation setCompletionBlock:^{
    guessing = NO;
    
    [self.searchDisplayController.searchResultsTableView performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:YES];
    
//    NSLog(@"operation completed!");
  }];
  
  [guessOperationQueue addOperation:guessOperation];
  
  
  return exactMatch;
}

@end
