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
//  ASFKMapPar.m
//
//  Created by Boris Vigman on 23/02/2019.
//  Copyright © 2019 Boris Vigman. All rights reserved.
//

#import "ASFKMapPar.h"
#import "ASFKControlBlock+Private.h"

@interface ASFKMapPar()
@property dispatch_queue_t parQ;
@property NSLock* lock;
@end
@implementation ASFKMapPar
-(id) init{
    self=[super init];
    {
        NSString* rand=[[self generateRandomNumber]stringValue];
        self.parQ = dispatch_queue_create([[@"com.map.par.1." stringByAppendingString:rand]cStringUsingEncoding:NSASCIIStringEncoding], DISPATCH_QUEUE_CONCURRENT);
        self.lock=[[NSLock alloc]init];
    }
    return self;
}

-(NSArray*) runOnArray:(NSArray*)array withProcedures:(NSArray<ASFKExecutableProcedure>*) procs withSummary:(ASFKExecutableProcedureSummary)summary{
    if(procs && array){
        NSUInteger j=[array count];
        __block NSMutableArray* ma=[NSMutableArray array];
        long long i;
        for (i=0; i<j;++i) {
            id obj=[array objectAtIndex:i];
            [self.lock lock];
            [ma addObject:[NSNull null]];
            [self.lock unlock];
            if(self.enabledNonBlockingExecution){
                dispatch_async(self.parQ, ^{
                    id result=obj;
                    for (ASFKExecutableProcedure proc in procs) {
                        result=proc(self.controlData,nil,i,result);
                    }
                    [self.lock lock];
                    [ma replaceObjectAtIndex:i withObject:result];
                    [self.lock unlock];
                });
            }else{
                    id result=obj;
                    for (ASFKExecutableProcedure proc in procs) {
                        result=proc(self.controlData,nil,i,result);
                    }
                    [self.lock lock];
                    [ma replaceObjectAtIndex:i withObject:result];
                    [self.lock unlock];
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

-(NSDictionary*) runOnDictionary:(NSDictionary*)dictionary withProcedures:(NSArray<ASFKExecutableProcedure>*) procs withSummary:(ASFKExecutableProcedureSummary)summary{
    if(procs && dictionary){
        __block NSMutableDictionary* md=[NSMutableDictionary dictionary];
        self.controlData.isBusy=YES;
        for (id key in dictionary) {
            id obj=[dictionary objectForKey:key];
            if(self.enabledNonBlockingExecution){
                dispatch_async(self.parQ, ^{
                    id result=obj;
                    for (ASFKExecutableProcedure proc in procs) {
                        result=proc(self.controlData,key,-1,result);
                    }
                    [md setObject:result forKey:key];
                });
            }else{
                id result=obj;
                for (ASFKExecutableProcedure proc in procs) {
                    result=proc(self.controlData,key,-1,result);
                }
                [md setObject:result forKey:key];
            }
        }
        if(summary){
            if(self.enabledNonBlockingExecution){
                dispatch_barrier_async(self.parQ, ^{
                    summary(self.controlData, md);
                    [md removeAllObjects];
                    md = nil;
                    self.controlData.isBusy=NO;
                });
            }else{
                summary(self.controlData, md);
                self.controlData.isBusy=NO;
                return md;
            }
        }
    }
    return dictionary;
}

@end
