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


static NSString *kDictionaryLookupHistory = @"kDictionaryLookupHistory";
static int kDictionaryLookupHistoryLimit = 15;
static int kDictionaryGuessCountLimit = 10;


@implementation DICWordLookupTableViewController {
@private
  UISearchBar *__searchBar;
  UITableView *__lookupHistoryTableView;
  UITextChecker *__textChecker;
  UISearchDisplayController *__searchDisplayController;

  NSArray *guessesArray;
  NSOperationQueue *guessOperationQueue;
  NSOperationQueue *lookupOperationQueue;
  BOOL exactMatch;
  BOOL guessing;
}


#pragma mark - View lifecycle


- (void)viewDidLoad {
  [super viewDidLoad];

  exactMatch = false;
  guessing = false;

  guessesArray = [[NSMutableArray alloc] init];

  guessOperationQueue = [[NSOperationQueue alloc] init];
  lookupOperationQueue = [[NSOperationQueue alloc] init];

  __searchBar = [[UISearchBar alloc] initWithFrame:CGRectZero];
  __searchBar.delegate = self;
  __searchBar.autocapitalizationType = UITextAutocapitalizationTypeNone;
  [__searchBar sizeToFit];

  __textChecker = [[UITextChecker alloc] init];

  __searchDisplayController = [[UISearchDisplayController alloc] initWithSearchBar:__searchBar contentsController:self];
  __searchDisplayController.delegate = self;
  __searchDisplayController.searchResultsDataSource = self;
  __searchDisplayController.searchResultsDelegate = self;

  __lookupHistoryTableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
  __lookupHistoryTableView.dataSource = self;
  __lookupHistoryTableView.delegate = self;
  __lookupHistoryTableView.tableHeaderView = __searchBar;
  __lookupHistoryTableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
  __lookupHistoryTableView.frame = self.view.bounds;

  [self.view addSubview:__lookupHistoryTableView];
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
  if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
    return YES;
  }
  else {
    return interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown;
  }
}


-(void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
  __lookupHistoryTableView.frame = self.view.bounds;
}


# pragma mark - view manipulation


-(void)makeCellDefault:(UITableViewCell *)cell {
  cell.selectionStyle = UITableViewCellSelectionStyleBlue;
  cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
  cell.textLabel.textAlignment = NSTextAlignmentLeft;
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


# pragma mark - internal


-(NSArray *)lookupHistory {
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

  return [defaults objectForKey:kDictionaryLookupHistory];
}


-(void)setLookupHistory:(NSArray *)lookupHistory {
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  [defaults setObject:lookupHistory forKey:kDictionaryLookupHistory];
  [defaults synchronize];
}


-(void)addToLookupHistory:(NSString *)term {
  NSMutableArray *lookupHistory = [@[term] mutableCopy];

  for (NSString *termInHistory in [self lookupHistory]) {
    if (![term isEqual:termInHistory] && [lookupHistory count] < kDictionaryLookupHistoryLimit) {
      [lookupHistory addObject:termInHistory];
    }
  }

  [self setLookupHistory:lookupHistory];
}

-(void)clearHistory {
  [[NSOperationQueue mainQueue] addOperationWithBlock:^{
    NSMutableArray *indexPaths = [[NSMutableArray alloc] initWithCapacity:[[self lookupHistory] count]];

    for (int i = 0; i < [[self lookupHistory] count]; i++) {
      [indexPaths addObject:[NSIndexPath indexPathForRow:i inSection:0]];
    }

    [__lookupHistoryTableView beginUpdates];
    [__lookupHistoryTableView deleteRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationTop];
    [self setLookupHistory:@[]];
    [__lookupHistoryTableView endUpdates];
  }];

  [[NSOperationQueue mainQueue] addOperationWithBlock:^{
    [__lookupHistoryTableView reloadData];
  }];
}


-(void)showDefinitionForTerm:(NSString *)term {
  [[NSOperationQueue mainQueue] addOperationWithBlock:^{
    [self addToLookupHistory:term];
    [__lookupHistoryTableView reloadData];
  }];

  UIReferenceLibraryViewController *referenceLibraryViewController = [[UIReferenceLibraryViewController alloc] initWithTerm:term];

  [self presentViewController:referenceLibraryViewController animated:YES completion:^{
    // do nothing
  }];
}


-(NSArray *)guessesForString:(NSString *)searchString {
  return [__textChecker guessesForWordRange:NSMakeRange(0, [searchString length]) inString:searchString language:@"en_US"];
}


-(NSArray *)completionsForString:(NSString *)searchString {
  return [__textChecker completionsForPartialWordRange:NSMakeRange(0, [searchString length]) inString:searchString language:@"en_US"];
}


-(void)makeGuessForSearchString:(NSString *)searchString {
  [guessOperationQueue cancelAllOperations];

  NSBlockOperation *guessOperation = [[NSBlockOperation alloc] init];
  __weak NSBlockOperation *weakGuessOperation = guessOperation;

  [guessOperation addExecutionBlock:^{
    NSMutableArray *guessResults = [@[] mutableCopy];

    for (NSString *guess in [self guessesForString:searchString]) {
      if ([weakGuessOperation isCancelled]) {
        break;
      }

      if ([guessResults count] < kDictionaryGuessCountLimit &&
          ![guess isEqualToString:searchString] &&
          [UIReferenceLibraryViewController dictionaryHasDefinitionForTerm:guess]) {
        [guessResults addObject:guess];
      }
    }

    if ([guessResults count] < kDictionaryGuessCountLimit) {
      for (NSString *completion in [self completionsForString:searchString]) {
        if ([weakGuessOperation isCancelled]) {
          break;
        }

        if ([guessResults count] < kDictionaryGuessCountLimit &&
            ![completion isEqualToString:searchString] &&
            ![guessResults containsObject:completion] &&
            [UIReferenceLibraryViewController dictionaryHasDefinitionForTerm:completion]) {
          [guessResults addObject:completion];
        }
      }
    }

    if (![weakGuessOperation isCancelled]) {
      [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        guessing = NO;
        guessesArray = [guessResults copy];
        [self.searchDisplayController.searchResultsTableView reloadData];
      }];
    }
  }];

  [guessOperationQueue addOperation:guessOperation];
}


-(void)startLookupForSearchString:(NSString *)searchString {
  [lookupOperationQueue cancelAllOperations];

  NSBlockOperation *lookupOperation = [[NSBlockOperation alloc] init];
  __weak NSBlockOperation *weakLookupOperation = lookupOperation;

  [lookupOperation addExecutionBlock:^{
    if ([UIReferenceLibraryViewController dictionaryHasDefinitionForTerm:searchString]) {
      if (![weakLookupOperation isCancelled]) {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
          exactMatch = YES;
          guessing = NO;
          [guessOperationQueue cancelAllOperations];
          [self.searchDisplayController.searchResultsTableView reloadData];
        }];
      }
    } else {
      if (![weakLookupOperation isCancelled]) {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
          exactMatch = NO;
          guessing = NO;
          [guessOperationQueue cancelAllOperations];
          [self.searchDisplayController.searchResultsTableView reloadData];
        }];
      }
    }
  }];

  [lookupOperationQueue addOperation:lookupOperation];
}


# pragma mark - UITableViewDataSource


-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

  static NSString *kCellID = @"wordCellID";

  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellID];
  if (cell == nil) {
    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kCellID];
  }

  if (tableView == self.searchDisplayController.searchResultsTableView) {
    if (exactMatch && indexPath.section == 0) {
      [self makeCellHighlighted:cell];
      cell.textLabel.text = __searchBar.text;
    } else if (guessing) {
      [self makeCellDisabled:cell];
      cell.textLabel.text = @"Guessing...";
    } else {
      [self makeCellNormal:cell];
      cell.textLabel.text = [[guessesArray objectAtIndex:indexPath.row] description];
    }
  } else if (tableView == __lookupHistoryTableView) {
    if ([[self lookupHistory] count] == 0) {
      [self makeCellDisabled:cell];
      cell.textLabel.text = @"No history";
    } else {
      [self makeCellNormal:cell];
      if (indexPath.row == [[self lookupHistory] count]) {
        cell.textLabel.textAlignment = NSTextAlignmentCenter;
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


-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  if (tableView == self.searchDisplayController.searchResultsTableView) {

    if (exactMatch && ([guessesArray count] > 0 || guessing)) {
      return 2;
    }

    return 1;
  } else if (tableView == __lookupHistoryTableView) {
    return 1;
  }

  return 0;
}


-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
  if (tableView == self.searchDisplayController.searchResultsTableView) {

    if (exactMatch && section == 0) {
      return @"Match";
    } else if (guessing) {
      return @"Guessing...";
    } else if ([guessesArray count] == 0) {
      return @"No results";
    }

    return @"Did you mean?";
  } else if (tableView == __lookupHistoryTableView) {
    return @"History";
  }

  return nil;
}


-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  if (tableView == self.searchDisplayController.searchResultsTableView) {
    if (exactMatch && section == 0) {
      return 1;
    }

    if (guessing) {
      return 1;
    }

    return [guessesArray count];
  } else if (tableView == __lookupHistoryTableView) {
    return [[self lookupHistory] count] + 1;
  }

  return 0;
}


# pragma mark - UITableViewDelegate


-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  [tableView deselectRowAtIndexPath:indexPath animated:YES];

  if (tableView == self.searchDisplayController.searchResultsTableView) {
    if (exactMatch && indexPath.section == 0) {
      [self showDefinitionForTerm:__searchBar.text];

    } else if (guessing) {
      // guessing, do nothing
      return;

    } else {
      [self showDefinitionForTerm:[[guessesArray objectAtIndex:indexPath.row] description]];
    }
  } else if (tableView == __lookupHistoryTableView) {
    if ([[self lookupHistory] count] == 0) {
      // empty history, do nothing
    } else {
      if (indexPath.row == [[self lookupHistory] count]) {
        [self clearHistory];
      } else {
        [self showDefinitionForTerm:[[[self lookupHistory] objectAtIndex:indexPath.row] description]];
      }
    }
  }
}


# pragma mark - UISearchDisplayDelegate


-(BOOL)searchDisplayController:(UISearchDisplayController *)searchDisplayController shouldReloadTableForSearchString:(NSString *)searchString {
  [[NSOperationQueue mainQueue] addOperationWithBlock:^{
    guessing = YES;
    exactMatch = NO;
    guessesArray = @[];
    [self.searchDisplayController.searchResultsTableView reloadData];
  }];

  [self makeGuessForSearchString:searchString];
  [self startLookupForSearchString:searchString];

  return NO;
}


# pragma mark - UISearchBarDelegate


-(void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
  if (!exactMatch) {
    return;
  }

  [self showDefinitionForTerm:searchBar.text];
}


@end
