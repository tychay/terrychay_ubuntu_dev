wm-ubuntu-dev
=============

This is a simple shell script that will take a vanilla instance of ubuntu server
and install the tools in order to build out an environment for Wikimedia
Development.

To use, start with an instance, get this file there and run `./install`

You will need sudo priv's on the box.


## Download Parallels

1. Go to [Ubuntu's website](http://www.ubuntu.com/) > Download > Server: Downlaod and Install 
2. [You willl be here](http://www.ubuntu.com/download/server/download). Download Latest, 64-bit
3. ubuntu-11.10-server-amd64.iso (or later) will be in your Downloads folder or Desktop

## Install Ubuntu (YMMV)

- Choose "English"
- "Install"
- "English" "United States" "Yes" "English (US)"x2
- it will install the software components for installation
- hostname "ubuntu" and TAB "Continue"
- "Pacific Time"
- "Guided + LVM", "SCSI3", "Yes"
- "max" (68.5GB) TAB "Continue" "Yes" [Amazon "small" uses 160GB. May be able to change using Settings below?]
- it will install Linux software into virtual machine
- Go through su account creation [create username and password: On dev VMs I use "ubuntu/Password1"]
- "No Automatic Updates" (not hard to use "apt-get update" instead. Should keep vm images updated on own schedule)
- Packages (none: install manually)
- install GRUB (boot loader is correct, this is a virtual machine)

## Run the installer

	$ cd *directory_where_wm-ubuntu-dev*
	$ ./bootstrap.sh *new_hostname*

## Special: Install on Parallels

Install Ubuntu:

- start Parallels
- Hit the + on Parallels Virtual Machines (or File > New…)
- Double-click Install Windows or another OS from DVD or image File (highlight Install Windows… and click Continue)
- Locate iso in /Downloads from drop down.
- Paralells will auto-detect OS. (If it fails, select "Ubuntu Linux" list or use Other Linux Kernel (2.6))
- Name it (I used "Ubuntu-11.10-server-amd64 Vanilla") and click "Install"
- Go through the (install ubuntu above)

(If cloned, networking will be broken):

- Check networking works with `$ ifconfig` (should have eth0)
- `$ sudo -i`
- `# pico /etc/udev/rules.d/70-persisten-net.rules` Delete the first PCI line and replace NAME="eth0" with name="eth1"
- `# reboot`

Install Parallels Tools:

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

- Click the settings in the lower right of the instance
- Go to Sharing, Choose "None"
- Click "Custom Folders..."
- navigate and add pointer to this directory
- `$ cd /media/psf/*directory name*
- `$ ./boostrap.sh` (repeat as necessary)
