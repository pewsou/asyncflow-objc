//
//  Filter.h
//
//  Created by Boris Vigman on 31/03/2019.
//  Copyright © 2019 Boris Vigman. All rights reserved.
//

#import "AsyncComposable.h"
typedef void* ( ^ASFKFilteringBlock)(void* data);
@interface ASFKFilter : AsyncComposable
#pragma mark - Configuration
-(BOOL) addFilteringBlock:(ASFKFilteringBlock)block;
#pragma mark - Evaluation
@end
