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

#import "ASFKExpirationCondition.h"
#import "ASFKBase.h"
#include <chrono>
@implementation ASFKCondition{
    std::atomic<BOOL> setDates;
    NSMutableArray<NSDate*>* datesArray;
    std::atomic<BOOL> setData;
    NSMutableArray* dataArray;
    std::atomic<BOOL> setULL;
    std::vector<NSUInteger> vectULL;
    std::atomic<BOOL> setLL;
    std::vector<NSInteger> vectLL;
    std::atomic<BOOL> setDouble;
    std::vector<double> vectDouble;
    std::atomic<BOOL> setBool;
    std::vector<BOOL> vectBool;
}
-(void) _initCond{
    lock = [NSLock new];
    setDates=NO;
    datesArray=[NSMutableArray new];
    setData=NO;
    dataArray =[NSMutableArray new];
    setULL=NO;
    vectULL.resize(1);
    setLL=NO;
    vectLL.resize(1);
    setBool=NO;
    vectBool.resize(1);
    setDouble=NO;
    vectDouble.resize(1);
}
-(id) init{
    self=[super init];
    if(self){
        [self _initCond];
        
    }
    return self;
}
-(BOOL) setULonglongArg:(NSUInteger)arg{
    BOOL tval=NO;
    if(setULL.compare_exchange_strong(tval,YES)){
        [lock lock];
        if(vectULL.size() != 1){
            vectULL.resize(1);
        }
        vectULL[0]=arg;
        [lock unlock];
        return YES;
    }
    return NO;
}
-(BOOL) setLonglongArg:(NSInteger)arg{
    BOOL tval=NO;
    if(setLL.compare_exchange_strong(tval,YES)){
        [lock lock];
        if(vectLL.size() != 1){
            vectLL.resize(1);
        }
        vectLL[0]=arg;
        [lock unlock];
        return YES;
    }
    return NO;
}
-(BOOL) setBoolArg:(BOOL)arg{
    BOOL tval=NO;
    if(setBool.compare_exchange_strong(tval,YES)){
        [lock lock];
        if(vectBool.size() != 1){
            vectBool.resize(1);
        }
        vectBool[0]=arg;
        [lock unlock];
        return YES;
    }
    return NO;
}
-(BOOL) setDoubleArg:(double)arg{
    BOOL tval=NO;
    if(setDouble.compare_exchange_strong(tval,YES)){
        [lock lock];
        if(vectDouble.size() != 1){
            vectDouble.resize(1);
        }
        vectDouble[0]=arg;
        [lock unlock];
        return YES;
    }
    return NO;
    
}
-(BOOL) setObjArg:(id)arg{
    BOOL tval=NO;
    if(setData.compare_exchange_strong(tval,YES)){
        if(arg){
            [lock lock];
            if([dataArray count]>0){
                [dataArray removeAllObjects];
            }
            [dataArray addObject:arg];
            [lock unlock];
        }
        else{
            [lock lock];
            [dataArray removeAllObjects];
            [lock unlock];
        }
        return YES;
    }
    return NO;
}
-(BOOL) setDateArg:(NSDate*)arg{
    BOOL tval=NO;
    if(setDates.compare_exchange_strong(tval,YES)){
        if(arg){
            [lock lock];
            if([datesArray count]>0){
                [datesArray removeAllObjects];
            }
            [datesArray addObject:arg];
            [lock unlock];
        }
        else{
            [lock lock];
            [datesArray removeAllObjects];
            [lock unlock];
        }
        return YES;
    }
    return NO;
}
-(BOOL) setULonglongArgs:(std::vector<NSUInteger>&)args{
    BOOL tval=NO;
    if(setULL.compare_exchange_strong(tval,YES)){
        [lock lock];
        if(vectULL.size() != args.size()){
            vectULL.resize(args.size());
        }
        vectULL=args;
        [lock unlock];
        return YES;
    }
    return NO;
}
-(BOOL) setLonglongArgs:(std::vector<NSInteger>&)args{
    BOOL tval=NO;
    if(setLL.compare_exchange_strong(tval,YES)){
        [lock lock];
        if(vectLL.size() != args.size()){
            vectLL.resize(args.size());
        }
        vectLL = args;
        [lock unlock];
        return YES;
    }
    return NO;
}
-(BOOL) setBoolArgs:(std::vector<BOOL>&)args{
    BOOL tval=NO;
    if(setBool.compare_exchange_strong(tval,YES)){
        [lock lock];
        if(vectBool.size() != args.size()){
            vectBool.resize(args.size());
        }
        vectBool = args;
        [lock unlock];
        return YES;
    }
    return NO;
}
-(BOOL) setDoubleArgs:(std::vector<double>&)args{
    BOOL tval=NO;
    if(setDouble.compare_exchange_strong(tval,YES)){
        [lock lock];
        if(vectDouble.size() != args.size()){
            vectDouble.resize(args.size());
        }
        vectDouble = args;
        [lock unlock];
        return YES;
    }
    return NO;
}
-(BOOL) setDateArgs:(NSArray<NSDate*>*)args{
    BOOL tval=NO;
    if(setDates.compare_exchange_strong(tval,YES)){
        if(args){
            [lock lock];
            if([datesArray count] != [args count]){
                [datesArray removeAllObjects];
            }
            [datesArray arrayByAddingObjectsFromArray:args];
            [lock unlock];
        }
        else{
            [lock lock];
            [datesArray removeAllObjects];
            [lock unlock];
        }
        return YES;
    }
    return NO;
}
-(BOOL) setObjArgs:(NSArray*)args{
    BOOL tval=NO;
    if(setData.compare_exchange_strong(tval,YES)){
        if(args){
            [lock lock];
            if([dataArray count] != [args count]){
                [dataArray removeAllObjects];
            }
            [dataArray arrayByAddingObjectsFromArray:args];
            [lock unlock];
        }
        else{
            [lock lock];
            [dataArray removeAllObjects];
            [lock unlock];
        }
        return YES;
    }
    return NO;
}
-(std::vector<NSUInteger>&) getULLVector{
    return vectULL;
}
-(std::vector<NSInteger>&) getLLVector{
    return vectLL;
}
-(std::vector<double>&) getDoubleVector{
    return vectDouble;
}
-(std::vector<BOOL>&) getBoolVector{
    return vectBool;
}
-(NSArray<NSDate*>*) getDateVector{
    return datesArray;
}
-(NSArray*) getDataVector{
    return dataArray;
}
-(BOOL) isConditionMet:(id) data{
    return NO;
}
-(BOOL) isConditionMetForDoubleValues:(std::vector<double>&)values data:(id)data{
    return NO;
}
-(BOOL) isConditionMetForBoolValues:(std::vector<BOOL>&)value data:(id)data{
    return NO;
}
-(BOOL) isConditionMetForULonglongValues:(std::vector<NSUInteger>&)value data:(id)data{
    return NO;
}
-(BOOL) isConditionMetForLonglongValues:(std::vector<NSInteger>&)value data:(id)data{
    return NO;
}
-(BOOL) isConditionMetAfterDateValues:(NSDate*)aDate data:(id)data{
    return NO;
}
-(BOOL) isConditionMetForObject:(id)data{
    return NO;
}
-(BOOL) isConditionMetForDoubleValue:(double)value data:(id)data{
    return NO;
}
-(BOOL) isConditionMetForBoolValue:(BOOL)value data:(id)data{
    return NO;
}
-(BOOL) isConditionMetForULonglongValue:(NSUInteger)value data:(id)data{
    return NO;
}
-(BOOL) isConditionMetForLonglongValue:(NSInteger)value data:(id)data{
    return NO;
}
@end

@implementation ASFKConditionNone

@end


@implementation ASFKConditionTemporal{
    std::chrono::time_point<std::chrono::system_clock, std::chrono::microseconds>  timePoint;
}
-(void) _setDeadline:(NSDate*)aDate{
    if(aDate){

        _itsDelay=-1;//dd0/double(1e6);
        _itsDeadline=aDate;
    }else{
        _itsDelay=-1;
        _itsDeadline=nil;
    }
}
-(void) _setDelay:(NSTimeInterval)seconds{
    if(seconds>0){
        using namespace std::chrono;

        _itsDelay=seconds;

    }
    else{
        _itsDelay=-1;
    }
    _itsDeadline=nil;
}
-(id) init{
    self =[super init];
    if(self){
        _itsDelay=-1;
        _itsDeadline=nil;
    }
    return self;
}
-(id) initWithSeconds:(NSTimeInterval)sec{
    self =[super init];
    if(self){
        [self _setDelay:sec];
    }
    return self;
}
-(id) initWithDate:(NSDate*)aDate{
    self =[super init];
    if(self){
        [self _setDeadline:aDate];
    }
    return self;
}
-(void) setDelay:(NSTimeInterval) seconds{
     [self _setDelay:seconds];
}
-(void) setDueDate:(NSDate*) aDate{
    [self _setDeadline:aDate];
}
-(void) delayToDeadline{
    if(self.itsDelay>0){
        _itsDeadline = [NSDate dateWithTimeIntervalSinceNow:self.itsDelay];
    }
}
-(void) deadlineToDelay{
    if(self.itsDeadline){
        _itsDelay=[self.itsDeadline timeIntervalSinceNow ];
        if(_itsDelay<0){
            _itsDelay = -1;
        }
    }
}
-(void) setFromTemporalCondition:(ASFKConditionTemporal*)cond{
    if(cond){
        if(cond.itsDelay>0){
            [self _setDelay:cond.itsDelay];
        }
        else if(cond.itsDeadline){
            [self _setDeadline:cond.itsDeadline];
        }
    }
}

-(ASFKConditionTemporal*) chooseEarliest:(ASFKConditionTemporal*)cond{
    if(cond){
        if(cond.itsDeadline && _itsDeadline){
            if([_itsDeadline compare:cond.itsDeadline]==NSOrderedAscending){
                return self;
            }
            return cond;
        }
        if(cond.itsDelay>0 && _itsDelay>0){
            if( cond.itsDelay > _itsDelay){
                return self;
            };
            return cond;
        }
        else{
            if(cond.itsDelay>0){
                return cond;
            }
        }
    }
    return self;
}
-(ASFKConditionTemporal*) chooseLatest:(ASFKConditionTemporal*)cond{
    if(cond){
        if(cond.itsDeadline && _itsDeadline){
            if([_itsDeadline compare:cond.itsDeadline]!=NSOrderedAscending){
                return self;
            }
            return cond;
        }
        if(cond.itsDelay>0 && _itsDelay>0){
            if( !(cond.itsDelay > _itsDelay)){
                return self;
            };
            return cond;
        }
        else{
            if(cond.itsDelay>0){
                return cond;
            }
        }
    }
    return self;
}
-(ASFKConditionTemporal*) testAndSetEarliest:(ASFKConditionTemporal*)cond{
    if(cond){
        if(_itsDeadline && cond.itsDeadline){
            NSComparisonResult cr=[_itsDeadline compare:cond.itsDeadline];
            if(cr!=NSOrderedAscending)
            {
                [self _setDeadline:cond.itsDeadline];
            }
        }
        else if(cond.itsDeadline){
            [self _setDeadline:cond.itsDeadline];
        }
        else if(_itsDelay>0 && cond.itsDelay>0){
            if(_itsDelay>cond.itsDelay){
                [self setDelay:cond.itsDelay];
            }
        }
        else if(cond.itsDelay>0){
            [self setDelay:cond.itsDelay];
        }
    }
    return self;
}
-(ASFKConditionTemporal*) testAndSetLatest:(ASFKConditionTemporal*)cond{
    if(cond){
        if(_itsDeadline && cond.itsDeadline){
            NSComparisonResult cr=[_itsDeadline compare:cond.itsDeadline];
            if(cr==NSOrderedAscending)
            {
                [self _setDeadline:cond.itsDeadline];
            }
        }
        else if(cond.itsDeadline){
            [self _setDeadline:cond.itsDeadline];
        }
        else if(_itsDelay>0 && cond.itsDelay>0){
            if(!(_itsDelay>cond.itsDelay)){
                [self setDelay:cond.itsDelay];
            }
        }
        else if(cond.itsDelay>0){
            [self setDelay:cond.itsDelay];
        }
    }
    return self;
}

-(BOOL) isConditionMetAfterDateValue:(NSDate*)aDate data:(id)data{
    if(_itsDeadline){
        NSComparisonResult cr=[_itsDeadline compare:aDate];

         if(cr==NSOrderedDescending || cr == NSOrderedSame){
            return NO;
        }
        return YES;
    }
    return NO;
}
@end

@implementation ASFKExpirationCondition
-(BOOL) setSampleLongLong:(NSInteger) val{
    return NO;
}
@end

@implementation ASFKExpirationConditionNone

@end

@implementation ASFKExpirationConditionOnTimer
-(id) init{
    self = [super init];
    if(self){
        _expirationTimer=[ASFKConditionTemporal new];
    }
    return self;
}
-(id) initWithSeconds:(NSTimeInterval)sec{
    self = [super init];
    if(self){
        _expirationTimer=[ASFKConditionTemporal new];
        [_expirationTimer setDelay:sec];
        [_expirationTimer delayToDeadline];
    }
    return self;
}
-(id) initWithDate:(NSDate*)aDate{
    if(self){
        _expirationTimer=[ASFKConditionTemporal new];
        [_expirationTimer setDueDate:aDate];
        [_expirationTimer deadlineToDelay];
    }
    return self;
}
-(id) initWithTemporalCondition:(ASFKConditionTemporal*)cond{
    if(self){
        _expirationTimer=[ASFKConditionTemporal new];
        [_expirationTimer setFromTemporalCondition:cond];
    }
    return self;
}

-(BOOL) isConditionMet:(id) data{
    BOOL r=NO;
    if([self.expirationTimer isConditionMetAfterDateValue:[NSDate date] data:nil]){
        r=YES;
        NSLog(@"expiration by timer");
    }
    return r;
}

@end

@implementation ASFKExpirationOnBatchEnd{
    std::atomic<NSInteger> batchSize;
    std::atomic<NSInteger> skipItems;
    std::atomic<NSInteger> sample;
}
-(id) init{
    self = [super init];
    if(self){
        sample=0;
        skipItems=0;
        batchSize=0;
    }
    return self;
}
-(id) initWithBatchSize:(NSInteger)size skip:(NSInteger)skip{
    self = [super init];
    if(self){
        if(skip<0){
            skip=0;
        }
        if(size<0){
            size=0;
        }
        sample=0;
        skipItems=skip;
        batchSize=size;

    }
    return self;
}
-(BOOL) isConditionMet:(id)data{
    
    BOOL x=[self isConditionMetForLonglongValue:sample data:nil];
    
    return x;
}
-(BOOL) isConditionMetForLonglongValue:(NSInteger)value data:(id)data{
    BOOL res=NO;
    if(value > 0){
        skipItems.fetch_sub(1);
    }
    
    if(skipItems.load() > 0){
        return NO;
    }
    if(batchSize > 0){
        batchSize.fetch_sub(1);
    }
    if(batchSize > 0){
        res=NO;
    }
    else{
        res=YES;
    }
    return res;
}
-(BOOL) setSampleLongLong:(NSInteger)val{
    sample=val;
    return YES;
}
@end

@implementation ASFKConditionCallRelease

@end
