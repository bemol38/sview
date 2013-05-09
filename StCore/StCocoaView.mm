/**
 * Copyright © 2011-2013 Kirill Gavrilov <kirill@sview.ru>
 *
 * StCore library is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * StCore library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 * See the GNU General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library.
 * If not, see <http://www.gnu.org/licenses/>.
 */

#if (defined(__APPLE__))

#include "StCocoaView.h"
#include "StWindowImpl.h"
#include "stvkeyscarbon.h"

#include <StStrings/StLogger.h>
#include <StTemplates/StRect.h>

@implementation StCocoaView

    - (id ) initWithStWin: (StWindowImpl* ) theStWin
                    nsWin: (NSWindow* )     theNsWin {
        NSRect aBounds = [[theNsWin contentView] bounds];
        self = [super initWithFrame: aBounds
                        pixelFormat: [[NSOpenGLView class] defaultPixelFormat]];
        if(self == NULL) {
            return NULL;
        }
        myStWin = theStWin;

        // setup fullscreen options
        NSString* aKeys[] = {
            NSFullScreenModeSetting,
            NSFullScreenModeWindowLevel // we override window level here, needed for slave window
        };
        NSNumber* aValues[] = {
            [NSNumber numberWithBool:    YES],
            [NSNumber numberWithInteger: kCGMaximumWindowLevel]
        };
        myFullScrOpts = [[NSDictionary alloc] initWithObjects: aValues
                                                      forKeys: aKeys
                                                        count: 2];

        // register Drag & Drop supports
        NSArray* aDndTypes = [NSArray arrayWithObjects: NSFilenamesPboardType, NULL];
        [self registerForDraggedTypes: aDndTypes];

        // replace content view in the window
        [theNsWin setContentView: self];

        // make view as first responder in winow to capture all useful events
        [theNsWin makeFirstResponder: self];
        return self;
    }

    - (void ) dealloc {
        [myFullScrOpts release];
        [super dealloc];
    }

    /*- (void ) reshape {
        // wait until view is redrawn in another thread
        ///myStWin->TheEvent.reset();
        ///myStWin->TheEvent.wait(1000);
        [super reshape];
        myStWin->myMessageList.append(StMessageList::MSG_RESIZE);
    }*/

    /**
     * Left mouse button - down.
     */
    - (void ) mouseDown: (NSEvent* ) theEvent {
        const StPointD_t aPnt    = myStWin->getMousePos();
        myStEvent.Type           = stEvent_MouseDown;
        myStEvent.Button.Time    = [theEvent timestamp];
        myStEvent.Button.Button  = ST_MOUSE_LEFT;
        myStEvent.Button.Buttons = 0;
        myStEvent.Button.PointX  = aPnt.x();
        myStEvent.Button.PointY  = aPnt.y();
        if(myStWin->myEventsThreaded) {
            myStWin->myEventsBuffer.append(myStEvent);
        } else {
            myStWin->signals.onMouseDown->emit(myStEvent.Button);
        }
    }

    /**
     * Left mouse button - up.
     */
    - (void ) mouseUp: (NSEvent* ) theEvent {
        const StPointD_t aPnt    = myStWin->getMousePos();
        myStEvent.Type           = stEvent_MouseUp;
        myStEvent.Button.Time    = [theEvent timestamp];
        myStEvent.Button.Button  = ST_MOUSE_LEFT;
        myStEvent.Button.Buttons = 0;
        myStEvent.Button.PointX  = aPnt.x();
        myStEvent.Button.PointY  = aPnt.y();
        if(myStWin->myEventsThreaded) {
            myStWin->myEventsBuffer.append(myStEvent);
        } else {
            myStWin->signals.onMouseUp->emit(myStEvent.Button);
        }
    }

    /**
     * Right mouse button - down.
     */
    - (void ) rightMouseDown: (NSEvent* ) theEvent {
        const StPointD_t aPnt    = myStWin->getMousePos();
        myStEvent.Type           = stEvent_MouseDown;
        myStEvent.Button.Time    = [theEvent timestamp];
        myStEvent.Button.Button  = ST_MOUSE_RIGHT;
        myStEvent.Button.Buttons = 0;
        myStEvent.Button.PointX  = aPnt.x();
        myStEvent.Button.PointY  = aPnt.y();
        if(myStWin->myEventsThreaded) {
            myStWin->myEventsBuffer.append(myStEvent);
        } else {
            myStWin->signals.onMouseDown->emit(myStEvent.Button);
        }
    }

    /**
     * Right mouse button - up.
     */
    - (void ) rightMouseUp: (NSEvent* ) theEvent {
        const StPointD_t aPnt    = myStWin->getMousePos();
        myStEvent.Type           = stEvent_MouseUp;
        myStEvent.Button.Time    = [theEvent timestamp];
        myStEvent.Button.Button  = ST_MOUSE_RIGHT;
        myStEvent.Button.Buttons = 0;
        myStEvent.Button.PointX  = aPnt.x();
        myStEvent.Button.PointY  = aPnt.y();
        if(myStWin->myEventsThreaded) {
            myStWin->myEventsBuffer.append(myStEvent);
        } else {
            myStWin->signals.onMouseUp->emit(myStEvent.Button);
        }
    }

    /**
     * Another (nor left nor right) mouse button - down.
     */
    - (void ) otherMouseDown: (NSEvent* ) theEvent {
        StVirtButton aBtnId = ST_NOMOUSE;
        if([theEvent buttonNumber] == 2) {
            aBtnId = ST_MOUSE_MIDDLE;
        }
        if(aBtnId != ST_NOMOUSE) {
            const StPointD_t aPnt    = myStWin->getMousePos();
            myStEvent.Type           = stEvent_MouseDown;
            myStEvent.Button.Time    = [theEvent timestamp];
            myStEvent.Button.Button  = aBtnId;
            myStEvent.Button.Buttons = 0;
            myStEvent.Button.PointX  = aPnt.x();
            myStEvent.Button.PointY  = aPnt.y();
            if(myStWin->myEventsThreaded) {
                myStWin->myEventsBuffer.append(myStEvent);
            } else {
                myStWin->signals.onMouseDown->emit(myStEvent.Button);
            }
        }
    }

    /**
     * Another (nor left nor right) mouse button - up.
     */
    - (void ) otherMouseUp: (NSEvent* ) theEvent {
        StVirtButton aBtnId = ST_NOMOUSE;
        if([theEvent buttonNumber] == 2) {
            aBtnId = ST_MOUSE_MIDDLE;
        }
        if(aBtnId != ST_NOMOUSE) {
            const StPointD_t aPnt    = myStWin->getMousePos();
            myStEvent.Type           = stEvent_MouseUp;
            myStEvent.Button.Time    = [theEvent timestamp];
            myStEvent.Button.Button  = aBtnId;
            myStEvent.Button.Buttons = 0;
            myStEvent.Button.PointX  = aPnt.x();
            myStEvent.Button.PointY  = aPnt.y();
            if(myStWin->myEventsThreaded) {
                myStWin->myEventsBuffer.append(myStEvent);
            } else {
                myStWin->signals.onMouseUp->emit(myStEvent.Button);
            }
        }
    }

    /**
     * Mouse scroll.
     */
    - (void ) scrollWheel: (NSEvent* ) theEvent {
        const CGFloat    aDeltaY = [theEvent deltaY];
        const CGFloat    aDeltaX = [theEvent deltaX];
        const StPointD_t aPnt    = myStWin->getMousePos();
        StVirtButton aBtnId = ST_NOMOUSE;
        if(stAreEqual(aDeltaX, 0.0, 0.01)) {
            if(stAreEqual(aDeltaY, 0.0, 0.01)) {
                // a lot of values near zero can be generated by touchpad
                return;
            }
            aBtnId = (aDeltaY > 0.0) ? ST_MOUSE_SCROLL_V_UP : ST_MOUSE_SCROLL_V_DOWN;
        } else {
            aBtnId = (aDeltaX > 0.0) ? ST_MOUSE_SCROLL_LEFT : ST_MOUSE_SCROLL_RIGHT;
        }

        //if([theEvent subtype] == NSMouseEventSubtype) {
        myStEvent.Type           = stEvent_MouseDown;
        myStEvent.Button.Time    = [theEvent timestamp];
        myStEvent.Button.Button  = aBtnId;
        myStEvent.Button.Buttons = 0;
        myStEvent.Button.PointX  = aPnt.x();
        myStEvent.Button.PointY  = aPnt.y();
        if(myStWin->myEventsThreaded) {
            myStWin->myEventsBuffer.append(myStEvent);
            myStEvent.Type = stEvent_MouseUp;
            myStWin->myEventsBuffer.append(myStEvent);
        } else {
            myStWin->signals.onMouseDown->emit(myStEvent.Button);
            myStEvent.Type = stEvent_MouseUp;
            myStWin->signals.onMouseUp  ->emit(myStEvent.Button);
        }
        //}
    }

    /**
     * 3-fingers swipe.
     */
    - (void ) swipeWithEvent: (NSEvent* ) theEvent {
        const CGFloat aDeltaX = [theEvent deltaX];
        const CGFloat aDeltaY = [theEvent deltaY];
        if(stAreEqual(aDeltaX, 0.0, 0.001)) {
            if(!stAreEqual(aDeltaY, 0.0, 0.001)) {
                myStWin->myMessageList.append((aDeltaY > 0.0)
                                            ? StMessageList::MSG_GO_TOP
                                            : StMessageList::MSG_GO_BOTTOM);
            }
        } else {
            myStWin->myMessageList.append((aDeltaX > 0.0)
                                        ? StMessageList::MSG_GO_BACKWARD
                                        : StMessageList::MSG_GO_FORWARD);
        }
    }

    /**
     * Keyboard shortcuts event.
     */
    /**- (BOOL ) performKeyEquivalent: (NSEvent* ) theEvent {
        unsigned short aKeyCode = [theEvent keyCode];
        ST_DEBUG_LOG("performKeyEquivalent " + aKeyCode);
        if(aKeyCode >= ST_CARBON2ST_VK_SIZE) {
            ST_DEBUG_LOG("performKeyEquivalent, keycode= " + aKeyCode + " ignored!\n");
            return NO;
        }
        return NO;
    }*/

    /**
     * Modifier key pressed.
     */
    - (void ) flagsChanged: (NSEvent* ) theEvent {
        NSUInteger aFlags = [theEvent modifierFlags];
        myStWin->myMessageList.getKeysMap()[ST_VK_CONTROL] = (aFlags & NSControlKeyMask);
        myStWin->myMessageList.getKeysMap()[ST_VK_SHIFT]   = (aFlags & NSShiftKeyMask);
    }

    /**
     * Key down event.
     */
    - (void ) keyDown: (NSEvent* ) theEvent {
        unsigned short aKeyCode = [theEvent keyCode];
        if(aKeyCode >= ST_CARBON2ST_VK_SIZE) {
            ST_DEBUG_LOG("keyDown, keycode= " + aKeyCode + " ignored!\n");
            return;
        }

        NSUInteger aFlags = [theEvent modifierFlags];
        if(aFlags & NSCommandKeyMask) {
            return; // ignore Command + key combinations - key up event doesn't called!
        }

        StUtf8Iter aUIter([[theEvent characters] UTF8String]);
        myStEvent.Key.Char = *aUIter;
        myStEvent.Key.VKey = (StVirtKey )ST_CARBON2ST_VK[aKeyCode];
        myStWin->myMessageList.getKeysMap()[myStEvent.Key.VKey] = true;

        myStEvent.Type = stEvent_KeyDown;
        myStEvent.Key.Time  = [theEvent timestamp];
        myStEvent.Key.Flags = ST_VF_NONE;
        if(aFlags & NSShiftKeyMask) {
            myStEvent.Key.Flags = StVirtFlags(myStEvent.Key.Flags | ST_VF_SHIFT);
        }
        if(aFlags & NSControlKeyMask) {
            myStEvent.Key.Flags = StVirtFlags(myStEvent.Key.Flags | ST_VF_CONTROL);
        }

        if(myStWin->myEventsThreaded) {
            myStWin->myEventsBuffer.append(myStEvent);
        } else {
            myStWin->signals.onKeyDown->emit(myStEvent.Key);
        }
    }

    /**
     * Key up event.
     */
    - (void ) keyUp: (NSEvent* ) theEvent {
        unsigned short aKeyCode = [theEvent keyCode];
        if(aKeyCode >= ST_CARBON2ST_VK_SIZE) {
            ST_DEBUG_LOG("keyUp,   keycode= " + aKeyCode + " ignored!\n");
            return;
        }

        NSUInteger aFlags = [theEvent modifierFlags];
        myStEvent.Key.VKey = (StVirtKey )ST_CARBON2ST_VK[aKeyCode];
        myStWin->myMessageList.getKeysMap()[myStEvent.Key.VKey] = false;

        myStEvent.Type = stEvent_KeyUp;
        myStEvent.Key.Time  = [theEvent timestamp];
        myStEvent.Key.Flags = ST_VF_NONE;
        if(aFlags & NSShiftKeyMask) {
            myStEvent.Key.Flags = StVirtFlags(myStEvent.Key.Flags | ST_VF_SHIFT);
        }
        if(aFlags & NSControlKeyMask) {
            myStEvent.Key.Flags = StVirtFlags(myStEvent.Key.Flags | ST_VF_CONTROL);
        }

        if(myStWin->myEventsThreaded) {
            myStWin->myEventsBuffer.append(myStEvent);
        } else {
            myStWin->signals.onKeyUp->emit(myStEvent.Key);
        }
    }

    - (void ) goToFullscreen {
        if(![self isInFullScreenMode]) {
            [self enterFullScreenMode: [[self window] screen] withOptions: myFullScrOpts];
        }
    }

    - (void ) goToWindowed {
        if([self isInFullScreenMode]) {
            [self exitFullScreenModeWithOptions: myFullScrOpts];
            [[self window] makeFirstResponder: self];
        }
    }

    - (NSDragOperation ) draggingEntered: (id <NSDraggingInfo> ) theSender {
        if((NSDragOperationGeneric & [theSender draggingSourceOperationMask]) == NSDragOperationGeneric) {
            return NSDragOperationGeneric;
        }
        // not a drag we can use
        return NSDragOperationNone;
    }

    - (void ) draggingExited: (id <NSDraggingInfo> ) theSender {
        //
    }

    - (BOOL ) prepareForDragOperation: (id <NSDraggingInfo> ) theSender {
        return YES;
    }

    - (BOOL ) performDragOperation: (id <NSDraggingInfo> ) theSender {
        NSPasteboard* aPasteBoard = [theSender draggingPasteboard];
        if([[aPasteBoard types] containsObject: NSFilenamesPboardType]) {
            NSArray* aFiles = [aPasteBoard propertyListForType: NSFilenamesPboardType];
            int aFilesCount = [aFiles count];
            if(aFilesCount < 1) {
                return NO;
            }

            for(NSUInteger aFileId = 0; aFileId < [aFiles count]; ++aFileId) {
                NSString* aFilePathNs = (NSString* )[aFiles objectAtIndex: aFileId];
                if(aFilePathNs == NULL
                || [aFilePathNs isKindOfClass: [NSString class]] == NO) {
                    continue;
                }

                // automatically convert filenames from decomposed form used by Mac OS X file systems
                const StString aFile = [[aFilePathNs precomposedStringWithCanonicalMapping] UTF8String];
                myStEvent.Type = stEvent_FileDrop;
                myStEvent.DNDrop.Time = myStWin->getEventTime();
                myStEvent.DNDrop.File = aFile.toCString();
                if(myStWin->myEventsThreaded) {
                    myStWin->myEventsBuffer.append(myStEvent);
                } else {
                    myStWin->signals.onFileDrop->emit(myStEvent.DNDrop);
                }
            }
        }
        return YES;
    }

@end

#endif // __APPLE__
