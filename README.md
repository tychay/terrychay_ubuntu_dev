terrychay-ubuntu-dev
====================

This is a simple shell script that will take a vanilla instance of ubuntu server
and install a dev environment for terrychay.com

To use, start with an instance, get this file there and run `./install`

You will need sudo priv's on the box.


## Download Ubuntu

1. Go to [Ubuntu's website](http://www.ubuntu.com/) > Download > Server: Download and Install 
2. [You willl be here](http://www.ubuntu.com/download/server/download). Download Latest, 64-bit
3. ubuntu-11.10-server-amd64.iso (or later) will be in your Downloads folder or Desktop

## Install Ubuntu on Parallels

Install Ubuntu:

- start Parallels
- Hit the + on Parallels Virtual Machines (or File > New…)
- Double-click Install Windows or another OS from DVD or image File (highlight Install Windows… and click Continue)
- Locate iso in /Downloads from drop down.
- Parallels will auto-detect OS. (If it fails, select "Ubuntu Linux" list or use Other Linux Kernel (2.6))
- Name it (I used "Ubuntu-11.10-server-amd64 Vanilla") and click "Install"

## Install Ubuntu (YMMV)

- Choose "English"
- "Install"
- "English" "United States" "Yes" "English (US)"x2
- it will install the software components for installation
- hostname "terrychay-dev" and TAB "Continue"
- "Pacific Time"
- "Guided + LVM", "SCSI3", "Yes"
- "max" (68.5GB) TAB "Continue" "Yes" [Amazon "small" uses 160GB. May be able to change using Settings below?]
- it will install Linux software into virtual machine
- Go through su account creation [create username and password: On dev VMs I use "ubuntu/Password1"]
- "No Automatic Updates" (not hard to use "apt-get update" instead. Should keep vm images updated on own schedule)
- Packages (none: install manually)
- install GRUB (boot loader is correct, this is a virtual machine)


## If networking is broken:

(If cloned, networking will be broken):

- Check networking works with `$ ifconfig` (should have eth0)
- `$ sudo -i`
- `# pico /etc/udev/rules.d/70-persistent-net.rules`
- Delete the first PCI line and replace `name="eth0"` with `name="eth1"` and save
- `# reboot`

## Parallels Tools

Install (should be able to skip step):

- `$ sudo apt-get update`
- `$ sudo apt-get install linux-headers-$(uname -r) build-essential`
- menu command "Virtual Machine > Install Parallels Tools…"
- `$ sudo mount -o exec /dev/cdrom /media/cdrom`
- `$ cd /media/cdrom`
- `$ sudo ./install`
- "Next" x3
- "Reboot"

(alternate if already installed)

- `$ cd /usr/lib/parallels-tools`
- `$ sudo ./install`
- (repeat as necessary)

## Bind installer as shared folder

- Click the settings in the lower right of the instance
- Go to "Options > Sharing"
- Share Folder: Choose "None"
- Uncheck "Map Mac volumes to Linux"
- Click "Custom Folders..."
- navigate and add pointer to this directory

## Bind the website as an empty directory

- Create a directory where you will store the development files
- name directory "terrychay-dev"
- add it as a shared folder (to /media/psf) by following instructions above
- copy your bitname key to this directory as "key.pem"


## Run the installer

If you know what you are doing, you can modify the first few lines of
`bootstrap.sh`

	$ cd /media/psf/terrychay-ubuntu-dev
	$ ./bootstrap.sh *new_hostname* *location of new config tree*

## To do development (in espress)

1. Make sure you have the bitnami key somewhere (same as "key.pem" above)
2. Open Terminal (in /Applications/Utilites)
3. Install and test the key (Control-C to get out)
	$ ssh-add *path-to-key.pem1
	$ sftp bitnami@terrychay.bitnamiapp.com
	Connected to terrychay.bitnamiapp.com.
	^CKilled by signal 15.
4. Open Espresso
5. Drag the "htdocs" folder (in wordpress) created in install above into workspace
6. To Servers + Sync, add the bitnami server as "TerryChay BitNami"
	- Protocol: SFTP
	- Server: terrychay.bitnamiapp.com
	- User Name: bitnami
	- Password:
	- Remote Path: /home/bitnami/apps/wordpress
7. In Publish > TerryChay BitNami, click on the bgi cloud button
8. Change to "sync". Try to sync. No changes should be synced

