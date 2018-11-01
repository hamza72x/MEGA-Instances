#!/bin/bash

#Some useful variables
REALHOME=$HOME
MEGADIR="MEGA"
FILE=$REALHOME/.config/megasync-instances/ok
ERR=0
echo "REALHOME = $REALHOME"

zenity () {
  /usr/bin/zenity "$@" 2>/dev/null
}

checkDep () {
  if [[ `whereis $1` == "$1:" ]];
  then
    >&2 echo "Dependency '$1' seems to be missing"
    ERR=1
  fi
}

#Function that creates a Desktop Entry and sets it up for autostart at the login
generateDesktopEntry () {
  DEPATH=$REALHOME/.config/autostart/mega_instances.desktop
	mkdir -p /home/$USER/.config/autostart
	echo "[Desktop Entry]" > $DEPATH
	echo "Type=Application" >> $DEPATH
	echo "Exec=/usr/bin/megasync-instances" >> $DEPATH
	echo "Name=megasync_instances" >> $DEPATH
	echo "Comment=Open all your MEGA instances"  >> $DEPATH
	chmod +x $DEPATH
}

finstall () {
  checkDep "zenity"
  checkDep "megasync"

	if [[ $ERR -ne 0 ]]; then
		>&2 echo "Error: Install all required dependencies before running MEGA-Instances"
		exit 1
	fi

	generateDesktopEntry
	frun
}

frun () {
	if [ -f $FILE ];
	then
		echo "MEGA-Instances is already configured, launching the instances..."
    echo "If you wish to run the first configuration again, manually remove $FILE"

		for d in $REALHOME/$MEGADIR/*/ ; do
			echo "$d"
			HOME=$d
			megasync 2> /dev/null &
		done

	else
	  	echo "MEGA-Instances is not configured. Will now start the configuration."

      if zenity --question --text=zenity --question --no-wrap --text="This is the first time you are running MEGA-Instances.\nIn order to continue we must delete your existing MEGA instance.\nPress Yes to continue, No to abort."; then
          rm -rf ~/MEGA
          rm -f ~/.config/megasync.desktop
      else
          exit
      fi

			INSTNUM=`zenity --entry --text="How many MEGA instances do you need?"`
			mkdir -p $REALHOME/$MEGADIR

			for (( i=1; i<=INSTNUM; i++ ))
			do
				NAME=`zenity --entry --text="Insert the name for instance $i/$INSTNUM"`
				ARRAY[$i]=$NAME
				mkdir -p $REALHOME/$MEGADIR/$NAME
			done

			for (( i=1; i<=INSTNUM; i++ ))
			do
				zenity --warning --text="Instance ${ARRAY[i]} ($i/$INSTNUM). Close it after the configuration."
				HOME=$REALHOME/$MEGADIR/${ARRAY[$i]}
				megasync
			done

			generateDesktopEntry

			zenity --warning --text="Will now launch all the instances. They will also start at every startup."
			HOME=$REALHOME
			touch $FILE #Mark as configured
			#cp $0 $REALHOME/$MEGADIR/mega_instances.sh
			chmod +x $REALHOME/$MEGADIR/mega_instances.sh
			bash $REALHOME/$MEGADIR/mega_instances.sh
	fi
}

finstall
