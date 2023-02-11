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
//
//  Copyright © 2019-2023 Boris Vigman. All rights reserved.
//
#import "ASFKBase.h"

@implementation ASFKFilteringQueue{
    std::atomic<eASFKQDroppingPolicy> dpolicy;
    ASFKFilter* itsFilter;
}
-(id)init{
    self=[super init];
    if(self){
        [self _initFQ];
    }
    return self;
}

-(id)initWithName:(NSString*)name{
    self=[super initWithName:name];
    if(self){
        [self _initFQ];
    }
    return self;
}
-(id)initWithName:(NSString*)name blocking:(BOOL)blk{
    self=[super initWithName:name];
    if(self){
        [self _initFQ];
    }
    return self;
}
-(void) _initFQ{
    dpolicy=E_ASFK_Q_DP_HEAD;
    itsFilter=nil;
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
#pragma mark - configuration

-(void) setDroppingPolicy:(eASFKQDroppingPolicy)policy{
    dpolicy=policy;
}
-(void) setDroppingAlgorithm:(ASFKFilter*)dropAlg{
    [lkNonLocal lock];
    itsFilter = dropAlg;
    [lkNonLocal unlock];
}
#pragma mark - filtering
-(BOOL) removeObjWithProperty:(id)obj andBlock:(BOOL (^)(id item,id sample, BOOL* stop)) blk{
    BOOL r=NO;
    
    if(obj && blk){
        NSMutableIndexSet* mis=[NSMutableIndexSet new];
        NSUInteger c=0;
        [lkNonLocal lock];
        BOOL stop = NO;
        for (id o in q) {
            r=YES;
            if(blk(o,obj,&stop)){
                [mis addIndex:c];
            }
            ++c;
            
            if( stop ){
                break;
            }
        }
        [q removeObjectsAtIndexes:mis];

        [lkNonLocal unlock];
    }
    return r;
}
#pragma mark - non-blocking interface
-(BOOL) castQueue:(ASFKQueue*)otherq exParams:(ASFKExecutionParams*)ex{
    DASFKLog(ASFK_STR_UNSUPPORTED_OP);
    return NO;
}

-(BOOL) castArray:(NSArray*)array exParams:(ASFKExecutionParams*)ex{
    if(array==nil || [array count]==0){
        return NO;
    }
    BOOL res=YES;
    [lock lock];
    for (id item in array) {
        res &= [self _insertElement:item];
    }
    
    [lock unlock];
    return res;
}
-(BOOL) castDictionary:(NSDictionary*)dict exParams:(ASFKExecutionParams*)ex{
    if(dict==nil || [dict count]==0){
        return NO;
    }
    BOOL res=YES;
    NSArray* a=[dict allValues];
    [lock lock];
    for (id item in a) {
        res &= [self _insertElement:item];
    }
    
    [lock unlock];
    return res;
}
-(BOOL) castOrderedSet:(NSOrderedSet*)set exParams:(ASFKExecutionParams*)ex{
    if(set==nil || [set count]==0){
        return NO;
    }
    BOOL res=YES;
    [lock lock];
    for (id item in set) {
        res &= [self _insertElement:item];
    }
    [lock unlock];
    return res;
}
-(BOOL) castUnorderedSet:(NSSet*)set exParams:(ASFKExecutionParams*)ex{
    if(set==nil || [set count]==0){
        return NO;
    }
    BOOL res=YES;
    [lock lock];
    for (id item in set) {
        res &= [self _insertElement:item];
    }
    [lock unlock];
    return res;
}

-(BOOL)castObject:(id)item exParams:(ASFKExecutionParams*)ex{
    BOOL res=NO;
    if(item){
        [lock lock];
        res = [self _insertElement:item];
        [lock unlock];
    }
    return res;
}
#pragma mark - Blocking interface (disabled)
-(BOOL) callQueue:(ASFKQueue*)otherq{
    DASFKLog(ASFK_STR_UNSUPPORTED_OP);
    return NO;
}
-(BOOL) callArray:(NSArray*)array exParams:(ASFKExecutionParams*) expar{
    DASFKLog(ASFK_STR_UNSUPPORTED_OP);
    return NO;
}
-(BOOL) callDictionary:(NSDictionary*)dict exParams:(ASFKExecutionParams*) expar{
    DASFKLog(ASFK_STR_UNSUPPORTED_OP);
    return NO;
}
-(BOOL) callOrderedSet:(NSOrderedSet*)set exParams:(ASFKExecutionParams*) expar{
    DASFKLog(ASFK_STR_UNSUPPORTED_OP);
    return NO;
}
-(BOOL) callUnorderedSet:(NSSet*)set exParams:(ASFKExecutionParams*) expar{
    DASFKLog(ASFK_STR_UNSUPPORTED_OP);
    return NO;
}
-(BOOL) callObject:(id)item exParams:(ASFKExecutionParams*) expar{
    DASFKLog(ASFK_STR_UNSUPPORTED_OP);
    return NO;
}
#pragma mark - Reading
-(id)pullWithCount:(NSInteger) count{
    if(paused){
        return nil;
    }
    [lock lock];
    NSUInteger qc = [q count];
    id item=[q firstObject];
    if (item && qc + count >= minQSize) {
        [q removeObjectAtIndex:0];
    }
    else{
        item=nil;
    }
    [lock unlock];;
    return item;
}
-(id)pull{
    if(paused){
        return nil;
    }
    [lock lock];
    NSUInteger qc = [q count];
    id item=[q firstObject];
    if (item && qc >= minQSize) {
        [q removeObjectAtIndex:0];
    }
    else{
        item=nil;
    }
    [lock unlock];;

    return item;
}

-(void) filterWith:(ASFKFilter*)filter{
    ASFKFilter* ft=filter;
    [lock lock];
    if(!ft)
    {
        ft=itsFilter;
    }
    if(ft){
        NSMutableIndexSet* iset=[NSMutableIndexSet new];
        BOOL res=[ft filterCandidatesInArray:q passing:YES saveToIndexSet:iset];
        if(res){
            [q removeObjectsAtIndexes:iset];
        }
    }
    [lock unlock];
}

#pragma mark - Private methods
-(BOOL) _insertElement:(id) item{
    BOOL res=NO;
        NSUInteger qc = [q count];
        if(qc+1 <= maxQSize)
        {
            [q addObject:item];
            res=YES;
        }
        else
        {
            NSRange r;
            if(dpolicy == E_ASFK_Q_DP_HEAD && qc > 0){
                r.location=0;
                r.length=qc-maxQSize+1;
                [q removeObjectsInRange:r];
                [q addObject:item];
                res = YES;
            }
            else if(dpolicy == E_ASFK_Q_DP_TAIL){
                r.location=maxQSize-1;
                r.length=qc-maxQSize+1;
                [q removeObjectsInRange:r];
                [q addObject:item];
                res = YES;
            }
            else if(dpolicy == E_ASFK_Q_DP_REJECT){
                res=NO;
            }
            else if(dpolicy == E_ASFK_Q_DP_ALGO){
                ASFKFilter* ft=nil;
                ft=itsFilter;
                if(nil==ft){
                    res=NO;
                }
                else{
                    NSMutableIndexSet* iset=[NSMutableIndexSet new];
                    res=[ft filterCandidatesInArray:q passing:YES saveToIndexSet:iset];
                    if(res){
                        [q removeObjectsAtIndexes:iset];
                        [q addObject:item];
                        res=YES;
                    }
                    else{
                        res=NO;
                    }
                }
                
            }
        }
    return res;
}
-(void) reset{
    [super reset];
    dpolicy=E_ASFK_Q_DP_HEAD;
    itsFilter=nil;
    minQSize=0;
    maxQSize=ULONG_MAX;
}
-(void) purge{
    [super purge];
}

@end
