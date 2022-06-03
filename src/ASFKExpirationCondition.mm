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
@implementation ASFKCondition
-(BOOL) isConditionMetForDoubleValues:(std::vector<double>&)values data:(id)data{
    return NO;
}
-(BOOL) isConditionMetForBoolValues:(std::vector<BOOL>&)value data:(id)data{
    return NO;
}
-(BOOL) isConditionMetForULonglongValues:(std::vector<unsigned long long>&)value data:(id)data{
    return NO;
}
-(BOOL) isConditionMetForLonglongValues:(std::vector<long long>&)value data:(id)data{
    return NO;
}
-(BOOL) isConditionMetAfterDateValues:(NSDate*)aDate data:(id)data{
    return NO;
}
-(BOOL) isConditionMetForObject:(id)data{
    return NO;
}
@end

@implementation ASFKConditionNone

@end

@implementation ASFKConditionOnBatchEnd

-(BOOL) isConditionMetForLonglongValues:(std::vector<long long>&)values data:(id)data{
    if(values.size()>0 && values[0]>0){
        return NO;
    }
    return YES;
}
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
@end

@implementation ASFKExpirationConditionNone

@end
@implementation ASFKExpirationOnBatchEnd{
    std::atomic<unsigned long long> batchSize;
}
-(id) init{
    self = [super init];
    if(self){
        batchSize=ULONG_MAX;
    }
    return self;
}
-(id) initWithBatchSize:(unsigned long long) bsize{
    self = [super init];
    if(self){
        batchSize=bsize;
    }
    return self;
}
-(BOOL) isConditionMetForLonglongValue:(std::vector<long long>&)values data:(id)data{
    batchSize.fetch_sub(1);
    if(batchSize.load()>0){
        return NO;
    }
    return YES;
}
@end
@implementation ASFKConditionCallRelease

@end
