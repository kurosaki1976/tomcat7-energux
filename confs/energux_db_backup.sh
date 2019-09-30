#!/bin/bash
BDIR=/var/backups/energux_db/$(date +%Y)
FILENAME=energux_$(date +%d%m%Y).sql
if [ ! -d $BDIR/$(date +%B) ]; then
	mkdir -p $BDIR/$(date +%B)
fi
if [ -f $BDIR/$(date +%B)/$FILENAME ]; then
	rm $BDIR/$(date +%B)/$FILENAME | pg_dump energux -h localhost -E UTF8 -U postgres -w -v -f $BDIR/$(date +%B)/$FILENAME
else
	pg_dump energux -h localhost -E UTF8 -U postgres -w -v -f $BDIR/$(date +%B)/$FILENAME
fi
exit 0
