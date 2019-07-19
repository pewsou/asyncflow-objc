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
//  Copyright © 2019 Boris Vigman. All rights reserved.
//

#import "ASFKComposeSeq.h"

@interface ASFKComposeSeq()
@property dispatch_queue_t exQ;
@property NSLock* lock;
@end
@implementation ASFKComposeSeq

-(id)init{
    self = [super init];
    if(self){
        NSString* rand=[[self generateRandomNumber]stringValue];
        self.exQ = dispatch_queue_create([[@"com.compose.seq.1." stringByAppendingString:rand]cStringUsingEncoding:NSASCIIStringEncoding], DISPATCH_QUEUE_SERIAL);
        rand=nil;
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
            [self.lock lock];
            [ma addObject:[NSNull null]];
            [self.lock unlock];
            id obj=[array objectAtIndex:i];
            if(self.enabledNonBlockingExecution){
                dispatch_async(self.exQ, ^{
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
                [ma replaceObjectAtIndex:i withObject:result];
            }
        }
        if(summary){
            if(self.enabledNonBlockingExecution){
                dispatch_async(self.exQ, ^{
                    summary(self.controlData, ma);
                    [self.lock lock];
                    [ma removeAllObjects];
                    ma = nil;
                    [self.lock unlock];
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
        for (id key in dictionary) {
            id obj=[dictionary objectForKey:key];
            if(self.enabledNonBlockingExecution){
                dispatch_async(self.exQ, ^{
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
                dispatch_async(self.exQ, ^{
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

@end
