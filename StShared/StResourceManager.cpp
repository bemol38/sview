/**
 * Copyright © 2014 Kirill Gavrilov <kirill@sview.ru>
 *
 * Distributed under the Boost Software License, Version 1.0.
 * See accompanying file license-boost.txt or copy at
 * http://www.boost.org/LICENSE_1_0.txt
 */

#include <StThreads/StResourceManager.h>

#include <StThreads/StProcess.h>
#include <StFile/StFolder.h>

#include <limits>
#ifdef max
    #undef max
#endif

#if defined(__ANDROID__)

#include <android/asset_manager.h>
#include <android/configuration.h>

/**
 * File resource.
 */
class StAssetResource : public StResource {

        public:

    /**
     * Default constructor.
     */
    ST_LOCAL StAssetResource(const StString& theName,
                             const StString& thePath,
                             AAsset*         theAsset)
    : StResource(theName, thePath),
      myAsset(theAsset) {
        //
    }

    /**
     * Destructor.
     */
    ST_LOCAL virtual ~StAssetResource() {
        if(myAsset != NULL) {
            AAsset_close(myAsset);
        }
    }

    /**
     * This is NOT a file.
     */
    ST_LOCAL virtual bool isFile() const { return false; }

    /**
     * Read file content.
     */
    ST_LOCAL virtual bool read() {
        if(myData != NULL) {
            return true;
        } else if(myAsset == NULL) {
            return false;
        }

        myData = (uint8_t* )AAsset_getBuffer(myAsset);
        mySize = AAsset_getLength(myAsset);
        return myData != NULL;
    }

        protected:

    AAsset* myAsset; //!< handle to asset

};

#endif

StResourceManager::StResourceManager(const StString& theAppName)
: myAppName(theAppName),
  myUserHomeFolder(StProcess::getEnv(StString("HOME")) + SYS_FS_SPLITTER),
  myResFolder(StProcess::getStShareFolder()),
  myLang("en") {

#if defined(_WIN32)
    //
#elif defined(__APPLE__)
    // OS X
    myUserDataFolder = myUserHomeFolder + "Library/Application Support/" + myAppName + "/";
    mySettingsFolder = myUserHomeFolder + "Library/Preferences/"         + myAppName + "/";
    myCacheFolder    = myUserHomeFolder + "Library/Caches/"              + myAppName + "/";
    // make sure parent paths are also exist (on broken home)
    StFolder::createFolder(myUserHomeFolder + "Library");
    StFolder::createFolder(myUserHomeFolder + "Library/Application Support");
    StFolder::createFolder(myUserHomeFolder + "Library/Preferences");
    StFolder::createFolder(myUserHomeFolder + "Library/Caches");
#else
    // Linux world
    myUserDataFolder = myUserHomeFolder + ".local/share/" + myAppName + "/";
    mySettingsFolder = myUserHomeFolder + ".config/"      + myAppName + "/";
    myCacheFolder    = myUserHomeFolder + ".cache/"       + myAppName + "/";
    // make sure parent paths are also exist (on broken home)
    StFolder::createFolder(myUserHomeFolder + ".local");
    StFolder::createFolder(myUserHomeFolder + ".local/share");
    StFolder::createFolder(myUserHomeFolder + ".config");
    StFolder::createFolder(myUserHomeFolder + ".cache");
#endif

    StFolder::createFolder(myUserDataFolder);
    StFolder::createFolder(mySettingsFolder);
    StFolder::createFolder(myCacheFolder);

#if !defined(__ANDROID__)
    const char* aLocaleStr = ::setlocale(LC_CTYPE, NULL);
    StString    aSysLoc(aLocaleStr != NULL ? aLocaleStr : "");
    aSysLoc.toLowerCase();
    if(aSysLoc.getLength() >= 3
    && aSysLoc.getChar(2) == '-') {
        myLang = aSysLoc.subString(0, 2);
    } else if(aSysLoc.isStartsWith(stCString("russian"))) {
        myLang = "ru";
    } else if(aSysLoc.isStartsWith(stCString("french"))) {
        myLang = "fr";
    } else if(aSysLoc.isStartsWith(stCString("german"))) {
        myLang = "de";
    } else if(aSysLoc.isStartsWith(stCString("korean"))) {
        myLang = "ko";
    }
#endif
}

#if defined(__ANDROID__)
StResourceManager::StResourceManager(AAssetManager*  theAssetMgr,
                                     const StString& theAppName)
: myAppName(theAppName),
  myResFolder(StProcess::getStShareFolder()),
  myLang("en"),
  myAssetMgr(theAssetMgr) {
    const StString aRootInt = "/data/data/";
    const StString aRootExt = "/sdcard/Android/data/";
    const StString aRoot    = StFolder::isFolder(aRootExt) ? aRootExt : aRootInt;

    myUserDataFolder = aRoot + theAppName + "/databases/";
    mySettingsFolder = aRoot + theAppName + "/shared_prefs/";
    myCacheFolder    = aRoot + theAppName + "/cache/";

    // create folders when needed
    StFolder::createFolder(aRoot + theAppName);
    StFolder::createFolder(myUserDataFolder);
    StFolder::createFolder(mySettingsFolder);
    StFolder::createFolder(myCacheFolder);

    if(myAssetMgr == NULL) {
        return;
    }

    AConfiguration* aConfig = AConfiguration_new();
    AConfiguration_fromAssetManager(aConfig, myAssetMgr);
    char aLang[3], aCountry[3];
    AConfiguration_getLanguage(aConfig, aLang);
    AConfiguration_getCountry (aConfig, aCountry);
    aLang[2]    = '\0';
    aCountry[2] = '\0';
    myLang = aLang;
    AConfiguration_delete(aConfig);
}
#endif

StResourceManager::~StResourceManager() {
    //
}

bool StResourceManager::isResourceExist(const StString& theName) const {
    const StString aPath = myResFolder + theName;
    if(StFileNode::isFileExists(aPath)) {
        return true;
    }
#if defined(__ANDROID__)
    if(myAssetMgr != NULL) {
        AAsset* anAsset = AAssetManager_open(myAssetMgr, aPath.toCString(), AASSET_MODE_UNKNOWN);
        if(anAsset != NULL) {
            AAsset_close(anAsset);
            return true;
        }
    }
#endif
    return false;
}

StHandle<StResource> StResourceManager::getResource(const StString& theName) const {
    const StString aPath = myResFolder + theName;
    if(StFileNode::isFileExists(aPath)) {
        return new StFileResource(theName, aPath);
    }
#if defined(__ANDROID__)
    if(myAssetMgr != NULL) {
        AAsset* anAsset = AAssetManager_open(myAssetMgr, aPath.toCString(), AASSET_MODE_UNKNOWN);
        if(anAsset != NULL) {
            return new StAssetResource(theName, aPath, anAsset);
        }
    }
#endif
    return StHandle<StResource>();
}

void StResourceManager::listSubFolders(const StString&        theFolder,
                                       StArrayList<StString>& theSubFolders) const {
    const StString aPath = myResFolder + theFolder;
    StFolder aFileDir(aPath);
    StArrayList<StString> anExtensions(1);
    aFileDir.init(anExtensions, 1, true);
    for(size_t aNodeId = 0; aNodeId < aFileDir.size(); ++aNodeId) {
        const StFileNode* aFileNode = aFileDir.getValue(aNodeId);
        if(aFileNode->isFolder()) {
            theSubFolders.add(aFileNode->getSubPath());
        }
    }
    if(aFileDir.size() != 0) {
        return;
    }
}

StResource::StResource(const StString& theName,
                       const StString& thePath)
: myName(theName),
  myPath(thePath),
  myData(NULL),
  mySize(0) {
    //
}

StResource::~StResource() {
    //
}

StFileResource::StFileResource(const StString& theName,
                               const StString& thePath)
: StResource(theName, thePath) {
    //
}

StFileResource::~StFileResource() {
    //
}

bool StFileResource::read() {
    if(myData != NULL) {
        return true;
    } else if(!myFile.readFile(myPath)) {
        return false;
    } else if(myFile.getSize() > size_t(std::numeric_limits<int>::max())) {
        return false;
    }

    myData = myFile.getBuffer();
    mySize = (int )myFile.getSize();
    return true;
}
