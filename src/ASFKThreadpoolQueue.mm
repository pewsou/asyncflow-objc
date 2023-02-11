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
//  Created by Boris Vigman on 23/02/2019.
//  Copyright © 2019-2023 Boris Vigman. All rights reserved.
//

#import "ASFKBase.h"
#import "ASFKSessionalFlow+Internal.h"
#import "ASFKQueue+Internal.h"
#import <deque>

enum eQSpecificity{
    ASFK_E_QSPEC_NONE,
    ASFK_E_QSPEC_REG,
    ASFK_E_QSPEC_BAT
};

typedef std::deque<std::pair<eQSpecificity,NSUInteger>> tQMapper;

@implementation ASFKThreadpoolQueue{
    std::deque<NSInteger> deqIndexes;
}
-(id)init{
    self=[super init];
    if(self){
        occupant=-1;
    }
    return self;
}

-(NSDictionary*) _postUnorderedSet:(ASFKParamSet*) params blocking:(BOOL) blk{
    NSSet* input=params.input;
    [self _queueFromUnorderedSet:input];
    return @{};
}
-(NSDictionary*) _postOrderedSet:(ASFKParamSet*) params blocking:(BOOL) blk{
    NSOrderedSet* input=params.input;
    [self _queueFromOrderedSet:input];
    return @{};
}
-(NSDictionary*) _postArray:(ASFKParamSet*)params blocking:(BOOL) blk{
    NSArray* input=params.input;
    [self _queueFromArray:input];
    return @{};
}

-(void) _queueFromOrderedSet:(NSOrderedSet *)set{
    if(set){
        for (id item in set) {
            [q addObject:item];
        }
    }
}
-(void) _queueFromUnorderedSet:(NSSet *)set{
    if(set){
        for (id item in set) {
            [q addObject:item];
        }
    }
}
-(void) _queueFromArray:(NSArray *)array{
    if(array){
        for (id item in array) {
            [q addObject:item];
        }
    }
}

-(void) queueFromThreadpoolQueue:(ASFKThreadpoolQueue*)queue{
    [lock lock];
    [queue begin];
    NSArray* data=[queue getData];
    [self _queueFromArray:data];
    [queue commit];
    [lock unlock];
}
#pragma mark - Prepending (disabled)
-(BOOL) prependFromQueue:(ASFKQueue*)otherq{
    DASFKLog(ASFK_STR_UNSUPPORTED_OP);
    return NO;
}
-(BOOL) prependFromArray:(NSArray*)array{
    DASFKLog(ASFK_STR_UNSUPPORTED_OP);
    return NO;
}
-(BOOL) prependFromOrderedSet:(NSOrderedSet*)set{
    DASFKLog(ASFK_STR_UNSUPPORTED_OP);
    return NO;
}
-(BOOL) prependFromUnorderedSet:(NSSet*)set{
    DASFKLog(ASFK_STR_UNSUPPORTED_OP);
    return NO;
}
-(BOOL) prependFromDictionary:(NSDictionary*)dict{
    DASFKLog(ASFK_STR_UNSUPPORTED_OP);
    return NO;
}

-(BOOL)castObject:(id)item exParams:(ASFKExecutionParams*)ex index:(NSInteger)index{
    if(item){
        [lock lock];
        [q addObject:item];
        deqIndexes.push_back(index);
        [lock unlock];

        return YES;
    }
    return NO;
}
#pragma mark - Pulling
-(id)   pullAndOccupyWithId:(long)itsid empty:(BOOL&)empty index:(NSInteger&)itemIndex term:(ASFKPriv_EndingTerm**)term{
    itemIndex=-1;
//    if(paused){
//        [lock lock];
//        occupant=-1;
//        empty=[q count]>0?NO:YES;
//        [lock unlock];
//        return nil;
//    }
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
        itemIndex=deqIndexes.front();
        deqIndexes.pop_front();
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
#pragma mark - Maintenance
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
    deqIndexes.clear();
    [lock unlock];;
}
@end

@implementation ASFKThreadpoolQueueHyb{
    std::atomic<eQSpecificity> lastItem;
    ASFKQueue* regQ;
    ASFKBatchingQueue2* blkQ;
    std::deque<std::pair<eQSpecificity, NSUInteger>> qmapper;
}
-(id)init{
    self=[super init];
    if(self){
        [self _initTQHyb];
        blkQ=nil;
        
    }
    return self;
}
-(id)initWithBlkMode:(eASFKBlockingCallMode)blockingMode{
    self=[super init];
    if(self){
        [self _initTQHyb];
        if(blockingMode==ASFK_BC_EXCLUSIVE){
            blkQ = [[ASFKBatchingQueue2 alloc]initWithName:@"blkQ" blocking:YES];
            //[blkQ setBlockingModeOn];
        }
        else if(blockingMode==ASFK_BC_CONTINUOUS){
            blkQ = [[ASFKBatchingQueue3 alloc]initWithName:@"blkQ" blocking:YES];
            //[blkQ setBlockingModeOn];
        }
        else
        {
            blkQ=nil;
        }
    }
    return self;
}
-(void) _initTQHyb{

    lastItem=ASFK_E_QSPEC_NONE;
    regQ = [[ASFKQueue alloc]initWithName:@"regQ"];
    itsSig=self;
    q=nil;
    
}

-(NSDictionary*) _postUnorderedSet:(ASFKParamSet*) params blocking:(BOOL) blk{
    NSSet* input=params.input;
    [self _queueFromUnorderedSet:input];
    return @{};
}
-(NSDictionary*) _postOrderedSet:(ASFKParamSet*) params blocking:(BOOL) blk{
    NSOrderedSet* input=params.input;
    [self _queueFromOrderedSet:input];
    return @{};
}
-(NSDictionary*) _postArray:(ASFKParamSet*)params blocking:(BOOL) blk{
    NSArray* input=params.input;
    [self _queueFromArray:input];
    return @{};
}

-(void) _queueFromOrderedSet:(NSOrderedSet *)set{
    if(set){
        for (id item in set) {
            [q addObject:item];
        }
    }
}
-(void) _queueFromUnorderedSet:(NSSet *)set{
    if(set){
        for (id item in set) {
            [q addObject:item];
        }
    }
}
-(void) _queueFromArray:(NSArray *)array{
    if(array){
        for (id item in array) {
            [q addObject:item];
        }
    }
}
-(void) queueFromThreadpoolQueue:(ASFKThreadpoolQueue*)queue{
    [lock lock];
    [queue begin];
    NSArray* data=[queue getData];
    [self _queueFromArray:data];
    [queue commit];
    [lock unlock];
}
#pragma mark - Prepending (disabled)
-(BOOL) prependFromQueue:(ASFKQueue*)otherq{
    DASFKLog(ASFK_STR_UNSUPPORTED_OP);
    return NO;
}
-(BOOL) prependFromArray:(NSArray*)array{
    DASFKLog(ASFK_STR_UNSUPPORTED_OP);
    return NO;
}
-(BOOL) prependFromOrderedSet:(NSOrderedSet*)set{
    DASFKLog(ASFK_STR_UNSUPPORTED_OP);
    return NO;
}
-(BOOL) prependFromUnorderedSet:(NSSet*)set{
    DASFKLog(ASFK_STR_UNSUPPORTED_OP);
    return NO;
}
-(BOOL) prependFromDictionary:(NSDictionary*)dict{
    DASFKLog(ASFK_STR_UNSUPPORTED_OP);
    return NO;
}
#pragma mark - Nonblocking interface
-(BOOL) castArray:(NSArray *)array exParams:(ASFKExecutionParams*)ex{
    if(array){
        NSUInteger c=[array count];
        if(c>0){
            [lock lock];
            qmapper.push_back(std::make_pair(ASFK_E_QSPEC_REG, c));
            [regQ castArray:array exParams:nil];
            [lock unlock];
            
        }
    }
    return NO;
}
-(BOOL) castUnorderedSet:(NSSet *)set exParams:(ASFKExecutionParams *)ex{
    if(set){
        NSUInteger c=[set count];
        if(c>0){
            [lock lock];
            qmapper.push_back(std::make_pair(ASFK_E_QSPEC_REG, c));
            [regQ castUnorderedSet:set exParams:nil];
            [lock unlock];
            
        }
    }
    return NO;
}
-(BOOL) castOrderedSet:(NSOrderedSet *)set exParams:(ASFKExecutionParams *)ex{
    if(set){
        NSUInteger c=[set count];
        if(c>0){
            [lock lock];
            qmapper.push_back(std::make_pair(ASFK_E_QSPEC_REG, c));
            [regQ castOrderedSet:set exParams:nil];
            [lock unlock];
        }
    }
    return NO;
}
-(BOOL) castDictionary:(NSDictionary *)dict exParams:(ASFKExecutionParams *)ex{
    if(dict){
        NSUInteger c=[dict count];
        if(c>0){
            [lock lock];
            qmapper.push_back(std::make_pair(ASFK_E_QSPEC_REG, c));
            [regQ castDictionary:dict exParams:nil];
            [lock unlock];
        }
    }
    return NO;
}
#pragma mark - blocking interface
-(BOOL) callArray:(NSArray *)array exParams:(ASFKExecutionParams *)params{
    DASFKLog(ASFK_STR_VER_UNAVAIL_OP);
    return NO;
}
-(BOOL) callUnorderedSet:(NSSet *)unoset exParams:(ASFKExecutionParams *)params{
    DASFKLog(ASFK_STR_VER_UNAVAIL_OP);
    
    return NO;
}
-(BOOL) callOrderedSet:(NSOrderedSet *)oset exParams:(ASFKExecutionParams *)params{
    DASFKLog(ASFK_STR_VER_UNAVAIL_OP);
    return NO;
}
-(BOOL) callDictionary:(NSDictionary *)dict exParams:(ASFKExecutionParams *)params{
    DASFKLog(ASFK_STR_VER_UNAVAIL_OP);
    return NO;
}
#pragma mark - Reading
-(id)   pullAndOccupyWithId:(long)itsid empty:(BOOL&)empty index:(NSInteger&)itemIndex term:(ASFKPriv_EndingTerm**)term{

    itemIndex=-1;
    *term=nil;
    [lock lock];
    if(occupant>=0 && occupant!=itsid){
        empty=YES;
        NSUInteger bc=0;
        if(blkQ){
            bc=[blkQ count];
        }
        if([regQ count]+bc>0){
            empty=NO;
        }
        [lock unlock];;
        return nil;
    }
    id item=nil;
    
    if(qmapper.size()>0){
        std::pair<eQSpecificity, NSInteger> items=qmapper.front();
        if(items.first==ASFK_E_QSPEC_REG){
            if(lastItem!=ASFK_E_QSPEC_REG){
                lastItem=ASFK_E_QSPEC_REG;
                
            }
            item=[regQ pull];
//            lastItem=ASFK_E_QSPEC_REG;
            if(item!=nil){
                itemIndex=items.second;
                items.second--;
                if(items.second>0){
                    qmapper.front().second=items.second;
                }
                else{
                    qmapper.pop_front();
                }
            }
        }
        else
        if(blkQ){
            NSInteger lib=0;
            if(lastItem!=ASFK_E_QSPEC_BAT){
                lastItem=ASFK_E_QSPEC_BAT;
            }
            id term0=nil;
            BOOL endb=NO;
            item=[blkQ pullAndBatchStatus:lib endBatch:endb term:&term0];
            
            if(item!=nil){
                itemIndex=items.second;
                items.second--;
                if(items.second>0){
                    qmapper.front().second=items.second;
                }
                else{
                    qmapper.pop_front();
                }
                
            }
            if(endb){
                *term=itsSig;
            }
        }
    
        if (item) {
            
            //[q removeObjectAtIndex:0];
            NSUInteger blkc=0;
            if(blkQ){
                blkc=[blkQ count];
            }
            if([regQ count]+blkc > 0){
                occupant=itsid;
                empty=NO;
            }
            else{
                occupant=-1;
                empty=YES;
            }
        }
        else{
            occupant=-1;
            empty=YES;
            
        }

    }
    else{
        lastItem=ASFK_E_QSPEC_NONE;
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
    NSUInteger blkc=0;
    [lock lock];
    if(blkQ){
        blkc=[blkQ count];
    }
    BOOL e=[regQ count]+blkc>0 && occupant>=0 ?NO:YES;
    [lock unlock];
    return e;
}
-(void)reset{
    [lock lock];
    if(blkQ){
        [blkQ reset];
    }
    [regQ reset];
    occupant=-1;
    [lock unlock];;
}
-(NSUInteger )count{
    NSUInteger blkc=0;
    [lock lock];
    if(blkQ){
        blkc=[blkQ count];
    }
    NSUInteger c=[regQ count]+blkc;
    [lock unlock];
    return c;
}
-(void) _releaseBlocked{
    [lock lock];
    if(blkQ)
    {
        [blkQ releaseFirst];
    }
    [lock unlock];

}
-(void) _releaseBlockedAll{
    
}
@end
