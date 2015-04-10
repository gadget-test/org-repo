PROJECT = org

DEPS = eper sync katana lager

dep_sync = git git://github.com/inaka/sync.git 0.1.3
dep_lager = git git://github.com/basho/lager.git 2.1.1
dep_eper = git git://github.com/massemanet/eper.git 0.90.0
dep_katana = git git://github.com/inaka/erlang-katana 0.2.0

DIALYZER_DIRS := ebin/
DIALYZER_OPTS += --verbose --statistics -Werror_handling \
                 -Wrace_conditions

ERLC_OPTS ?= +debug_info +warn_export_vars +warn_shadow_vars \
	+warn_obsolete_guard # +bin_opt_info +warn_export_all +warn_missing_spec
ERLC_OPTS += +'{parse_transform, lager_transform}' +debug_info

include erlang.mk

CT_OPTS = -cover test/dcn.coverspec -erl_args -config ${CONFIG}
TEST_ERLC_OPTS += +'{parse_transform, lager_transform}' +debug_info

SHELL_OPTS = -name ${PROJECT}@`hostname` -s lager -s ${PROJECT} -s sync

quicktests: app build-ct-suites
	@if [ -d "test" ] ; \
	then \
		mkdir -p logs/ ; \
		$(CT_RUN) -suite $(addsuffix _SUITE,$(CT_SUITES)) $(CT_OPTS) ; \
	fi
	$(gen_verbose) rm -f test/*.beam

erldocs: app
	erldocs . -o doc/
