//
//  CLSkypeAppDelegate.h
//  CLSkype
//
//  Created by Maximilian Schirmer on 07/02/2010.
//  Copyright 2010 Maximilian Schirmer. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <CoreLocation/CoreLocation.h>
#import "Skype.h"

@interface CLSkypeAppDelegate : NSObject <NSApplicationDelegate, CLLocationManagerDelegate, NSURLHandleClient> {
	NSURLHandle *urlHandle;
	CLLocationManager *locationManager;
	SkypeApplication *skype;

	NSUserDefaults *preferences;
	
	IBOutlet NSWindow *preferencesWindow;
	
	NSString *city;
	NSString *country;
}

@property (readwrite, retain) NSString *city;
@property (readwrite, retain) NSString *country;

- (IBAction) moodMessagePatternInputFinished:(id) sender;

- (NSString *) queryWebserviceWithMessage:(NSString *)urlString;
- (NSString *) reverseGeocodeWithLatitude:(NSString *) latitude andLongitude:(NSString *) longitude;
- (void) processGoogleMapsResponse:(NSString *)query;
- (void) setSkypeCityAndCountry;

@end
