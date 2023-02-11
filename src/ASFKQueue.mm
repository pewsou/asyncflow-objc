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
//  Copyright © 2019-2023 Boris Vigman. All rights reserved.
//

#import "ASFKBase.h"
#import "ASFKQueue+Internal.h"

@implementation ASFKQueue{
    std::atomic<BOOL> condPredR;
    std::atomic<BOOL> condPredW;
    NSCondition* condR;
    NSCondition* condW;
}
-(id)init{
    self=[super init];
    if(self){
        [self _initQ:NO];
    }
    return self;
}

-(id)initWithName:(NSString*)name{
    self=[super initWithName:name];
    if(self){
        [self _initQ:NO];
    }
    return self;
}
-(id) initWithName:(NSString*) name blocking:(BOOL)blk{
    self=[super initWithName:name];
    if(self){
        [self _initQ:blk];
    }
    return self;
}
-(void) _initQ:(BOOL)blk{
    q=[NSMutableArray array];
    lock=[NSLock new];
    minQSize=0;
    maxQSize=ULONG_MAX;
    condPredR=NO;
    condPredW=NO;
    paused=NO;
    condR=nil;
    condW=nil;
    blocking=blk;
    if(blocking){
        condR=[NSCondition new];
        condW=[NSCondition new];
    }
}
-(BOOL) isBlocking{
    return blocking;
}
#pragma mark - Configuration
-(BOOL) setMaxQSize:(NSUInteger)size{
    BOOL r=YES;
    if(size < minQSize.load()){
        r=NO;
        WASFKLog(@"new upper limit is not greater than lower limit");
    }
    maxQSize=size;
    return r;
}
-(BOOL) setMinQSize:(NSUInteger)size{
    BOOL r=YES;
    if(size > maxQSize.load()){
        r=NO;
        WASFKLog(@"new lower limit is not less than upper limit");
    }
    minQSize=size;
    return r;
}
#pragma mark - Insertion
-(void) queueFromQueue:(ASFKQueue*)otherq{
    DASFKLog(ASFK_STR_VER_UNAVAIL_OP);
}
-(void) queueFromArray:(NSArray*)array{
    DASFKLog(ASFK_STR_VER_UNAVAIL_OP);
}
-(void) queueFromOrderedSet:(NSOrderedSet*)set{
    DASFKLog(ASFK_STR_VER_UNAVAIL_OP);
}
-(void) queueFromUnorderedSet:(NSSet*)set{
    DASFKLog(ASFK_STR_VER_UNAVAIL_OP);
}
-(void) queueFromDictionary:(NSDictionary*)dict{
    DASFKLog(ASFK_STR_VER_UNAVAIL_OP);
}
#pragma mark - prepending
-(BOOL) prependFromQueue:(ASFKQueue*)otherq{
    DASFKLog(ASFK_STR_VER_UNAVAIL_OP);
    return NO;
}
-(BOOL) prependFromArray:(NSArray*)array{
    DASFKLog(ASFK_STR_VER_UNAVAIL_OP);
    return NO;
}
-(BOOL) prependFromOrderedSet:(NSOrderedSet*)set{
    DASFKLog(ASFK_STR_VER_UNAVAIL_OP);
    return NO;
}
-(BOOL) prependFromUnorderedSet:(NSSet*)set{
    DASFKLog(ASFK_STR_VER_UNAVAIL_OP);
    return NO;
}
-(BOOL) prependFromDictionary:(NSDictionary*)dict{
    if(blocking==NO && dict){
        [lock lock];
        [dict enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
            [q insertObject:obj atIndex:0];
        }];
        [lock unlock];
        return YES;
    }
    return NO;
}
#pragma mark - Non-blocking interface
-(BOOL) castQueue:(ASFKQueue* _Nullable)otherq exParams:(ASFKExecutionParams* _Nullable)ex{
    DASFKLog(ASFK_STR_VER_UNAVAIL_OP);
    return NO;
}
-(BOOL)castObject:(id _Nullable)item exParams:(ASFKExecutionParams* _Nullable)ex{
    if(item){
        [lock lock];
        BOOL insert=[q count]+1<=maxQSize?YES:NO;
        if(insert){
            [q addObject:item];
        }
        [lock unlock];
        if(insert==YES){
            if(blocking){
                [condR lock];
                condPredR=YES;
                [condR signal];
                [condR unlock];
            }
        }
        
        return insert;
    }
    return NO;
}
-(BOOL) castArray:(NSArray* _Nullable)array exParams:(ASFKExecutionParams* _Nullable)ex{
    if(array){
        [lock lock];
        BOOL insert=[q count]+[array count]<=maxQSize?YES:NO;
        if(insert){
            [q addObjectsFromArray:array];
        }
        [lock unlock];
        if(insert==YES){
            if(blocking){
                [condR lock];
                condPredR=YES;
                [condR signal];
                [condR unlock];
            }
        }
        return insert;
    }
    return NO;
}
-(BOOL) castDictionary:(NSDictionary* _Nullable)dict exParams:(ASFKExecutionParams* _Nullable)ex{
    if(dict){
        [lock lock];
        BOOL insert=[q count]+[dict count]<=maxQSize?YES:NO;
        if(insert){
            [q addObjectsFromArray:[dict allValues]];
        }
        [lock unlock];
        if(insert==YES){
            if(blocking){
                [condR lock];
                condPredR=YES;
                [condR signal];
                [condR unlock];
            }
        }
        return insert;
    }
    return NO;
}
-(BOOL) castOrderedSet:(NSOrderedSet* _Nullable)set exParams:(ASFKExecutionParams* _Nullable)ex{
    if(set){
        [lock lock];
        BOOL insert=[q count]+[set count]<=maxQSize?YES:NO;
        if(insert){
            [q addObjectsFromArray:[set array]];
        }
        [lock unlock];
        if(insert==YES){
            if(blocking){
                [condR lock];
                condPredR=YES;
                [condR signal];
                [condR unlock];
            }
        }
        return insert;
    }
    return NO;
}
-(BOOL) castUnorderedSet:(NSSet* _Nullable)set exParams:(ASFKExecutionParams* _Nullable)ex{
    if(set){
        [lock lock];
        BOOL insert=[q count]+[set count]<=maxQSize?YES:NO;
        if(insert){
            [q addObjectsFromArray:[set allObjects]];
        }
        [lock unlock];
        if(insert==YES){
            if(blocking){
                [condR lock];
                condPredR=YES;
                [condR signal];
                [condR unlock];
            }
        }
        return insert;
    }
    return NO;
}

#pragma mark - Blocking interface
-(BOOL) callQueue:(ASFKQueue*)otherq exParams:(ASFKExecutionParams*) expar{
    DASFKLog(ASFK_STR_VER_UNAVAIL_OP);
    return NO;
}
-(BOOL) callArray:(NSArray* _Nullable)array exParams:(ASFKExecutionParams* _Nullable) expar{
    DASFKLog(ASFK_STR_VER_UNAVAIL_OP);
    
    return NO;
}
-(BOOL) callDictionary:(NSDictionary* _Nullable)dict exParams:(ASFKExecutionParams* _Nullable) expar{
    DASFKLog(ASFK_STR_VER_UNAVAIL_OP);
    return NO;
}
-(BOOL) callOrderedSet:(NSOrderedSet* _Nullable)set exParams:(ASFKExecutionParams* _Nullable) expar{
    DASFKLog(ASFK_STR_VER_UNAVAIL_OP);
    
    return NO;
}
-(BOOL) callUnorderedSet:(NSSet* _Nullable)set exParams:(ASFKExecutionParams* _Nullable) expar{
    DASFKLog(ASFK_STR_VER_UNAVAIL_OP);
    
    return NO;
}
-(BOOL) callObject:(id _Nullable)item exParams:(ASFKExecutionParams* _Nullable) expar{
    DASFKLog(ASFK_STR_VER_UNAVAIL_OP);
    
    return NO;
}
#pragma mark - querying
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

-(id)pull{
    if(paused){
        return nil;
    }
    if(blocking){
        [lock lock];
        NSUInteger c=[q count];
        [lock unlock];
        if(c<=minQSize){
            [condR lock];
            condPredR=NO;
            while(condPredR==NO){
                [condR wait];
                [lock lock];
                condPredR=[q count]>0?YES:NO;
                [lock unlock];
            }
            [condR unlock];
        }
        else{
            condPredR=YES;
        }
    }
    [lock lock];
    id item=[q count]>minQSize?[q firstObject]:nil;
    if(item)
    {
        [q removeObjectAtIndex:0];
        if(blocking){
            [condW lock];
            condPredW=YES;
            [condW signal];
            [condW unlock];
        }
    }
    [lock unlock];
    
    return item;
}

-(void)reset{
    [lock lock];
    [q removeAllObjects];
    if(blocking){
        [condR lock];
        condPredR=YES;
        [condR broadcast];
        [condR unlock];
        
        [condW lock];
        condPredW=YES;
        [condW broadcast];
        [condW unlock];
    }
    [lock unlock];;
}
-(void) purge{
    [lock lock];
    [q removeAllObjects];
    [lock unlock];;
}
-(void) pause{
    paused=YES;
}
-(void) resume{
    paused=NO;
}
@end
