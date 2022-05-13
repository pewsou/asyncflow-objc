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
@implementation ASFKQueue
-(id)init{
    self=[super init];
    if(self){
        q=[NSMutableArray array];
        lock=[NSLock new];
        
    }
    return self;
}
-(BOOL) isEmpty{
    [lock lock];
    BOOL e=[q count]>0?NO:YES;
    [lock unlock];
    return e;
}
-(NSUInteger )count{
    [lock lock];
    NSUInteger c=[q count];
    [lock unlock];
    return c;
}
-(BOOL)push:(id)item{
    if(item){
        [lock lock];
        [q addObject:item];
        [lock unlock];
        return YES;
    }
    return NO;
    
}
-(id)pull{
    [lock lock];
    id item=[q firstObject];
    if (item) {
        [q removeObjectAtIndex:0];
    }
    [lock unlock];;
    return item;
}

-(void)reset{
    [lock lock];
    [q removeAllObjects];
    [lock unlock];;
}

@end
