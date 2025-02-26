
include ../vsn.mk

EMULATOR=beam
EBIN=../ebin
INCLUDE=../include

APP_TARGET=$(EBIN)/edoc.app

ERL_COMPILE_FLAGS += -I$(INCLUDE) +warn_unused_vars +nowarn_shadow_vars +warn_unused_import +warn_deprecated_catch -Werror

SOURCES= \
	edoc.erl \
	edoc_cli.erl \
	edoc_data.erl \
	edoc_doclet.erl \
	edoc_doclet_chunks.erl \
	edoc_doclet_markdown.erl \
	edoc_extract.erl \
	edoc_html_to_markdown.erl \
	edoc_layout.erl \
	edoc_layout_chunks.erl \
	edoc_lib.erl \
	edoc_macros.erl \
	edoc_parser.erl \
	edoc_refs.erl \
	edoc_report.erl \
	edoc_run.erl \
	edoc_scanner.erl \
	edoc_specs.erl \
	edoc_tags.erl \
	edoc_types.erl \
	edoc_wiki.erl

OBJECTS=$(SOURCES:%.erl=$(EBIN)/%.$(EMULATOR)) $(APP_TARGET)

all: $(OBJECTS)

$(OBJECTS): edoc.hrl edoc_types.hrl \
	$(INCLUDE)/edoc_doclet.hrl 

clean:
	rm -f $(OBJECTS)
	rm -f edoc_parser.erl

$(EBIN)/%.$(EMULATOR):%.erl
	erlc -pa $(EBIN) -W $(ERL_COMPILE_FLAGS) -o$(EBIN) $<

edoc_parser.erl: edoc_parser.yrl
	erlc $<

$(APP_TARGET): edoc.app.src ../vsn.mk
	sed -e 's;%VSN%;$(EDOC_VSN);' $< > $@
