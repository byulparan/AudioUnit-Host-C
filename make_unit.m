#import <AudioUnit/AUCocoaUIView.h>
#import <AudioUnit/AudioUnit.h>
#import <AudioToolbox/AudioToolbox.h>
#import <Cocoa/Cocoa.h>
#import <signal.h>

AudioUnit make_unit(int type, int subtype, int manufacturer);
void display_unit(AudioUnit unit);


void show_signals(const sigset_t exmask)
{

    int exsignals[43];

    exsignals[0] = SIGABRT;
    exsignals[1] = SIGALRM;
    exsignals[2] = SIGBUS;
    exsignals[3] = SIGCHLD;
    exsignals[4] = SIGCONT;
#ifdef SIGEMT
    exsignals[5] = SIGEMT;
#else
    exsignals[5] = -1;
#endif

    exsignals[6] = SIGFPE;

#ifdef SIGFREEZE
    exsignals[7] = SIGFREEZE;
#else
    exsignals[7] = -1;
#endif

    exsignals[8] = SIGHUP;
    exsignals[9] = SIGILL;
#ifdef SIGINFO
    exsignals[10] = SIGINFO;
#else
    exsignals[10] = -1;
#endif

    exsignals[11] = SIGINT;
    exsignals[12] = SIGIO;
    exsignals[13] = SIGIOT;

#ifdef SIGJVM1
    exsignals[14] = SIGJVM1;
#else
    exsignals[14] = -1;
#endif
#ifdef SIGJVM2
    exsignals[15] = SIGJVM2;
#else
    exsignals[15] = -1;
#endif

    exsignals[16] = SIGKILL;
#ifdef SIGLOST
    exsignals[17] = SIGLOST;
#else
    exsignals[17] = -1;
#endif

#ifdef SIGLWP
    exsignals[18] = SIGLWP;
#else
    exsignals[18] = -1;
#endif

    exsignals[19] = SIGPIPE;
    exsignals[20] = -1;
    exsignals[21] = SIGPROF;
    exsignals[22] = -1;
    exsignals[23] = SIGQUIT;
    exsignals[24] = SIGSEGV;
    exsignals[25] = -1;
    exsignals[26] = SIGSTOP;
    exsignals[27] = SIGSYS;
    exsignals[28] = SIGTERM;
#ifdef SIGTHAW
    exsignals[29] = SIGTHAW;
#else
    exsignals[29] = -1;
#endif
#ifdef SIGTHR
    exsignals[30] = SIGTHR;
#else
    exsignals[30] = -1;
#endif
    exsignals[31] = SIGTRAP;
    exsignals[32] = SIGTSTP;
    exsignals[33] = SIGTTIN;
    exsignals[34] = SIGTTOU;
    exsignals[35] = SIGURG;
    exsignals[36] = SIGUSR1;
    exsignals[37] = SIGUSR2;
    exsignals[38] = SIGVTALRM;
#ifdef SIGWAITING
    exsignals[39] = SIGWAITING;
#else
    exsignals[39] = -1;
#endif

    exsignals[40] = SIGWINCH;
    exsignals[41] = SIGXCPU;
    exsignals[42] = SIGXFSZ;
// #ifdef SIGXRES
//     exsignals[43] = SIGXRES;
// #else
//     exsignals[43] = -1;
// #endif

    int exsignals_n = 0;

    for (;exsignals_n < 43; exsignals_n++) {
        if (exsignals[exsignals_n] == -1) continue;
        static char *exsignal_name;
        exsignal_name = strsignal(exsignals[exsignals_n]);
        switch(sigismember(&exmask, exsignals[exsignals_n]))
        {
        case 0: break;
        case 1: printf("YES %d\n", exsignals_n); break;
        case -1: printf("could not obtain signal\n"); break;
        default: printf("UNEXPECTED for %s return\n", exsignal_name); break;
        }
    }
}
const sigset_t getmask(void)
{
        static sigset_t retmask;
        if ((sigprocmask(SIG_SETMASK, NULL, &retmask)) == -1)
                printf("could not obtain process signal mask\n");

        return retmask;
}

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

  sigset_t masked = getmask();
  AudioUnit unit = make_unit('aumu','PRO3', 'Artu');
  display_unit(unit);
  
  sigprocmask(SIG_SETMASK, &masked, 0);
  struct sigaction action;
  action.sa_handler = SIG_DFL;
  sigemptyset(&action.sa_mask);
  action.sa_flags = 0;
  sigaction(SIGINT, &action, 0);
  show_signals(getmask());
  
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
  NSRect frame = NSMakeRect(0, 400, f.size.width, f.size.height);

  NSWindow* window  = [[NSWindow alloc] initWithContentRect:frame
						  styleMask:NSWindowStyleMaskTitled |
					NSWindowStyleMaskClosable
						    backing:NSBackingStoreBuffered
						      defer:NO];
  window.contentView = pluginView;
  [window makeKeyAndOrderFront:nil];
}
