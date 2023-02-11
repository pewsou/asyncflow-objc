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
//  Copyright © 2019-2023 Boris Vigman. All rights reserved.
//

#import "ASFKBase.h"
#import "ASFKSessionalFlow+Internal.h"
@implementation ASFKFilter
-(NSDictionary*) _postUnorderedSet:(ASFKParamSet*) params blocking:(BOOL) blk{
    
    return @{};
}
-(NSDictionary*) _postOrderedSet:(ASFKParamSet*) params blocking:(BOOL) blk{

    return @{};
}
-(NSDictionary*) _postArray:(ASFKParamSet*)params blocking:(BOOL) blk{

    return @{};
}
-(NSDictionary*) _castDictionary:(ASFKParamSet *)params{
  
    return @{};
}
-(NSDictionary*) _callObject:(ASFKParamSet *)params{
    
    return @{};
}
-(BOOL) testCriteriaMatch:(id)object{
    return YES;
}
-(BOOL) filterCandidatesInArray:(NSArray*)objects passing:(BOOL)writeOut saveToArray:(NSMutableArray*)array{
    return YES;
}
-(BOOL) filterCandidatesInArray:(NSArray*)objects passing:(BOOL)writeOut saveToIndexSet:(NSMutableIndexSet*)iset{
    return YES;
}
-(BOOL) filterCandidatesInArray:(NSArray*)objects passing:(BOOL)writeOut saveToRange:(NSRange&)range{
    return YES;
}
-(BOOL) filterCandidatesInSet:(NSSet*)objects passing:(BOOL)writeOut saveToArray:(NSMutableArray*)array{
    return YES;
}
-(BOOL) filterCandidatesInOrderedSet:(NSOrderedSet*)objects passing:(BOOL)writeOut saveToIndexSet:(NSMutableIndexSet*)iset{
    return YES;
}
-(BOOL) filterCandidatesInOrderedSet:(NSOrderedSet*)objects passing:(BOOL)writeOut saveToRange:(NSRange&)range{
    return YES;
}
-(BOOL) filterCandidatesInDictionary:(NSDictionary*)objects passing:(BOOL)writeOut saveToKeys:(NSMutableArray*)keys values:(NSMutableArray*)values{
    return YES;
}
@end
