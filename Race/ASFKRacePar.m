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
//  Created by Boris Vigman on 29/03/2019.
//  Copyright © 2019 Boris Vigman. All rights reserved.
//

#import "ASFKRacePar.h"
@interface ASFKRacePar ()
@property (atomic) NSMutableArray<ASFKExecutableProcedure>* procedures;
@property dispatch_queue_t parQ;
@property NSMutableDictionary* dprocs;

@property (nonatomic) NSLock* lock;
@end
@implementation ASFKRacePar
-(id) init{
    self = [super init];
    if(self){
        self.lock=[NSLock new];
        NSString* rand=[[self generateRandomNumber]stringValue];
        self.parQ= dispatch_queue_create([[@"com.race.par.Q1." stringByAppendingString:rand]cStringUsingEncoding:NSASCIIStringEncoding], DISPATCH_QUEUE_CONCURRENT);
        rand=nil;
        rand=[[self generateRandomNumber]stringValue];
        self.dprocs=[NSMutableDictionary dictionary];
        self.stopAfterN=1;
        //self.serQ = dispatch_queue_create([[@"com.race.seq.Q1." stringByAppendingString:rand]cStringUsingEncoding:NSASCIIStringEncoding], DISPATCH_QUEUE_SERIAL);
        //rand=nil;
    }
    return self;
}
-(id) storeProcedure:(ASFKExecutableProcedure) proc withId:(id)identity{
    if(proc&&identity){
        id key=nil;
        if(identity){
            key=identity;
        }else{
            key=@([self.dprocs count]);
        }
        [self.dprocs setObject:proc forKey:key];
        return key;
    }
    return nil;
}
-(void) storeProcedureC:(ASFKExecutableProcedureCStyle)proc{
    
}
-(void) storeProcedures:(NSArray<ASFKExecutableProcedure>*)procs{
    NSUInteger c=0;
    for (ASFKExecutableProcedure p in procs) {
        [self storeProcedure:p withId:@(c)];
        c++;
    }
}
-(void) storeProcedure:(ASFKExecutableProcedure)proc{
    NSLog(@"WARNING: the method ASFKRacePar::storeProcedure is unavailable in this class");
}
-(NSArray*) runOnArray:(NSArray*)array {
    return [self runOnArray:array withProcedures:self.procs withSummary:self.sumproc];
}
-(NSArray*) runOnArray:(NSArray*)array withSummary:(ASFKExecutableProcedureSummary)summary{
    return [self runOnArray:array withProcedures:self.procs withSummary:summary];
}
-(NSArray*) runOnArray:(NSArray*)array withProcedures:(NSArray<ASFKExecutableProcedure>*) procs{
    return [self runOnArray:array withProcedures:procs withSummary:self.sumproc];
}
-(NSArray*) runOnArray:(NSArray*)array withProcedures:(NSArray<ASFKExecutableProcedure>*) procs withSummary:(ASFKExecutableProcedureSummary)summary{
    if(procs && array){
        if([procs count]!=[array count]){
            NSLog(@"ERROR: Number of data elements differs from number of procedures");
            return @[];
        }
        __block NSMutableArray* ma=[NSMutableArray array];
        __block NSUInteger count=self.stopAfterN;
        NSUInteger i=0;
        for (id elem in array) {
            id obj=[array objectAtIndex:i];
            ASFKExecutableProcedure proc=[procs objectAtIndex:i];
            ++i;
            if(proc==nil){
                continue;
            }
            ASFKDefaultBlockType b=^{
                id result=nil;
                [self.lock lock];
                if (count>0){
                    [self.lock unlock];
                    result=proc(self.controlData,nil,i,obj);
                    [self.lock lock];
                    [ma addObject:result];
                    count--;
                    [self.lock unlock];
                }else{
                    [self.controlData requestCancellation];
                    [self.lock unlock];
                }
            };
            if(self.enabledNonBlockingExecution){
                dispatch_async(self.parQ, ^{
                    b();
                });
            }else{
                dispatch_sync(self.parQ, ^{
                    b();
                });
            }
        }
        if(summary){
            if(self.enabledNonBlockingExecution){
                dispatch_barrier_async(self.parQ, ^{
                    summary(self.controlData, ma);
                    [ma removeAllObjects];
                    ma = nil;
                });
            }else{
                summary(self.controlData, ma);
                return ma;
            }
        }
    }
    return array;
}

-(NSDictionary*) runOnDictionary:(NSDictionary*)dictionary{
    NSMutableDictionary* md=[[NSMutableDictionary alloc]init];
    
    return [self runOnDictionary:dictionary withNamedProcedures:self.dprocs withSummary:self.sumproc];
}
-(NSDictionary*) runOnDictionary:(NSDictionary*)dictionary withProcedures:(NSArray<ASFKExecutableProcedure>*) procs{
    NSMutableDictionary* md=[[NSMutableDictionary alloc]init];
    long long i=0;
    for (ASFKExecutableProcedure p in procs) {
        [md setObject:p forKey:@(i)];
        i++;
    }
    
    return [self runOnDictionary:dictionary withNamedProcedures:md withSummary:self.sumproc];
}
-(NSDictionary*) runOnDictionary:(NSDictionary*)dictionary withSummary:(ASFKExecutableProcedureSummary)summary{
    return [self runOnDictionary:dictionary withNamedProcedures:self.dprocs withSummary:summary];
}
-(NSDictionary*) runOnDictionary:(NSDictionary*)dictionary withProcedures:(NSArray<ASFKExecutableProcedure>*) procs withSummary:(ASFKExecutableProcedureSummary)summary{
    NSMutableDictionary* md=[[NSMutableDictionary alloc]init];
    long long i=0;
    for (ASFKExecutableProcedure p in procs) {
        [md setObject:p forKey:@(i)];
        i++;
    }

    return [self runOnDictionary:dictionary withNamedProcedures:md withSummary:summary];
}
-(NSDictionary*) runOnDictionary:(NSDictionary*)dictionary withNamedProcedures:(NSDictionary*) procs withSummary:(ASFKExecutableProcedureSummary)summary{
    if(procs && dictionary){
        __block NSMutableDictionary* md=[NSMutableDictionary dictionary];
        __block NSUInteger count=self.stopAfterN;
        long long i=0;
        for (id key in dictionary) {
            id obj=[dictionary objectForKey:key];
            ASFKExecutableProcedure proc=[procs objectForKey:key];
            if(proc==nil){
                continue;
            }
            ASFKDefaultBlockType b=^{
                id result=nil;
                [self.lock lock];
                if (count>0){
                    [self.lock unlock];
                    result=proc(self.controlData,key,-1,obj);
                    [self.lock lock];
                    [md setObject:result forKey:@(i)];
                    count--;
                    [self.lock unlock];
                }else{
                    [self.controlData requestCancellation];
                    [self.lock unlock];
                }
            };
            if(self.enabledNonBlockingExecution){
                dispatch_async(self.parQ, ^{
                    b();
                });
            }else{
                dispatch_sync(self.parQ, ^{
                    b();
                });
            }
        }
        if(summary){
            if(self.enabledNonBlockingExecution){
                dispatch_barrier_async(self.parQ, ^{
                    summary(self.controlData, md);
                    [md removeAllObjects];
                    md = nil;
                });
            }else{
                summary(self.controlData, md);
                return md;
            }
        }
    }
    return dictionary;
}

-(id) runOnUnspecified:(id)uns{
    return uns;
}
-(id) runOnUnspecified:(id)uns withSummary:(ASFKExecutableProcedureSummary)summary{
    return uns;
}
-(id) runOnUnspecified:(NSDictionary*)uns withProcedures:(NSArray<ASFKExecutableProcedure>*) procs{
    return uns;
}
-(id) runOnUnspecified:(id)uns withProcedures:(NSArray<ASFKExecutableProcedure>*) procs withSummary:(ASFKExecutableProcedureSummary)summary{
    return uns;
}

@end
