/**
 * LinkOpener - Opens links in 3rd party apps.
 *
 * By Adaminsull <http://h4ck.co.uk>
 * Based on YTOpener by Ad@m <http://hbang.ws>
 * Licensed under the GPL license <http://www.gnu.org/copyleft/gpl.html>
 */

#import "JSONKit.h"

%group LOSpringBoard
%hook SpringBoard
-(void)_openURLCore:(NSURL *)url display:(id)display publicURLsOnly:(BOOL)publicOnly animating:(BOOL)animated additionalActivationFlag:(unsigned int)flags {
	if ([[url scheme] isEqualToString:@"http"] || [[url scheme] isEqualToString:@"https"]) {
		if ([[url host] isEqualToString:@"twitter.com"] && [[url pathComponents] count] == 2) {
			if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"tweetbot://"]]) {
				[[UIApplication sharedApplication] openURL:[NSURL URLWithString:[@"tweetbot:///user_profile/" stringByAppendingString:[[url pathComponents] objectAtIndex:1]]]];
				return;
			} else if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"twitter://"]]) {
				[[UIApplication sharedApplication] openURL:[NSURL URLWithString:[@"twitter://user?screen_name=" stringByAppendingString:[[url pathComponents] objectAtIndex:1]]]];
				return;
			}
		} else if ([[url host] isEqualToString:@"www.facebook.com"] && [[url pathComponents] count] == 2 && [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"fb://"]]) {
			[[UIApplication sharedApplication] openURL:[NSURL URLWithString:[@"fb://profileForLinkOpener/" stringByAppendingString:[[url pathComponents]objectAtIndex:1]]]];
			return;
		} else if (([[url host] hasPrefix:@"ebay.co"] || [[url host] hasPrefix:@"www.ebay.co"]) && [[url pathComponents] count] == 4 && [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"ebay://"]]) {
			[[UIApplication sharedApplication] openURL:[NSURL URLWithString:[@"ebay://launch?itm=" stringByAppendingString:[[url pathComponents] objectAtIndex:3]]]];
			return;
		} else if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"vnd.youtube://"]]) {
			BOOL isMobile = NO;
			if (([[url scheme] isEqualToString:@"http"] || [[url scheme] isEqualToString:@"https"]) && ([[url host] isEqualToString:@"youtube.com"] || [[url host] isEqualToString:@"www.youtube.com"] || (isMobile = [[url host] isEqualToString:@"m.youtube.com"])) && isMobile ? [[url fragment] rangeOfString:@"/watch"].length > 0 : [[url path] isEqualToString:@"/watch"]) {
				NSArray *params = [(isMobile ? [[url fragment] stringByReplacingOccurrencesOfString:@"/watch?" withString:@""] : [url query]) componentsSeparatedByString:@"&"];
				for (NSString *i in params) {
					if ([i rangeOfString:@"v="].location == 0) {
						[[UIApplication sharedApplication] openURL:[NSURL URLWithString:[@"vnd.youtube://" stringByAppendingString:[i stringByReplacingOccurrencesOfString:@"v=" withString:@""]]]];
						return;
					}
				}
			} else if ([[url host] isEqualToString:@"youtu.be"] && [[url pathComponents] count] > 1) {
				[[UIApplication sharedApplication] openURL:[NSURL URLWithString:[@"vnd.youtube://" stringByAppendingString:[[url pathComponents] objectAtIndex:1]]]];
				return;
			} else if ([[url scheme] isEqualToString:@"youtube"]) {
				[[UIApplication sharedApplication] openURL:[NSURL URLWithString:[@"vnd." stringByAppendingString:[url absoluteString]]]];
				return;
			}
		}

	}
	%orig;
}
%end
%end

%group LOFacebook
%hook AppDelegate
-(BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApp annotation:(id)annotation {
	if ([[url host] isEqualToString:@"profileForLinkOpener"] && [[url pathComponents] count] == 2) {
		// This is a terrible way to do this, however Facebook crashes if we do this asynchronously. Don't ever do this elsewhere.
		NSData *output = [NSURLConnection sendSynchronousRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:[@"https://graph.facebook.com/" stringByAppendingString:[[url pathComponents] objectAtIndex:1]]] cachePolicy:NSURLRequestReloadRevalidatingCacheData timeoutInterval:60] returningResponse:nil error:nil];
		if (output == nil) {
			UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Oops, something went wrong." message:nil delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
			[alert show];
			[alert release];
		} else {
			NSDictionary *json = [output objectFromJSONData];
			return %orig(application, [NSURL URLWithString:[@"fb://profile/" stringByAppendingString:[json objectForKey:@"id"]]], sourceApp, annotation);
		}
		return NO;
	} else {
		return %orig;
	}
}
%end
%end

%ctor {
	%init;
	if ([[[NSBundle mainBundle] bundleIdentifier] isEqualToString:@"com.apple.springboard"]) {
		%init(LOSpringBoard);
	} else {
		%init(LOFacebook);
	}
}