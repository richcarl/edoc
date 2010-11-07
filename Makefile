
APPNAME=edoc

SUB_DIRECTORIES = src

include vsn.mk

DOC_OPTS={def,{version,\"$(EDOC_VSN)\"}}


all: subdirs

subdirs:
	@for d in $(SUB_DIRECTORIES); do \
	  	(cd $$d; $(MAKE)); \
	done

clean:
	@for d in $(SUB_DIRECTORIES); do \
	  	(cd $$d; $(MAKE) clean); \
	done

docs:
	erl -pa ./ebin -noshell -eval "edoc:application($(APPNAME), \".\", [$(DOC_OPTS)])" -s init stop
