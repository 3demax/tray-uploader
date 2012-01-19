OUT=tray

default:
	@echo "doing default action:"
	valac --pkg=gtk+-2.0 --pkg=libsoup-2.4 --pkg libnotify --pkg json-glib-1.0 tray.vala -o ${OUT}
	
run:
	./${OUT}

all:
	@echo "make all:"
	make
	make run
