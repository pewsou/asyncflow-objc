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
//  Created by Boris Vigman on 15/02/2019.
//  Copyright © 2019-2022 Boris Vigman. All rights reserved.
//

#import "ASFKBase.h"

@interface ASFKFilter : ASFKLinearFlow
-(BOOL) testCriteriaMatch:(id)object;
-(BOOL) filterCandidatesInArray:(NSArray*)objects saveToArray:(NSMutableArray*)array;
-(BOOL) filterCandidatesInArray:(NSArray*)objects saveToIndexSet:(NSMutableIndexSet*)iset;
-(BOOL) filterCandidatesInArray:(NSArray*)objects saveToRange:(NSRange&)range;
-(BOOL) filterCandidatesInSet:(NSSet*)objects saveToArray:(NSMutableArray*)array;
-(BOOL) filterCandidatesInOrderedSet:(NSOrderedSet*)objects saveToIndexSet:(NSMutableIndexSet*)iset;
-(BOOL) filterCandidatesInOrderedSet:(NSOrderedSet*)objects saveToRange:(NSRange&)range;
-(BOOL) filterCandidatesInDictionary:(NSDictionary*)objects saveToKeys:(NSMutableArray*)keys values:(NSMutableArray*)values;
@end
