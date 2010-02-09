//
//  CLSkypeAppDelegate.m
//  CLSkype
//
//  Created by Maximilian Schirmer on 07/02/2010.
//  Copyright 2010 Maximilian Schirmer. All rights reserved.
//

#import "CLSkypeAppDelegate.h"
#import "NSDictionary+BSJSONAdditions.h"

@implementation CLSkypeAppDelegate

@synthesize city;
@synthesize country;

- (void)awakeFromNib {
	preferences = [NSUserDefaults standardUserDefaults];
	[preferences registerDefaults:[NSDictionary dictionaryWithObjectsAndKeys:
								   [NSNumber numberWithBool:YES], @"setSkypeProfile",
								   [NSNumber numberWithBool:NO], @"setSkypeMoodMessage",
								   @"@ <city>, <country>", @"skypeMoodMessagePattern", nil]];
	
	[preferences synchronize];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	locationManager = [[CLLocationManager alloc] init];
	locationManager.delegate = self;
	[locationManager startUpdatingLocation];
	
	skype = [SBApplication applicationWithBundleIdentifier:@"com.skype.skype"];
}

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation {
	// Ignore updates where nothing we care about changed
	if (newLocation.coordinate.longitude == oldLocation.coordinate.longitude &&
		newLocation.coordinate.latitude == oldLocation.coordinate.latitude &&
		newLocation.horizontalAccuracy == oldLocation.horizontalAccuracy)
	{
		return;
	} else {
		NSLog(@"new location found: %f | %f", newLocation.coordinate.longitude, newLocation.coordinate.latitude);
		NSString *latitude = [NSString stringWithFormat:@"%f", newLocation.coordinate.latitude];
		NSString *longitude = [NSString stringWithFormat:@"%f", newLocation.coordinate.longitude];

		NSString *response = [self reverseGeocodeWithLatitude:latitude andLongitude:longitude];
		[self processGoogleMapsResponse:response];
		[self setSkypeCityAndCountry];
		
		NSLog(@"reverse geocoded location: city: %@ | country: %@", [self city], [self country]);
	}
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
	NSLog(@"CLLocationManager failed with error: %@", error);
}

- (NSString *)reverseGeocodeWithLatitude:(NSString *) latitude andLongitude:(NSString *) longitude {
	NSString *urlString = [NSString stringWithFormat:@"http://maps.google.com/maps/geo?q=%@,%@&sensor=true&key=BQIAAAAaavHF3oAjxsNcz9e_NpRZxQdlEqBbpekY-dfRX0p1Stajqnn1RSfxqjJnSnWuxtEdJ7g5S-Ya2a3vQ", latitude, longitude];
	return [self queryWebserviceWithMessage: urlString];
}

- (NSString *)queryWebserviceWithMessage:(NSString *)urlString {
	NSString *escapedURLString = (NSString *) CFURLCreateStringByAddingPercentEscapes(NULL,
																					  (CFStringRef)urlString,
																					  (CFStringRef)@"%+#",	// Characters to leave unescaped
																					  NULL,
																					  kCFStringEncodingUTF8);
	
	NSURL *url = [NSURL URLWithString:escapedURLString];
	urlHandle = [url URLHandleUsingCache: NO];
	[urlHandle addClient: self];
	
	return [[NSString alloc] initWithData:[urlHandle loadInForeground] encoding:NSUTF8StringEncoding];
}

- (void) processGoogleMapsResponse:(NSString *)query {
	NSString *address = @"";
	NSDictionary *jsonQuery = [NSDictionary dictionaryWithJSONString:query];
	
	NSArray *placemarks = [jsonQuery objectForKey:@"Placemark"];
	for (NSDictionary* placemark in placemarks) {
		NSDictionary* addressDetails = [placemark objectForKey:@"AddressDetails"];
		NSString* accuracy = [addressDetails objectForKey:@"Accuracy"];
		
		if ([accuracy isEqualTo:[NSNumber numberWithInt:4]]) {
			address = [placemark objectForKey:@"address"];
			[self setCountry:[[[addressDetails objectForKey:@"Country"] objectForKey:@"CountryNameCode"] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]];
		}
	}
	NSArray *addressComponents = [address componentsSeparatedByString: @","];
	
	if ([addressComponents count] > 0) {
		[self setCity:[[addressComponents objectAtIndex:0] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]];
	}
}

- (void) setSkypeCityAndCountry {
	if ([self city] != nil && ![[self city] isEqualToString:@""] && [self country] != nil && ![[self country] isEqualToString:@""]) {
		if ([preferences boolForKey:@"setSkypeProfile"] == YES) {
			[skype sendCommand:[NSString stringWithFormat:@"SET PROFILE CITY %@", [self city]] scriptName:@"CLSkype"];
			[skype sendCommand:[NSString stringWithFormat:@"SET PROFILE COUNTRY %@", [self country]] scriptName:@"CLSkype"];
		}
		if ([preferences boolForKey:@"setSkypeMoodMessage"] == YES) {
			NSString *moodMessagePattern = [preferences stringForKey:@"skypeMoodMessagePattern"];
			if (moodMessagePattern != nil) {
				NSString *moodMessage = [[moodMessagePattern stringByReplacingOccurrencesOfString:@"<city>" withString:[self city]] stringByReplacingOccurrencesOfString:@"<country>" withString:[self country]];				
				[skype sendCommand:[NSString stringWithFormat:@"SET PROFILE MOOD_TEXT %@", moodMessage] scriptName:@"CLSkype"];
			}
		}
	}
}

- (IBAction) moodMessagePatternInputFinished:(id) sender {
	if ([preferences boolForKey:@"setSkypeMoodMessage"] == YES) {
		NSString *moodMessagePattern = [preferences stringForKey:@"skypeMoodMessagePattern"];
		if (moodMessagePattern != nil) {
			NSString *moodMessage = [[moodMessagePattern stringByReplacingOccurrencesOfString:@"<city>" withString:[self city]] stringByReplacingOccurrencesOfString:@"<country>" withString:[self country]];
			[skype sendCommand:[NSString stringWithFormat:@"SET PROFILE MOOD_TEXT %@", moodMessage] scriptName:@"CLSkype"];
		}
	}
}

#pragma mark NSURLHandleClient methods

- (void) URLHandleResourceDidBeginLoading:(NSURLHandle *)sender {
}

- (void) URLHandleResourceDidCancelLoading:(NSURLHandle *)sender {
}

- (void) URLHandle:(NSURLHandle *)sender resourceDidFailLoadingWithReason:(NSString *)reason {
	// TODO: This is relevant, inform user that reverse geocoding failed
}

- (void) URLHandleResourceDidFinishLoading:(NSURLHandle *)sender {
}

- (void) URLHandle:(NSURLHandle *)sender resourceDataDidBecomeAvailable:(NSData *)newBytes {
}


- (void)applicationWillTerminate:(NSNotification *)aNotification {
	[locationManager stopUpdatingLocation];
	[locationManager release];
}

@end
