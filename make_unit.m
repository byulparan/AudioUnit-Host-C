#import <AudioUnit/AUCocoaUIView.h>
#import <AudioUnit/AudioUnit.h>
#import <AudioToolbox/AudioToolbox.h>
#import <Cocoa/Cocoa.h>

AudioUnit make_unit(int type, int subtype, int manufacturer);
void display_unit(AudioUnit unit);

int main(int argc, char* argv[]) {

  NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
  NSApp = [NSApplication sharedApplication];

  [NSApp setActivationPolicy: NSApplicationActivationPolicyRegular];
  [[NSProcessInfo processInfo] setProcessName: @"GUILE"];

  NSMenu* menubar = [[NSMenu alloc] initWithTitle: @"MainMenu"];
  NSMenuItem* appMenuItem = [[NSMenuItem new] autorelease];
  [NSApp setMainMenu: menubar];
  [menubar addItem: appMenuItem];
   
  NSMenu* appMenu = [[NSMenu new] autorelease];
  NSMenuItem* quitMenuItem = [[NSMenuItem alloc] initWithTitle: @"Make_Unit"
							action: @selector(terminate:)
						 keyEquivalent: @"q"];

  NSMenuItem* closeMenuItem = [[NSMenuItem alloc] initWithTitle: @"close"
							 action: @selector(performClose:)
						  keyEquivalent: @"w"];

  [appMenu addItem: quitMenuItem];
  [appMenu addItem: closeMenuItem];
  [appMenuItem setSubmenu: appMenu];

  AudioUnit unit = make_unit('aumu','Ni$D', '-NI-');
  display_unit(unit);
  
  [NSApp run];
  [pool release];
  
  return 0;
}


AudioUnit make_unit(int type, int subtype, int manufacturer) {
  AudioComponentDescription audioDesc;
  
  audioDesc.componentType = type;
  audioDesc.componentSubType = subtype;
  audioDesc.componentManufacturer = manufacturer;
  audioDesc.componentFlags = 0;
  audioDesc.componentFlagsMask = 0;

  AudioComponent found = AudioComponentFindNext(NULL, &audioDesc);
  AudioComponentGetDescription(found, &audioDesc);
    
  if(!found) {
    NSLog(@"can't found");
    exit(1);
  }

  AudioUnit unit = NULL;
  AudioComponentInstanceNew(found, &unit);
  
  if(unit) {
    NSLog(@"make unit");
  } else {
    NSLog(@"can't make unit");
    exit(1);
  }
  
  AudioStreamBasicDescription format;  

  format.mFormatID = kAudioFormatLinearPCM;
  format.mFormatFlags = 41;
  format.mBytesPerPacket = 4;
  format.mBytesPerFrame = 4;
  format.mFramesPerPacket = 1;
  format.mBitsPerChannel = 32;
  format.mSampleRate = 44100.0;
  format.mChannelsPerFrame = 2;
  AudioUnitSetProperty(unit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 0, &format, sizeof(AudioStreamBasicDescription));

  AudioUnitSetProperty(unit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, 0, &format, sizeof(AudioStreamBasicDescription));

   AudioUnitInitialize(unit);
   AudioUnitReset(unit, kAudioUnitScope_Global, 0);

  return unit;
}

void display_unit(AudioUnit unit) {
  unsigned int dataSize = 0;
  unsigned char isWritable = 0;
  NSView* pluginView;
  if (AudioUnitGetPropertyInfo (unit, kAudioUnitProperty_CocoaUI, kAudioUnitScope_Global,
				0, &dataSize, &isWritable) == 0 && dataSize != 0) {
    
    AudioUnitCocoaViewInfo* info = (AudioUnitCocoaViewInfo*)malloc(dataSize);

    if (AudioUnitGetProperty (unit, kAudioUnitProperty_CocoaUI, kAudioUnitScope_Global,
			      0, info, &dataSize) == 0)
      {
	NSString* viewClassName = (NSString*) (info->mCocoaAUViewClass[0]);
	CFStringRef path = CFURLCopyPath (info->mCocoaAUViewBundleLocation);
	NSString* unescapedPath = (NSString*) CFURLCreateStringByReplacingPercentEscapes (NULL, path, CFSTR (""));
	CFRelease (path);
	NSBundle* viewBundle = [NSBundle bundleWithPath: [unescapedPath autorelease]];
	Class viewClass = [viewBundle classNamed: viewClassName];

	if ([viewClass conformsToProtocol: @protocol (AUCocoaUIBase)]
	    && [viewClass instancesRespondToSelector: @selector (interfaceVersion)]
	    && [viewClass instancesRespondToSelector: @selector (uiViewForAudioUnit: withSize:)]) {
	
	  id factory = [[[viewClass alloc] init] autorelease];
	  pluginView = [factory uiViewForAudioUnit: unit
					  withSize: NSMakeSize(100,100)];
	}
	
	for (int i = (dataSize - sizeof (CFURLRef)) / sizeof (CFStringRef); --i >= 0;)
	  CFRelease (info->mCocoaAUViewClass[i]);
	CFRelease (info->mCocoaAUViewBundleLocation);
      }
  }

  
  NSRect f = [pluginView frame];
  NSRect frame = NSMakeRect(0, 0, f.size.width, f.size.height);

  NSWindow* window  = [[NSWindow alloc] initWithContentRect:frame
						  styleMask:NSWindowStyleMaskTitled |
					NSWindowStyleMaskClosable
						    backing:NSBackingStoreBuffered
						      defer:NO];
  window.contentView = pluginView;
  [window makeKeyAndOrderFront:nil];
}
