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
//  ASFKControlBlock.m
//  Async
//
//  Created by Boris Vigman on 05/04/2019.
//  Copyright © 2019 Boris Vigman. All rights reserved.
//

#import "ASFKBase.h"

@implementation ASFKControlBlock{
    BOOL cancelRequested;
    BOOL busyFlag;
    NSLock* lock;
}
-(id)init{
    self=[super init];
    if(self){
        lock=[[NSLock alloc]init];
        [lock lock];
        cancelRequested=NO;
        busyFlag=NO;
        [lock unlock];
    }
    return self;
}
-(void)requestCancellation{
    NSLog(@"requesting cancellation");
    [lock lock];
    cancelRequested=YES;
    [lock unlock];
}
-(void)forgetCancellation{
    NSLog(@"forgetting cancellation");
    [lock lock];
    cancelRequested=NO;
    [lock unlock];
}
-(BOOL) cancellationRequested{
    [lock lock];
    BOOL cr=cancelRequested;
    [lock unlock];
    return cr;
}
-(BOOL) isBusy{
    [lock lock];
    BOOL b=busyFlag;
    [lock unlock];
    return b;
}

@end
