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
//  Created by Boris Vigman on 05/04/2019.
//  Copyright © 2019-2023 Boris Vigman. All rights reserved.
//

#import "ASFKBase+Internal.h"

@implementation ASFKBase (Internal)
+(uint64_t)getTimestamp{
    mach_timebase_info_data_t _clock_timebase;
    mach_timebase_info(&_clock_timebase);
    uint64_t machtime = mach_absolute_time();
    uint64_t nanos = (machtime * _clock_timebase.numer) / _clock_timebase.denom;
    return nanos;
}
+(NSString*) generateRandomString{
    int r = arc4random();
    NSMutableString* st=[[NSMutableString alloc] initWithString:[[NSNumber numberWithInt:r]stringValue ]];
    return st;
}
+(ASFK_IDENTITY_TYPE) concatIdentity:(ASFK_IDENTITY_TYPE)primaryId withIdentity:(ASFK_IDENTITY_TYPE)secondaryId{
    if(primaryId){
        if(secondaryId){
            NSString* subid=[((NSNumber*)secondaryId )stringValue];
            return [primaryId stringByAppendingFormat:(@"+(%@)"),subid];
        }else{
            return primaryId;
        }
    }else if(secondaryId){
        return secondaryId;
    }
    return primaryId;
}
+(ASFK_IDENTITY_TYPE) generateIdentity{
    return [[NSUUID UUID]UUIDString];
}
+(NSNumber*) generateRandomNumber{
    long long r = arc4random();
    NSNumber* n=[NSNumber numberWithLongLong:r];
    return n;
}
+(NSArray*)  splitArray:(NSArray*) array to:(NSUInteger) chunks{
    if(array && [array count]>0){
        if(chunks > 0 && chunks <= [array count]){
            NSMutableArray* ma=[NSMutableArray array];
            NSUInteger asize=[array count]/chunks;
            NSUInteger rem=[array count]%chunks;
            for(NSUInteger i=0;i<chunks;++i){
                NSMutableArray* ma0=[NSMutableArray array];
                for(NSUInteger j=0;j<asize;++j){
                    [ma0 addObject:[array objectAtIndex:(i * asize) + j]];
                }
                [ma addObject:ma0];
            }
            if(rem>0){
                for (NSUInteger k=0; k<rem; ++k) {
                    [[ma lastObject]addObject:[array objectAtIndex:(asize * chunks) + k]];
                }
            }
            return ma;
        }
        return array;
    }
    return array;
}
+(NSArray*)  groupArray:(NSArray*) array by:(NSUInteger) items{
    if(array && [array count]>0){
        if(items > 0 && items <= [array count]){
            NSMutableArray* ma=[NSMutableArray array];
//            NSUInteger chunks=[array count]/items;
//            NSUInteger rem=[array count]%items;
//            if(rem>0){
//                ++chunks;
//            }
            for(NSUInteger i=0,j=0;i<[array count];++i,++j){
                NSMutableArray* ma0=[ma lastObject];;
                if(j==items){
                    j=0;
                }
                if(j==0){
                    ma0=[NSMutableArray array];
                    [ma addObject:ma0];
                }
                [ma0 addObject:[array objectAtIndex:i]];
                
            }
            
            return ma;
        }
        return array;
    }
    return array;
}
-(BOOL) isCancellationRequested{
    
    return NO;
}
-(ASFKControlBlock*) refreshCancellationData{
    
    return nil;
}
-(void) registerSession:(ASFKControlBlock*)cblk{
    if(cblk){
        ASFKLog(@"INFO: Registering session %@",cblk.sessionId);
        [lkNonLocal lock];
        [ctrlblocks setObject:cblk forKey:cblk.sessionId];
        [lkNonLocal unlock];
    }
}
-(ASFKControlBlock*) newSession{
    ASFKLog(@"Adding session");
    ASFKControlBlock* b=[[ASFKControlBlock alloc]initWithParent:self.itsName sessionId:[ASFKBase generateIdentity] andSubId:nil];
    [self registerSession:b];
    
    return b;
}
-(ASFKControlBlock*) newSession:(ASFK_IDENTITY_TYPE)sessionId andSubsession:(ASFK_IDENTITY_TYPE)subId{
    ASFKLog(@"Adding sub-session");
    ASFKControlBlock* b=[[ASFKControlBlock alloc]initWithParent:self.itsName sessionId:sessionId andSubId:subId];
    [self registerSession:b];
    
    return b;
}
-(void) forgetAllSessions{
    DASFKLog(@" Unregistering all sessions");
    [lkNonLocal lock];
    [ctrlblocks removeAllObjects];
    [lkNonLocal unlock];
}
-(void) forgetSession:(NSString*)sessionId{
    DASFKLog(@" Forgetting session %@",sessionId);
    if(sessionId){
        [lkNonLocal lock];
        ASFKControlBlock* cb= [ctrlblocks objectForKey:sessionId];
        if(cb){
            [ctrlblocks removeObjectForKey:cb.sessionId];
            cb=nil;
        }else{
            WASFKLog(@" Failed to forget session because session identifier was not found");
        }
        [lkNonLocal unlock];
    }else{
        WASFKLog(@" Failed to forget session because session identifier is invalid");
    }
}
-(ASFKControlBlock*) getControlBlockWithId:(NSString*)blkId{
    if(blkId){
        [lkNonLocal lock];
        ASFKControlBlock* r=[ctrlblocks objectForKey:blkId];
        [lkNonLocal unlock];
        return r;
    }
    return nil;;
}
-(void)terminate:(ASFKControlBlock*)cblk{
    if(cblk){
        ASFKLog(@" Terminating session %@",cblk.sessionId);
        [self cancelSession:cblk.sessionId];
    }
}
-(void)setProgressRoutine:(ASFKProgressRoutine)prog{
    if(prog!=nil){
        progressProc=prog;
    }
}
@end
