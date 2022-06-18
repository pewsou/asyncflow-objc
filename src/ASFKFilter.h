/*
 This program is free software: you can redistribute it and/or modify
 it under the terms of the GNU Affero General Public License as
 published by the Free Software Foundation, either version 3 of the
 License, or (at your option) any later version.
 
 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU Affero General Public License for more details.
 
 You should have received a copy of the GNU Affero General Public License
 along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */
//  Copyright © 2019-2022 Boris Vigman. All rights reserved.
//

#import "ASFKBase.h"

@interface ASFKFilter : ASFKLinearFlow
/*!
 @brief Tests given object with some custom criteria.
 @param object object to test.
 @return YES if test passes; NO otherwise.
 */
-(BOOL) testCriteriaMatch:(id)object;
/*!
 @brief Tests array of objects.
 @param objects objects to test.
 @param writeOut indication of whether to save passing objects or non-passing. YES for passing, NO otherwise.
 @param array array of filtered objects.
 @return YES if at least one test passes; NO otherwise.
 */
-(BOOL) filterCandidatesInArray:(NSArray*)objects passing:(BOOL)writeOut saveToArray:(NSMutableArray*)array;
/*!
 @brief Tests array of objects.
 @param objects objects to test.
 @param writeOut indication of whether to save passing objects or non-passing. YES for passing, NO otherwise.
 @param iset index set of filtered objects.
 @return YES if at least one test passes; NO otherwise.
 */
-(BOOL) filterCandidatesInArray:(NSArray*)objects passing:(BOOL)writeOut saveToIndexSet:(NSMutableIndexSet*)iset;
/*!
 @brief Tests array of objects.
 @param objects objects to test.
 @param writeOut indication of whether to save passing objects or non-passing. YES for passing, NO otherwise.
 @param range range of indexes of filtered objects.
 @return YES if at least one test passes; NO otherwise.
 */
-(BOOL) filterCandidatesInArray:(NSArray*)objects passing:(BOOL)writeOut saveToRange:(NSRange&)range;
/*!
 @brief Tests unordered set of objects.
 @param objects objects to test.
 @param writeOut indication of whether to save passing objects or non-passing. YES for passing, NO otherwise.
 @param array array of filtered objects.
 @return YES if at least one test passes; NO otherwise.
 */
-(BOOL) filterCandidatesInSet:(NSSet*)objects passing:(BOOL)writeOut saveToArray:(NSMutableArray*)array;
/*!
 @brief Tests unordered set of objects.
 @param objects ordered set of objects to test.
 @param writeOut indication of whether to save passing objects or non-passing. YES for passing, NO otherwise.
 @param iset index set of filtered objects.
 @return YES if at least one test passes; NO otherwise.
 */
-(BOOL) filterCandidatesInOrderedSet:(NSOrderedSet*)objects passing:(BOOL)writeOut saveToIndexSet:(NSMutableIndexSet*)iset;
/*!
 @brief Tests unordered set of objects.
 @param objects ordered set of objects to test.
 @param writeOut indication of whether to save passing objects or non-passing. YES for passing, NO otherwise.
 @param range range of indexes of filtered objects.
 @return YES if at least one test passes; NO otherwise.
 */
-(BOOL) filterCandidatesInOrderedSet:(NSOrderedSet*)objects passing:(BOOL)writeOut saveToRange:(NSRange&)range;
/*!
 @brief Tests dictionary of objects.
 @param objects ordered set of objects to test.
 @param writeOut indication of whether to save passing objects or non-passing. YES for passing, NO otherwise.
 @param keys array of keys of filtered objects. If nil, then not used.
 @param values array of values of filtered objects. If nil, then not used.
 @return YES if at least one test passes; NO otherwise.
 */
-(BOOL) filterCandidatesInDictionary:(NSDictionary*)objects passing:(BOOL)writeOut saveToKeys:(NSMutableArray*)keys values:(NSMutableArray*)values;
@end
