//
//  MainViewController.m
//  Dictionary
//
//  Created by Feng Ye on 11/18/11.
//  Copyright (c) 2011 @forresty. All rights reserved.
//

#import "MainViewController.h"
#import "Dictionary.h"
#import "LookupHistory.h"

@implementation MainViewController {
@private
  __strong UISearchBar *__searchBar;
  __strong UITableView *__lookupHistoryTableView;
  __strong UISearchDisplayController *__searchDisplayController;

  __strong NSArray *__completions;

  __strong NSOperationQueue *__completionLookupOperationQueue;

  BOOL __lookingUpCompletions;

  Dictionary *__dictionary;
  LookupHistory *__lookupHistory;
}


#pragma mark - View lifecycle


- (void)viewDidLoad {
  [super viewDidLoad];

  __dictionary = [Dictionary sharedInstance];
  __lookupHistory = [LookupHistory sharedInstance];

  __lookingUpCompletions = NO;

  __completions = @[];

  __completionLookupOperationQueue = [[NSOperationQueue alloc] init];

  [self buildViews];
}


- (void)buildViews {
  [self buildSearchBar];
  [self buildLookupHistoryTableView];
  [self buildSearchDisplayController];
  [self setupViewConstraints];
}


- (void)buildSearchBar {
  __searchBar = [[UISearchBar alloc] init];
  __searchBar.delegate = self;
  __searchBar.autocapitalizationType = UITextAutocapitalizationTypeNone;
  [__searchBar sizeToFit];
}


- (void)buildLookupHistoryTableView {
  __lookupHistoryTableView = [[UITableView alloc] init];
  [__lookupHistoryTableView setTranslatesAutoresizingMaskIntoConstraints:NO];
  __lookupHistoryTableView.dataSource = self;
  __lookupHistoryTableView.delegate = self;
  __lookupHistoryTableView.tableHeaderView = __searchBar;

  [self.view addSubview:__lookupHistoryTableView];
}


- (void)buildSearchDisplayController {
  __searchDisplayController = [[UISearchDisplayController alloc] initWithSearchBar:__searchBar contentsController:self];
  __searchDisplayController.delegate = self;
  __searchDisplayController.searchResultsDataSource = self;
  __searchDisplayController.searchResultsDelegate = self;
}


- (void)setupViewConstraints {
  NSDictionary *views = NSDictionaryOfVariableBindings(__lookupHistoryTableView, self.view);
  [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|[__lookupHistoryTableView]|" options:0 metrics:nil views:views]];
  [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[__lookupHistoryTableView]|" options:0 metrics:nil views:views]];
}


# pragma mark - history


- (NSArray *)indexPathsForLookupHistory {
  NSMutableArray * indexPaths = [[NSMutableArray alloc] initWithCapacity:[__lookupHistory count]];

  for (int i = 0; i < [__lookupHistory count]; i++) {
    [indexPaths addObject:[NSIndexPath indexPathForRow:i inSection:0]];
  }

  return indexPaths;
}


- (void)clearHistory {
  [[NSOperationQueue mainQueue] addOperationWithBlock:^{
    [__lookupHistoryTableView beginUpdates];
    [__lookupHistoryTableView deleteRowsAtIndexPaths:[self indexPathsForLookupHistory] withRowAnimation:UITableViewRowAnimationTop];
    [__lookupHistory clear];
    [__lookupHistoryTableView endUpdates];
  }];

  [[NSOperationQueue mainQueue] addOperationWithBlock:^{
    [__lookupHistoryTableView reloadData];
  }];
}


# pragma mark - view manipulation


- (void)makeCellDefault:(UITableViewCell *)cell {
  cell.selectionStyle = UITableViewCellSelectionStyleBlue;
  cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
  cell.textLabel.textAlignment = NSTextAlignmentLeft;
  cell.textLabel.font = [UIFont fontWithName:@"Baskerville" size:24];
}


- (void)makeCellDisabled:(UITableViewCell *)cell {
  [self makeCellDefault:cell];
  cell.textLabel.textColor = [UIColor grayColor];
  cell.selectionStyle = UITableViewCellSelectionStyleNone;
  cell.accessoryType = UITableViewCellAccessoryNone;
}


- (void)makeCellNormal:(UITableViewCell *)cell {
  [self makeCellDefault:cell];
  cell.textLabel.textColor = [UIColor blackColor];
}


- (void)makeCellHighlighted:(UITableViewCell *)cell {
  [self makeCellDefault:cell];
  cell.textLabel.textColor = [UIColor blueColor];
}


# pragma mark - UI presentation


- (void)showDefinitionForTerm:(NSString *)term {
  [[NSOperationQueue mainQueue] addOperationWithBlock:^{
    [__lookupHistory addLookupHistoryWithTerm:term];
    [__lookupHistoryTableView reloadData];
  }];

  UIReferenceLibraryViewController *referenceLibraryViewController = [[UIReferenceLibraryViewController alloc] initWithTerm:term];

  [self presentViewController:referenceLibraryViewController animated:YES completion:NULL];
}


# pragma mark - definition / completion lookup && guesses


//-(NSArray *)mergeAndSortArray:(NSArray *)array withAnotherArray:(NSArray *)anotherArray {
//  NSArray *result = [array arrayByAddingObjectsFromArray:anotherArray];
//
//  return [result sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
//}


//-(void)makeGuessForSearchString:(NSString *)searchString {
//  __guessing = YES;
//  [__guessOperationQueue cancelAllOperations];
//
//  NSBlockOperation *guessOperation = [[NSBlockOperation alloc] init];
//  __weak NSBlockOperation *weakGuessOperation = guessOperation;
//
//  [guessOperation addExecutionBlock:^{
//    NSMutableArray *guessResults = [@[] mutableCopy];
//
//    for (NSString *guess in [__dictionary guessesForTerm:searchString]) {
//      if ([weakGuessOperation isCancelled]) {
//        break;
//      }
//
//      if (![guess isEqualToString:searchString] && [__dictionary hasDefinitionForTerm:guess]) {
//        [guessResults addObject:guess];
//      }
//    }
//
//    if (![weakGuessOperation isCancelled]) {
//      [[NSOperationQueue mainQueue] addOperationWithBlock:^{
//        __guessing = NO;
//        __guesses = guessResults;
//        [self.searchDisplayController.searchResultsTableView reloadData];
//      }];
//    }
//  }];
//
//  [__guessOperationQueue addOperation:guessOperation];
//}
//

-(void)startLookupCompletionsForSearchString:(NSString *)searchString {
  __lookingUpCompletions = YES;
  [__completionLookupOperationQueue cancelAllOperations];

  NSBlockOperation *operation = [[NSBlockOperation alloc] init];
  __weak NSBlockOperation *weakOperation = operation;

  [operation addExecutionBlock:^{
    NSMutableArray *results = [@[] mutableCopy];

    if ([__dictionary hasDefinitionForTerm:searchString]) {
      [results addObject:searchString];
    }

    if ([weakOperation isCancelled]) {
      return;
    }

    for (NSString *completion in [__dictionary completionsForTerm:searchString]) {
      if ([weakOperation isCancelled]) {
        break;
      }

      if ([__dictionary hasDefinitionForTerm:completion]) {
        [results addObject:completion];
      }
    }

    if (![weakOperation isCancelled]) {
      [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        __lookingUpCompletions = NO;
        __completions = results;
        [self.searchDisplayController.searchResultsTableView reloadData];
      }];
    }
  }];

  [__completionLookupOperationQueue addOperation:operation];
}


# pragma mark - UITableViewDataSource


-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

  static NSString *kCellID = @"wordCellID";

  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellID];
  if (cell == nil) {
    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kCellID];
  }

  if (tableView == self.searchDisplayController.searchResultsTableView) {
    if (__lookingUpCompletions) {
      [self makeCellDisabled:cell];
      cell.textLabel.text = @"Looking up...";
    } else if ([__completions count] > 0){
      [self makeCellNormal:cell];
      cell.textLabel.text = [__completions[indexPath.row] description];
    } else {
      [self makeCellDisabled:cell];
      cell.textLabel.text = @"No result";
    }
  } else if (tableView == __lookupHistoryTableView) {
    if ([__lookupHistory count] == 0) {
      [self makeCellDisabled:cell];
      cell.textLabel.text = @"No history";
    } else {
      [self makeCellNormal:cell];
      if (indexPath.row == [__lookupHistory count]) {
        cell.textLabel.textAlignment = NSTextAlignmentCenter;
        cell.accessoryType = UITableViewCellAccessoryNone;
        cell.textLabel.font = [UIFont fontWithName:@"Helvetica" size:18];
        cell.textLabel.text = @"Clear History";
      } else {
        cell.textLabel.text = [__lookupHistory[indexPath.row] description];
      }
    }
  }

  return cell;
}


-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  if (tableView == self.searchDisplayController.searchResultsTableView) {
    return 1;
  } else if (tableView == __lookupHistoryTableView) {
    return 1;
  }

  return 0;
}


-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
  if (tableView == self.searchDisplayController.searchResultsTableView) {
    return nil;
  } else if (tableView == __lookupHistoryTableView) {
    return @"History";
  }

  return nil;
}


-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  if (tableView == self.searchDisplayController.searchResultsTableView) {
    if (__lookingUpCompletions) {
      return 1;
    } else if ([__completions count] > 0) {
      return [__completions count];
    } else {
      return 1;
    }
  } else if (tableView == __lookupHistoryTableView) {
    return [__lookupHistory count] + 1;
  }

  return 0;
}


# pragma mark - UITableViewDelegate


-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  [tableView deselectRowAtIndexPath:indexPath animated:YES];

  if (tableView == self.searchDisplayController.searchResultsTableView) {
    if ([__searchBar.text length] > 0 && [__completions count] > 0 && indexPath.section == 0) {
      [self showDefinitionForTerm:__completions[indexPath.row]];

    } else if (__lookingUpCompletions) {
      // guessing, do nothing
      return;

    }
  } else if (tableView == __lookupHistoryTableView) {
    if ([__lookupHistory count] == 0) {
      // empty history, do nothing
    } else {
      if (indexPath.row == [__lookupHistory count]) {
        [self clearHistory];
      } else {
        [self showDefinitionForTerm:[__lookupHistory[indexPath.row] description]];
      }
    }
  }
}


# pragma mark - UISearchDisplayDelegate


-(BOOL)searchDisplayController:(UISearchDisplayController *)searchDisplayController shouldReloadTableForSearchString:(NSString *)searchString {
//  NSAssert([NSOperationQueue mainQueue] == [NSOperationQueue currentQueue], @"should be called in main queue!");

  if ([searchString length] < 1) {
    return NO;
  }

  [[NSOperationQueue mainQueue] addOperationWithBlock:^{
    __lookingUpCompletions = YES;
    __completions = @[];
    [self.searchDisplayController.searchResultsTableView reloadData];
  }];

  [self startLookupCompletionsForSearchString:searchString];

  return NO;
}


# pragma mark - UISearchBarDelegate


-(void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
  if ([searchBar.text length] > 0 && [__completions count] > 0 && [searchBar.text isEqualToString:__completions[0]]) {
    [self showDefinitionForTerm:searchBar.text];
  }
}


@end
