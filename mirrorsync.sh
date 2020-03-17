#!/bin/bash
#
# The script to sync a local mirror of the Arch Linux repositories and ISOs
#
# Copyright (C) 2007 Woody Gilk <woody@archlinux.org>
# Modifications by Dale Blount <dale@archlinux.org>
# and Roman Kyrylych <roman@archlinux.org>
# Comments translated to German by Dirk Sohler <dirk@0x7be.de>
# Licensed under the GNU GPL (version 2)

# Speicherorte für den Synchronisationsvorgang
SYNC_HOME="/home/mirror"
SYNC_LOGS="$SYNC_HOME/logs"
SYNC_FILES="$SYNC_HOME/files"
SYNC_LOCK="$SYNC_HOME/mirrorsync.lck"

# Auswahl der zu synchronisierenden Repositorys
# Gültige Optionen sind: core, extra, testing, community, iso
# Leer lassen, um den gesammten Mirror zu synchronisieren
# SYNC_REPO=(core extra testing community iso)
SYNC_REPO=(core)

# Server, von dem synchronisiert werden soll
# Nur offizielle, öffentliche Mirrors dürfen rsync.archlinux.org verwenden
# SYNC_SERVER=rsync.archlinux.org::ftp
SYNC_SERVER=rsync.selfnet.de::archlinux
# An dieser Stelle weicht die Lokalisierte Version des Scripts von der
# Originalversion ab, da der Mirror in der Originalversion seit einigen
# Tagen nicht mehr synchronisiert wurde, und daher nur alte Pakete
# bereit stellte. Selfnet hat eine Quota von 50 GB fullspeed am Tag, und
# wird danach auf 16 KByte/s runtergestuft.

# Format des Logfile-Namens
# Das beispiel gibt etwas wie sync_20091019-3.log aus
LOG_FILE="pkgsync_$(date +%Y%m%d-%H).log"

# Logfile anlegen und Timestamp einfügen
touch "$SYNC_LOGS/$LOG_FILE"
echo "=============================================" >> "$SYNC_LOGS/$LOG_FILE"
echo ">> Starting sync on $(date --rfc-3339=seconds)" >> "$SYNC_LOGS/$LOG_FILE"
echo ">> ---" >> "$SYNC_LOGS/$LOG_FILE"

if [ -z $SYNC_REPO ]; then
  # Sync a complete mirror
  rsync -rptlv \
        --delete-after \
        --safe-links \
        --max-delete=1000 \
        --copy-links \
        --delay-updates $SYNC_SERVER "$SYNC_FILES" \
        >> "$SYNC_LOGS/$LOG_FILE"
else
  # Alle Repositorys synchronisieren, die in $SYNC_REPO angegeben wurden
  for repo in ${SYNC_REPO[@]}; do
    repo=$(echo $repo | tr [:upper:] [:lower:])
    echo ">> Syncing $repo to $SYNC_FILES/$repo" >> "$SYNC_LOGS/$LOG_FILE"

    # Wenn man nur i686-Pakete synchronisieren will, kann man in dem
    # rsync-Aufruf dies nach --delete-after inzufügen:
    #  --exclude=os/x86_64
    # 
    # Will man stattdessen nur die x86_64-Pakete synchronisieren, verwendet
    # man stattdessen --exclude=os/i686
    #
    # Will man beide Architekturen auf dem eigenen Mirror anbieten, lässt
    # den rsync-Aufruf einfach, wie er ist
    #
    rsync -rptlv \
          --delete-after \
          --exclude=os/x86_64 \
          --safe-links \
          --max-delete=1000 \
          --copy-links \
          --delay-updates $SYNC_SERVER/$repo "$SYNC_FILES" \
          >> "$SYNC_LOGS/$LOG_FILE"

    # Erstellt eine Datei $repo.lastsync, die den Timestamp der synchronisation
    # beinhaltet (z. B. 2009-10-19 03:14:28+02:00). Dies kann nützlich sein,
    # um einen Hinweis darauf zu haben, wann der eigene Mirror zuletzt mit
    # dem angegebenen Mirror abgeglichen wurde. Zum Verwenden einkommentieren.
    # date --rfc-3339=seconds > "$SYNC_FILES/$repo.lastsync"

    # Nach jedem Repository fünf Sekunden warten, um zu viele gleichzeitige 
    # Verbindungen zum rsync-Server zu verhindern, fall die Verbindung nach
    # dem synchronisieren des vorherigen Repositorys vom Server nicht
    # zeitig geschlossen wurde
    sleep 5 
  done
fi

# Weiteren Timestamp ins Logfile schreiben, und es schließen
echo ">> ---" >> "$SYNC_LOGS/$LOG_FILE"
echo ">> Finished sync on $(date --rfc-3339=seconds)" >> "$SYNC_LOGS/$LOG_FILE"
echo "=============================================" >> "$SYNC_LOGS/$LOG_FILE"
echo "" >> "$SYNC_LOGS/$LOG_FILE"

# Die lock-Datei zum Sperren des Script-Durchlaufs löschen und das
# Script beenden
rm -f "$SYNC_LOCK"
exit 0
