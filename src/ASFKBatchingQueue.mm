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
#import <limits>

@implementation ASFKPriv_WrapBQ{
    
}
-(id) init{
    self=[super init];
    if(self){
        writecond=nil;
        wcPred=NO;
        many = [NSMutableArray new];
    }
    return self;
}
@end

@implementation ASFKBatchingQueue{
    NSCondition* readcond;
    ASFKPriv_WrapBQ* tempWBQ;
    std::atomic<BOOL> condPredR;
}
-(id)init{
    self=[super init];
    if(self){
        [self _initBQ];
    }
    return self;
}
-(id)initWithName:(NSString*)name{
    self=[super initWithName:name blocking:NO];
    if(self){
        [self _initBQ];
    }
    return self;
}
-(id)initWithName:(NSString*)name blocking:(BOOL)blk{
    self=[super initWithName:name blocking:blk];
    if(self){
        [self _initBQ];
    }
    return self;
}
-(void) _initBQ{
    q=[NSMutableArray array];
    lock=[NSLock new];
    paused=NO;
    netCount=0;
    condPredR=NO;
    tempWBQ=[ASFKPriv_WrapBQ new];
    batchLimitUpper=std::numeric_limits<std::uint64_t>::max();
    batchLimitLower=std::numeric_limits<std::uint64_t>::min();
    if(blocking){
        readcond=[NSCondition new];
    }
}
-(void)reset{
    [self purge];
    batchLimitUpper=std::numeric_limits<std::uint64_t>::max();
    batchLimitLower=std::numeric_limits<std::uint64_t>::min();
    paused=NO;
    netCount=0;
    condPredR=NO;
    tempWBQ=nil;
    tempWBQ=[ASFKPriv_WrapBQ new];
}
-(void) purge{
    [lock lock];
    if(blocking){
        [q enumerateObjectsWithOptions:(NSEnumerationConcurrent) usingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if(((ASFKPriv_WrapBQ*)obj)->writecond){
                [((ASFKPriv_WrapBQ*)obj)->writecond lock];
                ((ASFKPriv_WrapBQ*)obj)->wcPred=YES;
                [((ASFKPriv_WrapBQ*)obj)->writecond broadcast];
                [((ASFKPriv_WrapBQ*)obj)->writecond unlock];
            }
        }];
    }
    [q removeAllObjects];
    netCount=0;
    condPredR=NO;
    [lock unlock];;
}
-(BOOL) setMaxQSize:(NSUInteger)size{
    WASFKLog(ASFK_STR_UNSUPPORTED_OP);
    return NO;
}
-(BOOL) setMinQSize:(NSUInteger)size{
    WASFKLog(ASFK_STR_UNSUPPORTED_OP);
    return NO;
}
-(BOOL) setUpperBatchLimit:(std::uint64_t)limit{
    BOOL r=YES;
    if(limit < batchLimitLower.load()){
        r=NO;
        WASFKLog(@"new upper limit is not greater than lower limit");
    }
    batchLimitUpper=limit;
    return r;

}
-(BOOL) setLowerBatchLimit:(std::uint64_t)limit{
    BOOL r=YES;
    if(limit > batchLimitUpper.load()){
        r=NO;
        WASFKLog(@"new lower limit is not less than upper limit");
    }
    batchLimitLower=limit;
    return r;
}

-(BOOL) castArrayToBatch:(NSArray*) ar{
    BOOL tval=NO;
    DASFKLog(ASFK_STR_VER_UNAVAIL_OP);
    return tval;
}
-(BOOL) castUnorderedSetToBatch:(NSSet*) set {
    BOOL tval=NO;
    DASFKLog(ASFK_STR_VER_UNAVAIL_OP);
    return tval;
}
-(BOOL) castOrderedSetToBatch:(NSOrderedSet*) set {
    BOOL tval=NO;
    DASFKLog(ASFK_STR_VER_UNAVAIL_OP);
    return tval;
}
-(BOOL) castDictionaryToBatch:(NSDictionary*) dict {
    BOOL tval=NO;
    DASFKLog(ASFK_STR_VER_UNAVAIL_OP);
    
    return tval;
}
-(BOOL) castObjectToBatch:(id) obj{
    BOOL tval=NO;
    DASFKLog(ASFK_STR_VER_UNAVAIL_OP);
    return tval;
}
-(BOOL) commitBatch:(BOOL) force{
    BOOL res=NO;
    DASFKLog(ASFK_STR_VER_UNAVAIL_OP);
    return res;
}
-(BOOL) resetBatch{
    BOOL res=NO;
    [lock lock];
    
    if(tempWBQ && [tempWBQ->many count]>0){
        [tempWBQ->many removeAllObjects];
        res=YES;
    }
    [lock unlock];
    return res;
}
#pragma mark - content replacement
-(void) queueFromBatchingQueue:(ASFKBatchingQueue*)otherq{
    DASFKLog(ASFK_STR_VER_UNAVAIL_OP);
}
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

#pragma mark - Non-blocking interface
-(BOOL) castQueue:(ASFKQueue*)otherq{
    if(otherq){
        ASFKPriv_WrapBQ* filler=[ASFKPriv_WrapBQ new];
        [lock lock];
        [otherq begin];
        NSArray* d=[otherq getData];
        [d enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if(NO==[obj isKindOfClass:[ASFKPriv_WrapBQ class]]){
                [q addObject:obj];
            }
        }];
        [otherq commit];
        [q addObject:filler];
        netCount=[q count];
        [lock unlock];
        return YES;
    }
    return NO;
}
-(BOOL)castObject:(id)item exParams:(ASFKExecutionParams *)ex{
    if(item){
        if(batchLimitUpper.load()<1 || batchLimitLower.load()>1){
            WASFKLog(ASFK_STR_Q_ULIMIT_VIOLATION);
            return NO;
        }
        ASFKPriv_WrapBQ* wrap=[ASFKPriv_WrapBQ new];
        [wrap->many addObject:item];
        [lock lock];
        [q addObject:wrap];
        netCount.fetch_add(1);
        [lock unlock];
        if(blocking){
            wrap->writecond=[NSCondition new];
            [readcond lock];
            condPredR=YES;
            [readcond broadcast];
            [readcond unlock];
        }

        return YES;
    }
    return NO;
}
-(BOOL) castArray:(NSArray*)array exParams:(ASFKExecutionParams *)ex{
    if(array && [array count]>0 ){
        if(batchLimitUpper.load() < [array count] || batchLimitLower.load()>[array count]){
            WASFKLog(ASFK_STR_Q_ULIMIT_VIOLATION);
            return NO;
        }
        ASFKPriv_WrapBQ* wrap=[ASFKPriv_WrapBQ new];
        [wrap->many addObjectsFromArray:array];
        [lock lock];
        [q addObject:wrap];
        netCount.fetch_add([wrap->many count]);
        [lock unlock];
        if(blocking){
            wrap->writecond=[NSCondition new];
            [readcond lock];
            condPredR=YES;
            [readcond broadcast];
            [readcond unlock];
        }
        
        return YES;
    }
    return NO;
}
-(BOOL) castDictionary:(NSDictionary*)dict exParams:(ASFKExecutionParams *)ex{
    if(dict && [dict count]>0){
        if(batchLimitUpper.load()<[dict count] || batchLimitLower.load()>[dict count]){
            WASFKLog(ASFK_STR_Q_ULIMIT_VIOLATION);
            return NO;
        }
        ASFKPriv_WrapBQ* wrap=[ASFKPriv_WrapBQ new];
        [wrap->many addObjectsFromArray:[dict allValues]];
        [lock lock];
        [q addObject:wrap];
        netCount.fetch_add([dict count]);
        [lock unlock];
        if(blocking){
            wrap->writecond=[NSCondition new];
            [readcond lock];
            condPredR=YES;
            [readcond broadcast];
            [readcond unlock];
        }
        
        return YES;
    }
    return NO;
}
-(BOOL) castOrderedSet:(NSOrderedSet*)set exParams:(ASFKExecutionParams *)ex{
    if(set && [set count]>0){
        if(batchLimitUpper.load()<[set count] || batchLimitLower.load()>[set count]){
            WASFKLog(ASFK_STR_Q_ULIMIT_VIOLATION);
            return NO;
        }
        ASFKPriv_WrapBQ* wrap=[ASFKPriv_WrapBQ new];
        [wrap->many addObjectsFromArray:[set array]];
        [lock lock];
        [q addObject:wrap];
        netCount.fetch_add([set count]);
        [lock unlock];
        if(blocking){
            wrap->writecond=[NSCondition new];
            [readcond lock];
            condPredR=YES;
            [readcond broadcast];
            [readcond unlock];
        }
        
        return YES;
    }
    return NO;
}
-(BOOL) castUnorderedSet:(NSSet*)set exParams:(ASFKExecutionParams *)ex{
    if(set && [set count]>0){
        if(batchLimitUpper.load()<[set count] || batchLimitLower.load()>[set count]){
            WASFKLog(ASFK_STR_Q_ULIMIT_VIOLATION);
            return NO;
        }
        ASFKPriv_WrapBQ* wrap=[ASFKPriv_WrapBQ new];
        [wrap->many addObjectsFromArray:[set allObjects]];
        [lock lock];
        [q addObject:wrap];
        netCount.fetch_add([set count]);
        [lock unlock];
        if(blocking){
            wrap->writecond=[NSCondition new];
            [readcond lock];
            condPredR=YES;
            [readcond broadcast];
            [readcond unlock];
        }
        
        return YES;
    }
    return NO;
}

#pragma mark - Blocking interface
-(BOOL) callQueue:(ASFKQueue*)otherq{
    DASFKLog(ASFK_STR_VER_UNAVAIL_OP);
    return NO;
}
-(BOOL) callArray:(NSArray*)array exParams:(ASFKExecutionParams*) params{
    DASFKLog(ASFK_STR_VER_UNAVAIL_OP);
    return NO;
}
-(BOOL) callDictionary:(NSDictionary*)dict exParams:(ASFKExecutionParams *)params{
    DASFKLog(ASFK_STR_VER_UNAVAIL_OP);
    return NO;
}
-(BOOL) callOrderedSet:(NSOrderedSet*)set exParams:(ASFKExecutionParams *)params{
    DASFKLog(ASFK_STR_VER_UNAVAIL_OP);
    
    return NO;
}
-(BOOL) callUnorderedSet:(NSSet*)set exParams:(ASFKExecutionParams *)params{
    DASFKLog(ASFK_STR_VER_UNAVAIL_OP);
    return NO;
}
-(BOOL) callObject:(id _Nullable)item exParams:(ASFKExecutionParams * _Nullable)params{
    DASFKLog(ASFK_STR_VER_UNAVAIL_OP);
    return NO;
}
#pragma mark - querying
-(BOOL) isEmpty{
    [lock lock];
    BOOL e=netCount.load()>0?NO:YES;
    [lock unlock];
    return e;
}
-(NSUInteger )count{
    return netCount.load();
}
-(NSUInteger) batchCount{
    [lock lock];
    NSUInteger qc=[q count];
    [lock unlock];
    return qc;
}
-(NSUInteger) candidateCount{
    NSUInteger csize=0;
    [lock lock];
    csize=[tempWBQ->many count];
    [lock unlock];
    return csize;
}
-(NSArray* _Nullable ) pullBatchAsArray{
    if(paused){
        return nil;
    }
    if(blocking){
        [self->readcond lock];
        //if(paused==NO){
            [lock lock];
            condPredR=[q count]>0?YES:NO;
            [lock unlock];
            while (condPredR==NO) {
                [self->readcond wait];
            }
        //}
        [self->readcond unlock];
    }
    
    id subitem=nil;
    //if(paused==NO){
        [lock lock];
        id item=[q firstObject];
        if(item){
            subitem=((ASFKPriv_WrapBQ*)item)->many ;
            if(subitem){
                if(blocking && ((ASFKPriv_WrapBQ*)item)->writecond){
                    [((ASFKPriv_WrapBQ*)item)->writecond lock];
                    ((ASFKPriv_WrapBQ*)item)->wcPred=YES;
                    [((ASFKPriv_WrapBQ*)item)->writecond broadcast];
                    [((ASFKPriv_WrapBQ*)item)->writecond unlock];
                }
                netCount.fetch_sub([((ASFKPriv_WrapBQ*)item)->many count]);
                [q removeObjectAtIndex:0];
            }
        }
        else{
            
        }
        [lock unlock];;
        return subitem;
//    }
//    else{
//        
//    }
    
//    return nil;
}
-(id) pull{
    if(paused){
        return nil;
    }
    if(blocking){
        [self->readcond lock];
            [lock lock];
            condPredR=[q count]>0?YES:NO;
            [lock unlock];
            while (condPredR==NO) {
                [self->readcond wait];
            }
        [self->readcond unlock];
    }
    
    id subitem=nil;
    [lock lock];
    id item=[q firstObject];
    if(item){
        subitem=[((ASFKPriv_WrapBQ*)item)->many firstObject];
        if(subitem){
            [((ASFKPriv_WrapBQ*)item)->many removeObjectAtIndex:0];
            netCount.fetch_sub(1);
            if([((ASFKPriv_WrapBQ*)item)->many count]==0){
                [q removeObjectAtIndex:0];
                if(blocking && ((ASFKPriv_WrapBQ*)item)->writecond){
                    [((ASFKPriv_WrapBQ*)item)->writecond lock];
                    ((ASFKPriv_WrapBQ*)item)->wcPred=YES;
                    [((ASFKPriv_WrapBQ*)item)->writecond broadcast];
                    [((ASFKPriv_WrapBQ*)item)->writecond unlock];
                }
                
            }
        }
        else{
            
        }
    }
    
    [lock unlock];;
    return subitem;
}

@end
#pragma mark - Private
/*!
 This class is for private use. 
 */
@implementation ASFKBatchingQueue2
{
    
}
-(id) initWithName:(NSString *)name{
    self=[super initWithName:name];
    if(self){
        [self _initBQ2];
    }
    return self;
}
-(id) init{
    self=[super init];
    if(self){
        [self _initBQ2];
    }
    return self;
}
-(id) initWithName:(NSString*) name blocking:(BOOL)blk{
    self=[super initWithName:name blocking:blk];
    if(self){
        [self _initBQ2];
        blocking=blk;
    }
    return self;
}
-(void) _initBQ2{
    deferred=[NSMutableArray new];
}

-(id)   pullAndBatchStatus:(NSInteger&)itemsLeft endBatch:(BOOL&)endBatch term:(ASFKPriv_EndingTerm**)term{
    id subitem=nil;
    *term=nil;
    endBatch=NO;
//    if(paused.load()==NO){
//        
//    }
//    else{
//        //Paused
//        
//    }
    [lock lock];
    if([deferred count]>0){
        subitem=nil;
    }
    else
    {
        id item=[q firstObject];
        if(item){
            subitem=[((ASFKPriv_WrapBQ*)item)->many firstObject];
            if(subitem){
                [((ASFKPriv_WrapBQ*)item)->many removeObjectAtIndex:0];
                netCount.fetch_sub(1);
                if([((ASFKPriv_WrapBQ*)item)->many count]==0){
                    [q removeObjectAtIndex:0];
                    *term=[ASFKPriv_EndingTerm singleInstance];
                    endBatch=YES;
                    if(((ASFKPriv_WrapBQ*)item)->writecond){
                        [deferred addObject:(item)];
                    }
                }
            }
        }
    }
    
    [lock unlock];
    return subitem;
}
-(BOOL) castObject:(id)item exParams:(ASFKExecutionParams *)ex{
    if(item){
        ASFKPriv_WrapBQ* wrap=[ASFKPriv_WrapBQ new];
        //wrap->single=item;
        [wrap->many addObject:item];
        [lock lock];
        [q addObject:wrap];
        netCount.fetch_add(1);
        [lock unlock];
        return YES;
    }
    return NO;
}
-(BOOL) castArray:(NSArray*)array exParams:(ASFKExecutionParams *)ex{
    if(array && [array count]>0){
        ASFKPriv_WrapBQ* wrap=[ASFKPriv_WrapBQ new];

        [wrap->many addObjectsFromArray:array];
        [lock lock];
        [q addObject:wrap];
        netCount.fetch_add([wrap->many count]);
        [lock unlock];

        return YES;
    }
    return NO;
}
-(BOOL) castArray:(NSArray*)array groupBy:(NSUInteger) grpSize exParams:(ASFKExecutionParams*)ex{
    return NO;
}
-(BOOL) castArray:(NSArray*)array splitTo:(NSUInteger) numOfChunks exParams:(ASFKExecutionParams*)ex{
    return NO;
}
-(BOOL) castDictionary:(NSDictionary*)dict exParams:(ASFKExecutionParams *)ex{
    if(dict && [dict count]>0){
        ASFKPriv_WrapBQ* wrap=[ASFKPriv_WrapBQ new];
//        NSMutableArray* ma=[NSMutableArray array];
//        [ma addObjectsFromArray:[dict allValues]];

        [wrap->many addObjectsFromArray:[dict allValues]];
        [lock lock];
        [q addObject:wrap];
        netCount.fetch_add([wrap->many count]);
        [lock unlock];

        return YES;
    }
    return NO;
}
-(BOOL) castOrderedSet:(NSOrderedSet*)set exParams:(ASFKExecutionParams *)ex{
    if(set && [set count]>0){
        ASFKPriv_WrapBQ* wrap=[ASFKPriv_WrapBQ new];

        [wrap->many addObjectsFromArray:[set array]];
        [lock lock];
        [q addObject:wrap];
        netCount.fetch_add([set count]);
        [lock unlock];

        return YES;
    }
    return NO;
}
-(BOOL) castUnorderedSet:(NSSet*)set exParams:(ASFKExecutionParams *)ex{
    if(set && [set count]>0){
        ASFKPriv_WrapBQ* wrap=[ASFKPriv_WrapBQ new];

        [wrap->many addObjectsFromArray:[set allObjects]];
        [lock lock];
        [q addObject:wrap];
        netCount.fetch_add([wrap->many count]);
        [lock unlock];

        return YES;
    }
    return NO;
}

#pragma mark - Blocking interface
-(BOOL) callQueue:(ASFKQueue*)otherq{
    if(otherq){
        [lock lock];
        [otherq begin];
        NSArray* d=[otherq getData];
        [q addObjectsFromArray:d];
        [otherq commit];
        [lock unlock];
        return YES;
    }
    return NO;
}
-(BOOL) callArray:(NSArray*)array exParams:(ASFKExecutionParams*) params{
    if(blocking){
        if(array && [array count]>0){
            ASFKPriv_WrapBQ* wrap=[ASFKPriv_WrapBQ new];
            if(blocking){
                wrap->writecond=[NSCondition new];
            }
            [wrap->many addObjectsFromArray:array];
            [lock lock];
            [q addObject:wrap];
            netCount.fetch_add([wrap->many count]);
            [lock unlock];
            
            [wrap->writecond lock];
            if(params){
                params->preBlock();
            }
            while(!wrap->wcPred){
                [wrap->writecond wait];
            }
            [wrap->writecond unlock];
            return YES;
        }

    }
    else{
        return [self castArray:array exParams:params];
    }
    return NO;
}
-(BOOL) callDictionary:(NSDictionary*)dict exParams:(ASFKExecutionParams *)params{
    if(blocking){
        if(dict && [dict count]>0){
            ASFKPriv_WrapBQ* wrap=[ASFKPriv_WrapBQ new];
            if(blocking){
                wrap->writecond=[NSCondition new];
            }
            [wrap->many addObjectsFromArray:[dict allValues]];
            [lock lock];
            [q addObject:wrap];
            netCount.fetch_add([wrap->many count]);
            [lock unlock];
            
            
            [wrap->writecond lock];
            if(params){
                params->preBlock();
            }
            while(!wrap->wcPred){
                [wrap->writecond wait];
            }
            [wrap->writecond unlock];
            
            return YES;
        }

    }
    else{
        return [self callDictionary:dict exParams:params];
    }
    return NO;
}
-(BOOL) callOrderedSet:(NSOrderedSet*)set exParams:(ASFKExecutionParams *)params{
    if(blocking){
        if(set && [set count]>0){
            ASFKPriv_WrapBQ* wrap=[ASFKPriv_WrapBQ new];
            if(blocking){
                wrap->writecond=[NSCondition new];
            }
            [wrap->many addObjectsFromArray:[set array]];
            [lock lock];
            [q addObject:wrap];
            netCount.fetch_add([wrap->many count]);
            [lock unlock];
            
            
            [wrap->writecond lock];
            if(params){
                params->preBlock();
            }
            while(!wrap->wcPred){
                [wrap->writecond wait];
            }
            [wrap->writecond unlock];
            return YES;
        }
    }
    else{
        return [self castOrderedSet:set exParams:params];
    }
    return NO;
}
-(BOOL) callUnorderedSet:(NSSet*)set exParams:(ASFKExecutionParams *)params{
    if(blocking){
        if(set && [set count]>0){
            ASFKPriv_WrapBQ* wrap=[ASFKPriv_WrapBQ new];
            if(blocking){
                wrap->writecond=[NSCondition new];
            }
            [wrap->many addObjectsFromArray:[set allObjects]];
            [lock lock];
            [q addObject:wrap];
            netCount.fetch_add([wrap->many count]);
            [lock unlock];
            
            [wrap->writecond lock];
            if(params){
                params->preBlock();
            }
            while(!wrap->wcPred){
                [wrap->writecond wait];
            }
            [wrap->writecond unlock];
            return YES;
        }
    }
    else{
        return [self castUnorderedSet:set exParams:params];
    }
    
    return NO;
}
-(BOOL) callObject:(id)item exParams:(ASFKExecutionParams *)params{
    if(blocking){
        if(item){
            ASFKPriv_WrapBQ* wrap=[ASFKPriv_WrapBQ new];
            if(blocking){
                wrap->writecond=[NSCondition new];
            }
            [wrap->many addObject:item];
            [lock lock];
            [q addObject:wrap];
            netCount.fetch_add(1);
            [lock unlock];
            
            [wrap->writecond lock];
            if(params){
                params->preBlock();
            }
            [wrap->writecond wait];
            [wrap->writecond unlock];
            return YES;
        }
    }
    else{
        return [self castObject:item exParams:params];
    }
    return NO;
}
-(void) releaseFirst{
    [lock lock];

    if([deferred count]>0){
        ASFKPriv_WrapBQ* wrap = [deferred objectAtIndex:0];
        
        [wrap->writecond lock];
        wrap->wcPred=YES;
        [wrap->writecond broadcast];
        [wrap->writecond unlock];
        [deferred removeObjectAtIndex:0];
    }
    [lock unlock];
}
-(void) releaseAll{
    [lock lock];
    [deferred enumerateObjectsWithOptions:(NSEnumerationConcurrent) usingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [((ASFKPriv_WrapBQ*)obj)->writecond lock];
        ((ASFKPriv_WrapBQ*)obj)->wcPred=YES;
        [((ASFKPriv_WrapBQ*)obj)->writecond broadcast];
        [((ASFKPriv_WrapBQ*)obj)->writecond unlock];
    }];
    [deferred removeAllObjects];
    [lock unlock];
}

@end
/*For internal use*/
@implementation ASFKBatchingQueue3
{

}
-(id) initWithName:(NSString *)name{
    self=[super initWithName:name];
    if(self){
        [self _initBQ3];
    }
    return self;
}
-(id) init{
    self=[super init];
    if(self){
        [self _initBQ3];
    }
    return self;
}
-(void) _initBQ3{
    
}

-(void) releaseFirst{
    [lock lock];
    
    if([deferred count]>0){
        ASFKPriv_WrapBQ* wrap = [deferred objectAtIndex:0];
        [wrap->writecond lock];
        wrap->wcPred=YES;
        [wrap->writecond broadcast];
        [wrap->writecond unlock];
        [deferred removeObjectAtIndex:0];
    }
    [lock unlock];
}

-(id)   pullAndBatchStatus:(NSInteger&)itemsLeft endBatch:(BOOL&)endBatch term:(ASFKPriv_EndingTerm**)term{
    id subitem=nil;
    endBatch=NO;
//    if(paused.load()==NO){
//        
//    }
//    else{
//        //Paused
//        
//    }
    [lock lock];
    {
        id item=[q firstObject];
        if(item){
            subitem=[((ASFKPriv_WrapBQ*)item)->many firstObject];
            if(subitem){
                [((ASFKPriv_WrapBQ*)item)->many removeObjectAtIndex:0];
                netCount.fetch_sub(1);
                if([((ASFKPriv_WrapBQ*)item)->many count]==0){
                    [q removeObjectAtIndex:0];
                    *term=[ASFKPriv_EndingTerm singleInstance];
                    endBatch=YES;
                    if(((ASFKPriv_WrapBQ*)item)->writecond){
                        [deferred addObject:(item)];
                    }
                }
            }
        }
        
    }
    [lock unlock];
    return subitem;
}

@end


