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
#import "ASFKLinearFlow+Internal.h"
#import "ASFKQueue+Internal.h"
@implementation ASFKThreadpoolQueue{
    long occupant;
}
-(id)init{
    self=[super init];
    if(self){
        occupant=-1;
    }
    return self;
}
-(NSDictionary*) _castUnorderedSet:(ASFKParamSet*) params{
    NSSet* input=params.input;
    [self _queueFromUnorderedSet:input];
    return @{};
}
-(NSDictionary*) _castOrderedSet:(ASFKParamSet*) params{
    NSOrderedSet* input=params.input;
    [self _queueFromOrderedSet:input];
    return @{};
}
-(NSDictionary*) _castArray:(ASFKParamSet*) params{
    NSArray* input=params.input;
    [self _queueFromArray:input];
    return @{};
}

-(void) _queueFromOrderedSet:(NSOrderedSet *)set{
    for (id item in set) {
        [q addObject:item];
    }
}
-(void) _queueFromUnorderedSet:(NSSet *)set{
    for (id item in set) {
        [q addObject:item];
    }
}
-(void) _queueFromArray:(NSArray *)array{
    for (id item in array) {
        [q addObject:item];
    }
}
-(void) queueFromArray:(NSArray*)array{
    [lock lock];
    [self _queueFromArray:array];
    [lock unlock];
}
-(void) queueFromOrderedSet:(NSOrderedSet*)set{
    [lock lock];
    [self _queueFromOrderedSet:set];
    [lock unlock];
}
-(void) queueFromUnorderedSet:(NSSet*)set{
    [lock lock];
    [self _queueFromUnorderedSet:set];
    [lock unlock];
}
-(void) queueFromItem:(id)item{
    [lock lock];
    [q addObject:item];
    [lock unlock];
}
-(void) queueFromQueue:(ASFKThreadpoolQueue*)queue{
    [lock lock];
    [queue begin];
    NSArray* data=[queue getData];
    [self _queueFromArray:data];
    [queue commit];
    [lock unlock];
}
-(id)pullAndOccupyWithId:(long)itsid empty:(BOOL &)empty{
    [lock lock];
    if(occupant>=0 && occupant!=itsid){
        empty=YES;
        if([q count]>0){
            empty=NO;
        }
        [lock unlock];;
        return nil;
    }
    
    id item=[q firstObject];
    if (item) {
        [q removeObjectAtIndex:0];
        if([q count]>0){
            occupant=itsid;
            empty=NO;
        }
        else{
            occupant=-1;
            empty=YES;
        }
    }else{
        occupant=-1;
        empty=YES;
    }
    [lock unlock];;
    return item;
}
-(void)unoccupyWithId:(long)itsid{
    [lock lock];
    if(occupant==itsid){
        occupant=-1;
    }
    [lock unlock];
}
-(void)unoccupy{
    [lock lock];
    occupant=-1;
    [lock unlock];
}
-(BOOL)isEmpty{
    [lock lock];
    BOOL e=[q count]>0 && occupant>=0 ?NO:YES;
    [lock unlock];
    return e;
}
-(void)reset{
    [lock lock];
    [q removeAllObjects];
    occupant=-1;
    [lock unlock];;
}
@end
