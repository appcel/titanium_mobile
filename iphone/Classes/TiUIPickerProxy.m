/**
 * Appcelerator Titanium Mobile
 * Copyright (c) 2009-2010 by Appcelerator, Inc. All Rights Reserved.
 * Licensed under the terms of the Apache Public License
 * Please see the LICENSE included with this distribution for details.
 */

#import "TiUIPickerProxy.h"
#import "TiUIPickerColumnProxy.h"
#import "TiUIPickerRowProxy.h"
#import "TiUIPicker.h"
#import "TiUtils.h"

@implementation TiUIPickerProxy

-(void)_configure
{
	[self replaceValue:NUMINT(-1) forKey:@"type" notification:NO];
	[self replaceValue:nil forKey:@"value" notification:NO];
	[super _configure];
}

-(BOOL)supportsNavBarPositioning
{
	return NO;
}

-(NSMutableArray*)columns
{
	NSMutableArray* columns = [self valueForUndefinedKey:@"columns"];
	if (columns==nil)
	{
		columns = [NSMutableArray array];
		[self replaceValue:columns forKey:@"columns" notification:NO];
	}
	return columns;
}

-(TiUIPicker*)picker
{
	return (TiUIPicker*)[self view];
}

-(TiUIPickerColumnProxy*)columnAt:(NSInteger)index
{
	NSMutableArray *columns = [self columns];
	if (index < [columns count])
	{
		return [columns objectAtIndex:index];
	}
	TiUIPickerColumnProxy *column = [[TiUIPickerColumnProxy alloc] _initWithPageContext:[self executionContext]];
	column.column = index;
	[columns addObject:column];
	[column release];
	return column;
}

#pragma mark Public APIs 

-(void)add:(id)args
{
	id data = [args objectAtIndex:0];
	
	TiUIPicker *picker = [self picker];
	
	if ([data isKindOfClass:[TiUIPickerRowProxy class]])
	{
		TiUIPickerRowProxy *row = (TiUIPickerRowProxy*)data;
		TiUIPickerColumnProxy *column = [self columnAt:0];
		NSInteger rowIndex = [column addRow:row];
		if ([self viewAttached])
		{
			[picker performSelectorOnMainThread:@selector(reloadColumn:) withObject:column waitUntilDone:NO];
		}
		if ([TiUtils boolValue:[row valueForUndefinedKey:@"selected"] def:NO])
		{
			[picker performSelectorOnMainThread:@selector(selectRow:) withObject:[NSArray arrayWithObjects:NUMINT(0),NUMINT(rowIndex),nil] waitUntilDone:NO];
		}
	}
	else if ([data isKindOfClass:[TiUIPickerColumnProxy class]])
	{
		NSMutableArray *columns = [self columns];
		[columns addObject:data];
		if ([self viewAttached])
		{
			[picker performSelectorOnMainThread:@selector(reloadColumn:) withObject:data waitUntilDone:NO];
		}
	}
	else if ([data isKindOfClass:[NSArray class]])
	{
		// peek to see what our first row is ... 
		id firstRow = [data objectAtIndex:0];
		
		// if an array of columns, just add them
		if ([firstRow isKindOfClass:[TiUIPickerColumnProxy class]])
		{
			NSMutableArray *columns = [self columns];
			for (id column in data)
			{
				[columns addObject:column];
			}
		}
		else if ([firstRow isKindOfClass:[NSDictionary class]])
		{
			for (id rowdata in data)
			{
				TiUIPickerRowProxy *row = [[TiUIPickerRowProxy alloc] _initWithPageContext:[self executionContext] args:[NSArray arrayWithObject:rowdata]];
				TiUIPickerColumnProxy *column = [self columnAt:0];
				NSInteger rowIndex = [column addRow:row];
				[row release];
				if ([TiUtils boolValue:[row valueForUndefinedKey:@"selected"] def:NO])
				{
					[[self view] performSelectorOnMainThread:@selector(selectRow:) withObject:[NSArray arrayWithObjects:NUMINT(0),NUMINT(rowIndex),nil] waitUntilDone:NO];
				}
			}
		}
		else
		{
			TiUIPickerColumnProxy *column = [self columnAt:0];
			for (id item in data)
			{
				ENSURE_TYPE(item,TiUIPickerRowProxy);
				[column addRow:item];
			}
			if ([self viewAttached])
			{
				[picker performSelectorOnMainThread:@selector(reloadColumn:) withObject:column waitUntilDone:NO];
			}
		}
	}
}

-(void)remove:(id)args
{
	//TODO
}

-(id)getSelectedRow:(id)args
{
	ENSURE_SINGLE_ARG(args,NSObject);
	if ([self viewAttached])
	{
		return [(TiUIPicker*)[self view] selectedRowForColumn:[TiUtils intValue:args]];
	}
	return nil;
}

-(void)setSelectedRow:(id)args
{
	ENSURE_UI_THREAD(setSelectedRow,args);
	
	if ([self viewAttached])
	{
		NSInteger column = [TiUtils intValue:[args objectAtIndex:0]];
		NSInteger row = [TiUtils intValue:[args objectAtIndex:1]];
		BOOL animated = [args count]>2 ? [TiUtils boolValue:[args objectAtIndex:2]] : YES;
		[(TiUIPicker*)[self view] selectRowForColumn:column row:row animated:animated];
	}
}

-(UIViewAutoresizing)verifyAutoresizing:(UIViewAutoresizing)suggestedResizing
{
	return suggestedResizing & ~(UIViewAutoresizingFlexibleHeight);
}

USE_VIEW_FOR_VERIFY_HEIGHT


@end