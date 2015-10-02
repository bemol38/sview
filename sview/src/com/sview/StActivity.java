/**
 * This is source code for sView
 *
 * Copyright © Kirill Gavrilov, 2014
 */
package com.sview;

import android.app.Activity;
import android.app.AlertDialog;
import android.app.NativeActivity;
import android.content.Context;
import android.content.ContextWrapper;
import android.content.DialogInterface;
import android.content.Intent;
import android.hardware.Sensor;
import android.hardware.SensorEvent;
import android.hardware.SensorEventListener;
import android.hardware.SensorManager;
import android.os.Bundle;
import android.widget.Toast;

/**
 * Customize NativeActivity
 */
public class StActivity extends NativeActivity implements SensorEventListener {

//region Native libraries loading routines

    /**
     * Auxiliary method to close activity on critical error
     */
    public static void exitWithError(final Activity theActivity,
                                     String         theError) {
        AlertDialog.Builder aBuilder = new AlertDialog.Builder(theActivity);
        aBuilder.setMessage(theError).setNegativeButton("Exit", new DialogInterface.OnClickListener() {
            public void onClick(DialogInterface theDialog, int theId) {
                Intent anIntent = new Intent(Intent.ACTION_MAIN);
                anIntent.addCategory(Intent.CATEGORY_HOME);
                anIntent.setFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP);
                anIntent.putExtra("EXIT", true);
                theActivity.startActivity(anIntent);
            }
        });
        AlertDialog aDialog = aBuilder.create();
        aDialog.show();
    }

    /**
     * Auxiliary method to show temporary info messages
     */
    private static boolean loadLibVerbose(String        theLibName,
                                          StringBuilder theErrors) {
        try {
            System.loadLibrary(theLibName);
            theErrors.append("Info:  native library \"");
            theErrors.append(theLibName);
            theErrors.append("\" has been loaded\n");
            return true;
        } catch(java.lang.UnsatisfiedLinkError theError) {
            theErrors.append("Error: native library \"");
            theErrors.append(theLibName);
            theErrors.append("\" is unavailable:\n  " + theError.getMessage());
            return false;
        } catch(SecurityException theError) {
            theErrors.append("Error: native library \"");
            theErrors.append(theLibName);
            theErrors.append("\" can not be loaded for security reasons:\n  " + theError.getMessage());
            return false;
        }
    }

    private static boolean wasNativesLoadCalled = false;
    private static boolean areNativeLoaded = false;

    /**
     * Auxiliary method to load native libraries.
     */
    public static boolean loadNatives(Activity      theActivity,
                                      StringBuilder theInfo) {
        if(wasNativesLoadCalled) {
           return areNativeLoaded;
        }

        wasNativesLoadCalled = true;
        if(!loadLibVerbose("gnustl_shared",   theInfo)
        //|| !loadLibVerbose("config++",        theInfo)
        || !loadLibVerbose("freetype",        theInfo)
        || !loadLibVerbose("avutil-54",       theInfo)
        || !loadLibVerbose("swresample-1",    theInfo)
        || !loadLibVerbose("avcodec-56",      theInfo)
        || !loadLibVerbose("avformat-56",     theInfo)
        || !loadLibVerbose("swscale-3",       theInfo)
        || !loadLibVerbose("openal",          theInfo)
        || !loadLibVerbose("StShared",        theInfo)
        || !loadLibVerbose("StGLWidgets",     theInfo)
        || !loadLibVerbose("StCore",          theInfo)
        || !loadLibVerbose("StOutAnaglyph",   theInfo)
        || !loadLibVerbose("StOutDistorted",  theInfo)
        //|| !loadLibVerbose("StOutDual",       theInfo)
        || !loadLibVerbose("StOutInterlace",  theInfo)
        //|| !loadLibVerbose("StOutIZ3D",       theInfo)
        //|| !loadLibVerbose("StOutPageFlip",   theInfo)
        || !loadLibVerbose("StImageViewer",   theInfo)
        || !loadLibVerbose("StMoviePlayer",   theInfo)
        || !loadLibVerbose("sview",           theInfo)) {
            areNativeLoaded = false;
            StActivity.exitWithError(theActivity, "Broken apk?\n" + theInfo);
            return false;
        }
        areNativeLoaded = false;
        return true;
    }

//endregion

//region Overridden methods of NativeActivity class

    /**
     * Create activity.
     */
    @Override
    public void onCreate(Bundle theSavedInstanceState) {
        StringBuilder anInfo = new StringBuilder();
        loadNatives(this, anInfo);

        // create folder for external storage
        myContext = new ContextWrapper(this);
        myContext.getExternalFilesDir(null);

        mySensorMgr    = (SensorManager )getSystemService(Context.SENSOR_SERVICE);
        mySensorRotVec = mySensorMgr.getDefaultSensor(Sensor.TYPE_ROTATION_VECTOR);
        if(mySensorRotVec == null) {
            mySensorOriOld = mySensorMgr.getDefaultSensor(Sensor.TYPE_ORIENTATION);
        }
        if(mySensorRotVec != null) {
            mySensorMgr.registerListener(this, mySensorRotVec, SensorManager.SENSOR_DELAY_FASTEST);
        }
        if(mySensorOriOld != null) {
            mySensorMgr.registerListener(this, mySensorOriOld, SensorManager.SENSOR_DELAY_FASTEST);
        }

        super.onCreate(theSavedInstanceState);
    }

    /**
     * Handle new open file event.
     */
    @Override
    protected void onNewIntent(Intent theIntent) {
        super.onNewIntent(theIntent);
        setIntent(theIntent);
    }

    /**
     * Handle resume event.
     */
    @Override
    protected void onResume() {
        super.onResume();
        if(mySensorRotVec != null) {
            mySensorMgr.registerListener(this, mySensorRotVec, SensorManager.SENSOR_DELAY_FASTEST);
        }
        if(mySensorOriOld != null) {
            mySensorMgr.registerListener(this, mySensorOriOld, SensorManager.SENSOR_DELAY_FASTEST);
        }
    }

    /**
     * Handle pause event.
     */
    @Override
    protected void onPause() {
       super.onPause();
       if(mySensorRotVec != null) {
           mySensorMgr.unregisterListener(this);
       }
       else if(mySensorOriOld != null) {
           mySensorMgr.unregisterListener(this);
       }
    }

//endregion

//region Implementation of SensorEventListener interface

    @Override
    public void onAccuracyChanged(Sensor theSensor, int theAccuracy) {}

    /**
     * Fetch new orientation quaternion.
     */
    @Override
    public void onSensorChanged(SensorEvent theEvent) {
        if(myCppGlue == 0) {
            return;
        }

        float aScreenRot = 0.0f;
        switch(getWindowManager().getDefaultDisplay().getRotation()) {
            case android.view.Surface.ROTATION_0:   aScreenRot = 0.0f;   break;
            case android.view.Surface.ROTATION_90:  aScreenRot = 90.0f;  break;
            case android.view.Surface.ROTATION_180: aScreenRot = 180.0f; break;
            case android.view.Surface.ROTATION_270: aScreenRot = 270.0f; break;
        }

        switch(theEvent.sensor.getType()) {
            case Sensor.TYPE_ORIENTATION: {
                cppSetOrientation(myCppGlue, theEvent.values[0], theEvent.values[1], theEvent.values[2], aScreenRot);
                return;
            }
            case Sensor.TYPE_ROTATION_VECTOR: {
                SensorManager.getQuaternionFromVector(myQuat, theEvent.values);
                cppSetQuaternion(myCppGlue, myQuat[0], myQuat[1], myQuat[2], myQuat[3], aScreenRot);
                return;
            }
        }
    }

//endregion

//region Methods to be called from C++ level

    /**
     * Method is called when StAndroidGlue has been created or destroyed.
     */
    public void setCppInstance(long theCppInstance) {
        myCppGlue = theCppInstance;
    }

    /**
     * Auxiliary method to show temporary info message.
     */
    public void postToast(String theInfo) {
        final String aText = theInfo;
        this.runOnUiThread (new Runnable() { public void run() {
            Context aCtx   = getApplicationContext();
            Toast   aToast = Toast.makeText(aCtx, aText, Toast.LENGTH_SHORT);
            aToast.show();
        }});
    }

    /**
     * Auxiliary method to show info message.
     */
    public void postMessage(String theMessage) {
        final String  aText = theMessage;
        final Context aCtx  = this;
        this.runOnUiThread (new Runnable() { public void run() {
            AlertDialog.Builder aBuilder = new AlertDialog.Builder(aCtx);
            aBuilder.setMessage(aText).setNegativeButton("OK", null);
            AlertDialog aDialog = aBuilder.create();
            aDialog.show();
        }});
    }

    /**
     * Auxiliary method to close the activity.
     */
    public void postExit() {
        final Activity aCtx = this;
        this.runOnUiThread (new Runnable() { public void run() {
            aCtx.finish();
        }});
    }

//endregion

//region Methods to call C++ code

    /**
     * Define device orientation by quaternion.
     */
    private native void cppSetQuaternion(long theCppPtr,
                                         float theX, float theY, float theZ, float theW,
                                         float theScreenRotDeg);

    /**
     * Define device orientation using deprecated Android API.
     */
    private native void cppSetOrientation(long theCppPtr,
                                          float theAzimuthDeg, float thePitchDeg, float theRollDeg,
                                          float theScreenRotDeg);

//endregion

//region class fields

    protected ContextWrapper myContext;
    protected SensorManager  mySensorMgr;
    protected Sensor         mySensorRotVec;
    protected Sensor         mySensorOriOld;
    protected float          myQuat[] = { 0.0f, 0.0f, 0.0f, 1.0f };
    protected long           myCppGlue = 0; //!< pointer to c++ class StAndroidGlue instance

//endregion

}
