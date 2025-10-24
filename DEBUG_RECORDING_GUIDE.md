# 🔍 DEBUG: Recording Issues - Comprehensive Testing Guide

## 🎯 What We've Added

### Enhanced Logging with 📹 Emoji Markers
Every camera-related action now logs with detailed information:

```
📹 CameraView: Creating view controller
📹 CameraView: Requesting permissions...
📹 CameraView: Permissions granted, configuring camera...
📹 Configuring camera...
📹 ✓ Video input added (camera: front)
📹 ✓ Audio input added
📹 ✓ Video output added
📹 ✓ Preview layer connected to session
📹 ✓ Camera configuration complete
📹 Camera session started running
📹 Camera should now be visible
```

### Visual Debug Panel
When upload button doesn't appear, you'll see a yellow-bordered debug panel showing:
- `isRecording` state
- `lastRecordedURL` state (NIL or EXISTS)
- Filename if available
- Conditions for button to appear

### File Verification
When recording finishes, logs now show:
- File path
- File exists check
- File size in bytes
- Callback invocation

## 📱 How to Test

### Step 1: Open Record Screen
1. Launch app
2. Navigate to Record screen
3. **Watch Xcode Console** for these logs (in order):

```
📹 CameraView: Creating view controller
📹 CameraView: Creating coordinator
📹 CameraViewController: viewDidLoad
📹 Preview layer added to view hierarchy
📹 View bounds: (0.0, 0.0, 390.0, 844.0)  [your device dimensions]
📹 Preview layer frame: (0.0, 0.0, 390.0, 844.0)
📹 CameraView: Requesting permissions...
```

**Expected Result**: Camera preview should be visible (not black)

### Step 2: Check Permissions
Look for one of these:
```
✅ Good:
📹 CameraView: Permissions granted, configuring camera...
📹 Configuring camera...

❌ Bad:
📹 CameraView: Permissions denied
```

If permissions denied:
1. Go to Settings → MirrorMate
2. Enable Camera & Microphone
3. Restart app

### Step 3: Check Camera Configuration
After permissions granted, look for:
```
📹 Configuring camera...
📹 ✓ Video input added (camera: front)
📹 ✓ Audio input added
📹 ✓ Video output added
📹 ✓ Preview layer connected to session
📹 ✓ Camera configuration complete
📹 CameraViewController: viewDidAppear
📹 View is visible: true, Alpha: 1.0
📹 Preview layer session: connected
📹 Camera should now be visible
```

**Expected Result**: By this point, camera preview MUST be visible

### Step 4: Start Recording
1. Tap the red record button
2. **Watch for**:

```
📹 CameraView: updateUIViewController called, isRecording=true
📹 CameraView: Starting recording to: <UUID>.mov
📹 CameraView: Recording command sent
📹 ✓ Recording STARTED to: <UUID>.mov
📹 File path: /private/var/.../<UUID>.mov
```

**Expected Result**: 
- Timer starts counting (00:01, 00:02, etc.)
- Red dot pulses
- Status text: "Tap to stop"

### Step 5: Stop Recording
1. Tap the stop button (square icon)
2. **Watch for**:

```
📹 CameraView: updateUIViewController called, isRecording=false
📹 CameraView: Stopping recording...
📹 CameraView: Stop recording command sent
📹 ✓ Recording FINISHED
📹 Output URL: /private/var/.../<UUID>.mov
📹 Error: none
📹 File exists: true
📹 File size: 1234567 bytes  [should be > 0]
📹 Calling onRecordingFinished callback...
📹 CameraView: Recording finished callback triggered
📹 URL: /private/var/.../<UUID>.mov, Error: nil
Recording finished callback. url=Optional(/private/var/.../..mov) err=nil
✓ Recording saved to: /private/var/.../<UUID>.mov
✓ File exists: true
✓ lastRecordedURL set, upload button should appear
```

**Expected Result**: 
- Timer stops
- Large blue "Upload & Analyze" button appears

### Step 6: If Button Doesn't Appear
Look at the **DEBUG INFO panel** on screen (yellow border):

```
🔍 DEBUG INFO
isRecording: false
lastRecordedURL: ✅ EXISTS  [GOOD]
or
lastRecordedURL: ❌ NIL     [BAD - THIS IS THE PROBLEM]
File: <UUID>.mov
```

Check console for what happened:
```
❌ If you DON'T see:
"✓ lastRecordedURL set, upload button should appear"

Then the callback didn't fire or failed!
```

## 🐛 Common Issues & Solutions

### Issue 1: Black Camera Screen

#### Symptom
Camera preview is all black

#### Check Console For
```
❌ Bad signs:
📹 CameraView: Permissions denied
❌ ERROR [Capture] No camera device found
❌ ERROR [Capture] Cannot add video input to session
📹 Preview layer session: NOT connected
```

#### Solutions
1. **Permissions**: Go to Settings → MirrorMate → Enable Camera & Microphone
2. **Camera in use**: Close all apps using camera (Camera app, FaceTime, etc.)
3. **Restart device**: Sometimes iOS needs a restart
4. **Check console**: Look for the exact error message

### Issue 2: Upload Button Never Appears

#### Symptom
After stopping recording, button doesn't show

#### Check Console For
```
Step 1: Did recording actually start?
Look for: "📹 ✓ Recording STARTED"
If NOT found → Recording never started!

Step 2: Did recording finish?
Look for: "📹 ✓ Recording FINISHED"
If NOT found → Recording didn't stop properly!

Step 3: Was file created?
Look for: "📹 File exists: true"
If false → No file was saved!

Step 4: Did callback fire?
Look for: "📹 CameraView: Recording finished callback triggered"
If NOT found → Callback wasn't called!

Step 5: Was state updated?
Look for: "✓ lastRecordedURL set, upload button should appear"
If NOT found → State update failed!
```

#### Solutions Based on Missing Step

**Missing Step 1** (Recording didn't start):
- Check: `📹 Camera session started running` appears
- Check: No error messages in console
- Try: Close and reopen record screen

**Missing Step 2** (Recording didn't finish):
- Wait a moment after tapping stop
- Check: `videoOutput.isRecording` in logs
- Try: Record for longer (5+ seconds)

**Missing Step 3** (File not created):
- Check: Disk space available
- Check: Error message in logs
- Try: Different file location

**Missing Step 4** (Callback not called):
- This is a critical bug
- Check: `onRecordingFinished` is set
- Look for: "📹 Callback invoked"

**Missing Step 5** (State not updated):
- Check: DispatchQueue.main.async wrapped the update
- Look for threading issues
- This indicates main thread problem

### Issue 3: Button Appears But Wrong State

#### Check Debug Panel
```
isRecording: false  ← Should be false
lastRecordedURL: ✅ EXISTS  ← Should be EXISTS

If BOTH are correct but button still doesn't show:
→ This is a SwiftUI rendering issue
```

#### Solution
1. Check if `VStack` spacing is pushing button off-screen
2. Scroll down on the screen
3. Check if button is behind another view

## 📊 Expected Console Output (Full Flow)

### Perfect Recording Flow:
```
[Opening Record Screen]
📹 CameraView: Creating view controller
📹 CameraView: Creating coordinator
📹 CameraViewController: viewDidLoad
📹 Preview layer added to view hierarchy
📹 View bounds: (0.0, 0.0, 390.0, 844.0)
📹 CameraView: Requesting permissions...
📹 CameraView: Permissions granted, configuring camera...
📹 Configuring camera...
📹 ✓ Video input added (camera: front)
📹 ✓ Audio input added
📹 ✓ Video output added
📹 ✓ Preview layer connected to session
📹 ✓ Camera configuration complete
📹 CameraViewController: viewDidAppear
📹 View is visible: true, Alpha: 1.0
📹 Preview layer session: connected
📹 Camera should now be visible

[Tapping Record]
📹 CameraView: updateUIViewController called, isRecording=true
📹 CameraView: Starting recording to: ABC123.mov
📹 CameraView: Recording command sent
📹 ✓ Recording STARTED to: ABC123.mov
📹 File path: /private/var/mobile/Containers/Data/Application/.../tmp/ABC123.mov

[Recording for 5 seconds...]

[Tapping Stop]
📹 CameraView: updateUIViewController called, isRecording=false
📹 CameraView: Stopping recording...
📹 CameraView: Stop recording command sent
📹 ✓ Recording FINISHED
📹 Output URL: /private/var/mobile/Containers/Data/Application/.../tmp/ABC123.mov
📹 Error: none
📹 File exists: true
📹 File size: 1852416 bytes
📹 Calling onRecordingFinished callback...
📹 Callback invoked
📹 CameraView: Recording finished callback triggered
📹 URL: /private/var/.../ABC123.mov, Error: nil
Recording finished callback. url=Optional(.../ABC123.mov) err=nil
✓ Recording saved to: /private/var/.../ABC123.mov
✓ File exists: true
✓ lastRecordedURL set, upload button should appear

[Button Appears]
✓✓✓ Upload button appeared on screen!
```

## 🎬 What You Should See (Visual Guide)

### When Opening Record Screen:
```
┌─────────────────────────┐
│     [X]        [👤]     │  ← Top controls
│                         │
│   📱 Camera Preview     │  ← Should show your face
│   (You should see       │     NOT black!
│    your face here!)     │
│                         │
│                         │
│      🎯 Eye Guide       │  ← Gaze overlay
│                         │
│   ┌─────────────────┐   │
│   │       ⚫️        │   │  ← Red record button
│   │  Tap to record  │   │
│   └─────────────────┘   │
└─────────────────────────┘
```

### While Recording:
```
┌─────────────────────────┐
│  [X]   🔴 00:05         │  ← Timer counting
│                         │
│   📱 Camera Preview     │
│   (Recording...)        │
│                         │
│      🎯 Eye Guide       │  ← More visible
│                         │
│   ┌─────────────────┐   │
│   │       ⬛️        │   │  ← Stop button (square)
│   │   Tap to stop   │   │
│   └─────────────────┘   │
└─────────────────────────┘
```

### After Stopping (SUCCESS):
```
┌─────────────────────────┐
│  [X]                    │
│                         │
│   📱 Camera Preview     │
│   (Stopped)             │
│                         │
│   ┌─────────────────┐   │
│   │  📤 Upload &    │   │  ← BIG BLUE BUTTON
│   │    Analyze      │   │     Should be obvious!
│   └─────────────────┘   │
└─────────────────────────┘
```

### After Stopping (FAILURE - Debug Mode):
```
┌─────────────────────────┐
│  [X]                    │
│                         │
│   📱 Camera Preview     │
│   (Stopped)             │
│                         │
│  ┌─────────────────────┐│
│  │  🔍 DEBUG INFO      ││  ← Yellow border
│  │  isRecording: false ││
│  │  lastRecordedURL:   ││
│  │  ❌ NIL             ││  ← THE PROBLEM!
│  │  Button should      ││
│  │  appear when:       ││
│  │  lastRecordedURL    ││
│  │  != nil AND         ││
│  │  !isRecording       ││
│  └─────────────────────┘│
└─────────────────────────┘
```

## 🚨 Critical Checkpoints

### Checkpoint 1: Camera Visible
**After opening record screen, within 2 seconds:**
- [ ] Camera preview shows your face (not black)
- [ ] Console shows: "📹 Camera should now be visible"
- [ ] Console shows: "📹 Preview layer session: connected"

### Checkpoint 2: Recording Starts
**After tapping record button:**
- [ ] Timer appears and counts (00:01, 00:02...)
- [ ] Red dot pulses
- [ ] Console shows: "📹 ✓ Recording STARTED"

### Checkpoint 3: Recording Stops
**After tapping stop button:**
- [ ] Timer stops
- [ ] Console shows: "📹 ✓ Recording FINISHED"
- [ ] Console shows: "📹 File exists: true"
- [ ] Console shows: "📹 File size: [number] bytes" (>0)

### Checkpoint 4: Callback Fires
**Immediately after recording stops:**
- [ ] Console shows: "📹 CameraView: Recording finished callback triggered"
- [ ] Console shows: "Recording finished callback. url=Optional(...)"
- [ ] Console shows: "✓ Recording saved to: ..."

### Checkpoint 5: State Updates
**Within 100ms of callback:**
- [ ] Console shows: "✓ lastRecordedURL set, upload button should appear"
- [ ] Upload button appears on screen
- [ ] Console shows: "✓✓✓ Upload button appeared on screen!"

## 📝 What to Send Me if Still Broken

Copy and paste from Xcode console:
1. Everything with `📹` emoji (camera logs)
2. Everything with `✓` (success markers)
3. Everything with `❌` (error markers)
4. The **DEBUG INFO** panel text from the screen

Example:
```
📹 CameraView: Creating view controller
📹 Configuring camera...
[... all camera logs ...]
📹 ✓ Recording FINISHED
📹 File exists: true
📹 File size: 0 bytes  ← PROBLEM: Size is 0!
```

---

## ✅ Build Status

```
** BUILD SUCCEEDED **
```

All fixes compiled successfully!

---

**Created**: October 17, 2025  
**Purpose**: Debug recording black screen and missing upload button  
**Status**: Enhanced logging + visual debug panel ready for testing

