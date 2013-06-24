//
//  MainViewController.m
//  Dictionary
//
//  Created by Feng Ye on 11/18/11.
//  Copyright (c) 2011 @forresty. All rights reserved.
//

#import "MainViewController.h"
#import "UIKit/UITextChecker.h"
#import "UIKit/UIReferenceLibraryViewController.h"
#import "Dictionary.h"


@implementation MainViewController {
@private
  __strong UISearchBar *__searchBar;
  __strong UITableView *__lookupHistoryTableView;
  __strong UITextChecker *__textChecker;
  __strong UISearchDisplayController *__searchDisplayController;

  __strong NSArray *candidatesArray;

  __strong NSOperationQueue *guessOperationQueue;
  __strong NSOperationQueue *definitionLookupOperationQueue;
  __strong NSOperationQueue *completionLookupOperationQueue;

  __strong NSString *exactMatchedString;
  BOOL guessing;
  BOOL lookingUpCompletions;

  Dictionary *dictionary;
}


#pragma mark - View lifecycle


- (void)viewDidLoad {
  [super viewDidLoad];

  dictionary = [Dictionary sharedDictionary];

  exactMatchedString = nil;
  guessing = NO;
  lookingUpCompletions = NO;

  candidatesArray = [[NSMutableArray alloc] init];

  guessOperationQueue = [[NSOperationQueue alloc] init];
  definitionLookupOperationQueue = [[NSOperationQueue alloc] init];
  completionLookupOperationQueue = [[NSOperationQueue alloc] init];

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


# pragma mark - history

-(void)clearHistory {
  [[NSOperationQueue mainQueue] addOperationWithBlock:^{
    NSMutableArray *indexPaths = [[NSMutableArray alloc] initWithCapacity:[[dictionary lookupHistory] count]];

    for (int i = 0; i < [[dictionary lookupHistory] count]; i++) {
      [indexPaths addObject:[NSIndexPath indexPathForRow:i inSection:0]];
    }

    [__lookupHistoryTableView beginUpdates];
    [__lookupHistoryTableView deleteRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationTop];
    [dictionary clearLookupHistory];
    [__lookupHistoryTableView endUpdates];
  }];

  [[NSOperationQueue mainQueue] addOperationWithBlock:^{
    [__lookupHistoryTableView reloadData];
  }];
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


# pragma mark - UI presentation


-(void)showDefinitionForTerm:(NSString *)term {
  [[NSOperationQueue mainQueue] addOperationWithBlock:^{
    [dictionary addToLookupHistory:term];
    [__lookupHistoryTableView reloadData];
  }];

  UIReferenceLibraryViewController *referenceLibraryViewController = [[UIReferenceLibraryViewController alloc] initWithTerm:term];

  [self presentViewController:referenceLibraryViewController animated:YES completion:NULL];
}


# pragma mark - definition / completion lookup && guesses


-(NSArray *)guessesForString:(NSString *)searchString {
  return [__textChecker guessesForWordRange:NSMakeRange(0, [searchString length]) inString:searchString language:@"en_US"];
}


-(NSArray *)completionsForString:(NSString *)searchString {
  return [__textChecker completionsForPartialWordRange:NSMakeRange(0, [searchString length]) inString:searchString language:@"en_US"];
}


-(NSArray *)mergeAndSortArray:(NSArray *)array withAnotherArray:(NSArray *)anotherArray {
  NSArray *result = [array arrayByAddingObjectsFromArray:anotherArray];

  return [result sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
}


-(void)makeGuessForSearchString:(NSString *)searchString {
  guessing = YES;
  [guessOperationQueue cancelAllOperations];

  NSBlockOperation *guessOperation = [[NSBlockOperation alloc] init];
  __weak NSBlockOperation *weakGuessOperation = guessOperation;

  [guessOperation addExecutionBlock:^{
    NSMutableArray *guessResults = [@[] mutableCopy];

    for (NSString *guess in [self guessesForString:searchString]) {
      if ([weakGuessOperation isCancelled]) {
        break;
      }

      if (![guess isEqualToString:searchString] && [dictionary hasDefinitionForTerm:guess]) {
        [guessResults addObject:guess];
      }
    }

    if (![weakGuessOperation isCancelled]) {
      [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        guessing = NO;
        candidatesArray = [self mergeAndSortArray:candidatesArray withAnotherArray:guessResults];
        [self.searchDisplayController.searchResultsTableView reloadData];
      }];
    }
  }];

  [guessOperationQueue addOperation:guessOperation];
}


-(void)startLookupCompletionsForSearchString:(NSString *)searchString {
  lookingUpCompletions = YES;
  [completionLookupOperationQueue cancelAllOperations];

  NSBlockOperation *operation = [[NSBlockOperation alloc] init];
  __weak NSBlockOperation *weakOperation = operation;

  [operation addExecutionBlock:^{
    NSMutableArray *results = [@[] mutableCopy];

    for (NSString *completion in [self completionsForString:searchString]) {
      if ([weakOperation isCancelled]) {
        break;
      }

      if (![completion isEqualToString:searchString] && [dictionary hasDefinitionForTerm:completion]) {
        [results addObject:completion];
      }
    }

    if (![weakOperation isCancelled]) {
      [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        lookingUpCompletions = NO;
        candidatesArray = [self mergeAndSortArray:candidatesArray withAnotherArray:results];
        [self.searchDisplayController.searchResultsTableView reloadData];
      }];
    }
  }];

  [completionLookupOperationQueue addOperation:operation];
}


-(void)startLookupDefinitionForSearchString:(NSString *)searchString {
  exactMatchedString = nil;
  [definitionLookupOperationQueue cancelAllOperations];

  NSBlockOperation *lookupOperation = [[NSBlockOperation alloc] init];
  __weak NSBlockOperation *weakLookupOperation = lookupOperation;

  [lookupOperation addExecutionBlock:^{
    NSAssert(exactMatchedString == nil, @"exactMatch should be NO here");

    if ([dictionary hasDefinitionForTerm:searchString]) {
      if (![weakLookupOperation isCancelled]) {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
          exactMatchedString = [searchString copy];
          [self.searchDisplayController.searchResultsTableView reloadData];
        }];
      }
    } else {
      if (![weakLookupOperation isCancelled]) {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
          exactMatchedString = nil;
          [self.searchDisplayController.searchResultsTableView reloadData];
        }];
      }
    }
  }];

  [definitionLookupOperationQueue addOperation:lookupOperation];
}


# pragma mark - UITableViewDataSource


-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

  static NSString *kCellID = @"wordCellID";

  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellID];
  if (cell == nil) {
    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kCellID];
  }

  if (tableView == self.searchDisplayController.searchResultsTableView) {
    if ([exactMatchedString isEqualToString:__searchBar.text] && indexPath.section == 0) {
      [self makeCellHighlighted:cell];
      cell.textLabel.text = __searchBar.text;
    } else if (guessing && lookingUpCompletions) {
      [self makeCellDisabled:cell];
      cell.textLabel.text = @"Guessing...";
    } else {
      [self makeCellNormal:cell];
      cell.textLabel.text = [[candidatesArray objectAtIndex:indexPath.row] description];
    }
  } else if (tableView == __lookupHistoryTableView) {
    if ([[dictionary lookupHistory] count] == 0) {
      [self makeCellDisabled:cell];
      cell.textLabel.text = @"No history";
    } else {
      [self makeCellNormal:cell];
      if (indexPath.row == [[dictionary lookupHistory] count]) {
        cell.textLabel.textAlignment = NSTextAlignmentCenter;
        cell.accessoryType = UITableViewCellAccessoryNone;
        cell.textLabel.font = [UIFont fontWithName:@"Helvetica" size:18];
        cell.textLabel.text = @"Clear History";
      } else {
        cell.textLabel.text = [[[dictionary lookupHistory] objectAtIndex:indexPath.row] description];
      }
    }
  }

  return cell;
}


-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  if (tableView == self.searchDisplayController.searchResultsTableView) {

    if ([exactMatchedString isEqualToString:__searchBar.text] && [candidatesArray count] > 0) {
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

    if ([exactMatchedString isEqualToString:__searchBar.text] && section == 0) {
      return @"Match";
    } else if (guessing && lookingUpCompletions) {
      return @"Guessing...";
    } else if ([candidatesArray count] == 0) {
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
    if ([exactMatchedString isEqualToString:__searchBar.text] && section == 0) {
      return 1;
    }

    if (guessing && lookingUpCompletions) {
      if ([exactMatchedString isEqualToString:__searchBar.text]) {
        return 2;
      }
      return 1;
    }

    return [candidatesArray count];
  } else if (tableView == __lookupHistoryTableView) {
    return [[dictionary lookupHistory] count] + 1;
  }

  return 0;
}


# pragma mark - UITableViewDelegate


-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  [tableView deselectRowAtIndexPath:indexPath animated:YES];

  if (tableView == self.searchDisplayController.searchResultsTableView) {
    if ([exactMatchedString isEqualToString:__searchBar.text] && indexPath.section == 0) {
      [self showDefinitionForTerm:__searchBar.text];

    } else if (guessing && lookingUpCompletions) {
      // guessing, do nothing
      return;

    } else {
      [self showDefinitionForTerm:[[candidatesArray objectAtIndex:indexPath.row] description]];
    }
  } else if (tableView == __lookupHistoryTableView) {
    if ([[dictionary lookupHistory] count] == 0) {
      // empty history, do nothing
    } else {
      if (indexPath.row == [[dictionary lookupHistory] count]) {
        [self clearHistory];
      } else {
        [self showDefinitionForTerm:[[[dictionary lookupHistory] objectAtIndex:indexPath.row] description]];
      }
    }
  }
}


# pragma mark - UISearchDisplayDelegate


-(BOOL)searchDisplayController:(UISearchDisplayController *)searchDisplayController shouldReloadTableForSearchString:(NSString *)searchString {
  if ([searchString length] < 1) {
    return NO;
  }

  [[NSOperationQueue mainQueue] addOperationWithBlock:^{
    guessing = YES;
    lookingUpCompletions = YES;
    exactMatchedString = nil;
    candidatesArray = @[];
    [self.searchDisplayController.searchResultsTableView reloadData];
  }];

  [self makeGuessForSearchString:searchString];
  [self startLookupDefinitionForSearchString:searchString];
  [self startLookupCompletionsForSearchString:searchString];

  return NO;
}


# pragma mark - UISearchBarDelegate


-(void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
  if ([exactMatchedString isEqualToString:searchBar.text]) {
    return;
  }

  [self showDefinitionForTerm:searchBar.text];
}


@end
