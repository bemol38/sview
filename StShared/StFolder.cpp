/**
 * Copyright © 2009-2014 Kirill Gavrilov <kirill@sview.ru>
 *
 * Distributed under the Boost Software License, Version 1.0.
 * See accompanying file license-boost.txt or copy at
 * http://www.boost.org/LICENSE_1_0.txt
 */

#include <StFile/StFolder.h>
#include <StStrings/StLogger.h>

#ifdef _WIN32
    #include <windows.h>
#else
    #include <sys/stat.h>
    #include <sys/types.h>
    #include <dirent.h>
#endif

namespace {
    static const StString IGNORE_DIR_CURR_NAME('.');
    static const StString IGNORE_DIR_UP_NAME("..");
}

StFolder::StFolder()
: StFileNode(stCString(""), NULL, NODE_TYPE_FOLDER) {
    //
}

StFolder::StFolder(const StCString& theFolderPath,
                   StNode*          theParentNode)
: StFileNode(theFolderPath, theParentNode, NODE_TYPE_FOLDER) {
    //
}

StFolder::~StFolder() {
    //
}

bool StFolder::isFolder() const {
    return true;
}

bool StFolder::isFolder(const StCString& thePath) {
#ifdef _WIN32
    StStringUtfWide aPath;
    aPath.fromUnicode(thePath);
    DWORD aFileAttributes = GetFileAttributesW(aPath.toCString());
    if(aFileAttributes == INVALID_FILE_ATTRIBUTES) {
        return false;
    }
    if((aFileAttributes & FILE_ATTRIBUTE_DIRECTORY) != 0) {
        return true;
    }
    return false;
#else
    DIR* aDir = opendir(thePath.toCString());
    if(aDir == NULL) {
        return false;
    }
    closedir(aDir);
    return true;
#endif
}

bool StFolder::createFolder(const StCString& thePath) {
    if(thePath.isEmpty()) {
        return false;
    }

#ifdef _WIN32
    StStringUtfWide aPath;
    aPath.fromUnicode(thePath);
    return ::CreateDirectoryW(aPath.toCString(), NULL) != FALSE;
#else
    return ::mkdir(thePath.toCString(), 0755) == 0;
#endif
}

void StFolder::addItem(const StArrayList<StString>& theExtensions,
                       int theDeep,
                       const StString& theSearchFolderPath,
                       const StString& theCurrentItemName,
                       const bool      theToAddEmptyFolders) {
    if(theCurrentItemName == IGNORE_DIR_CURR_NAME || theCurrentItemName == IGNORE_DIR_UP_NAME) {
        return;
    }

    StString aCurrItemFullName = theSearchFolderPath + SYS_FS_SPLITTER + theCurrentItemName;
    if(isFolder(aCurrItemFullName)) {
        if(theDeep > 1) {
            StFolder* aSubFolder = new StFolder(theCurrentItemName, this);
            aSubFolder->init(theExtensions, theDeep - 1);
            if(aSubFolder->size() > 0
            || theToAddEmptyFolders) {
                add(aSubFolder);
            } else {
                // ignore empty folders
                delete aSubFolder;
            }
        } else if(theToAddEmptyFolders) {
            StFolder* aSubFolder = new StFolder(theCurrentItemName, this);
            add(aSubFolder);
        }
    } else {
        StString anItemExtension = StFileNode::getExtension(theCurrentItemName);
        for(size_t anExt = 0; anExt < theExtensions.size(); ++anExt) {
            if(anItemExtension.isEqualsIgnoreCase(theExtensions[anExt])) {
                add(new StFileNode(theCurrentItemName, this));
                break;
            }
        }
    }
}

void StFolder::init(const StArrayList<StString>& theExtensions,
                    const int                    theDeep,
                    const bool                   theToAddEmptyFolders) {
    // clean up old list...
    clear();
    StString aSearchFolderPath = getPath();
#ifdef _WIN32
    WIN32_FIND_DATAW aFindFile;
    StString aStrSearchMask = getPath() + StString(SYS_FS_SPLITTER) + '*';

    HANDLE hFind = FindFirstFileW(aStrSearchMask.toUtfWide().toCString(), &aFindFile);
    for(BOOL hasFile = (hFind != INVALID_HANDLE_VALUE); hasFile == TRUE;
        hasFile = FindNextFileW(hFind, &aFindFile)) {
        //
        StString aCurrItemName(aFindFile.cFileName);
        addItem(theExtensions, theDeep, aSearchFolderPath, aCurrItemName, theToAddEmptyFolders);
    }
    FindClose(hFind);
#else
    DIR* aSearchedFolder = opendir(aSearchFolderPath.toCString());
    if(aSearchedFolder == NULL) {
        return;
    }
    for(dirent* aDirItem = readdir(aSearchedFolder); aDirItem != NULL;
        aDirItem = readdir(aSearchedFolder)) {
        //
    #if (defined(__APPLE__))
        // automatically convert filenames from decomposed form used by Mac OS X file systems
        StString aCurrItemName = stFromUtf8Mac(aDirItem->d_name);
    #else
        StString aCurrItemName(aDirItem->d_name);
    #endif
        addItem(theExtensions, theDeep, aSearchFolderPath, aCurrItemName, theToAddEmptyFolders);
    }
    closedir(aSearchedFolder);
#endif
    // perform sorting...
    sort();
}
