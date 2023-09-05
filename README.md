![Logo](https://via.placeholder.com/885x185/8020A0/FFFFFF?text=PortablePanda)

# Portable Panda

Portable Panda is an AHK script that creates a simple menu for portable apps.

## Features

- Easely manage your portable apps
- Simple search
- Run as user / admin
- Define which apps runs your files, using extensions
- Run files with drag and drop
- Add icons to your app categories

## Installation

Portable Panda is design to go on a USB drive so just download this repo to a folder and put it wherever you want!
 
## Usage/Examples

Using Portable Panda is straighforward. 
To add new apps to the menu, you first need to create a category. To do this, simple create a new folder inside ```Applications```, that's inside the ```Data``` folder. You can name it anything, let's say ```Utilities```. Then to add a new app, just copy the app folder, i.e. ```HWInfo``` and copy inside ```Utilities``` folder.

> There's one caveat: The folder name **MUST** be the same as the executable, or else Portable Panda can't *see it*. For more info about this, please check ```Portable Panda.ahk``` 

After that, you can use your apps by right clicking on the tray menu, or pressing ```F3```

The folder structure should be something like this:
```
App\
Data\
  Applications\
    Utilities\
      HWInfo\
        HWInfo.exe
      Utilities.ico (Optional)
  settings.ini
Other\
Portable Panda.ahk
```

| Shortcut  | Function  |
|---|---|
| **Shift + Left Click** | (Menu entry) Opens entry as admin |
| **Ctrl + Left Click** | (Menu entry) Opens entry's folder on File Explorer |
| **Windows Key + j** | Opens current user downloadsd folder |
| **Windows Key + Esc** | Closes current windows, like Alt+F4 |
| **Windows Key + Space** | Toggles Always on Top on the current open window |
| **Windows Key + Mouse Middle Button** | Toggles Always on Top on the current open window |
| **Shift + Enter** | Opens a program with the default app on settings.ini. |
| **Shift + Enter** | If Caps Lock is ON, it will open as admin. |
| **F1** | Search for apps |
| **F3** | Open Menu |

- Shortcuts are enable by default, but you can disable them.
- Icons for apps are automaticaly chosen because it uses the the executable as the source.
- Icons for categories are added by adding a ```.ico``` image to the category folder.
- If you need to use ```AHK``` scripts, download ```AHK``` and copy the ```AutoHotkey64.exe``` to the ```App``` folder.
- There is also a builtin ```Tools``` submenu with some useful stuff. It's disable by default, but you can enable on the settings.