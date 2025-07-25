#!/bin/sh
#
# Build and test Git
#

. ${0%/*}/lib.sh

run_tests=t

case "$jobname" in
linux-breaking-changes)
	export GIT_TEST_DEFAULT_INITIAL_BRANCH_NAME=main
	export WITH_BREAKING_CHANGES=YesPlease
	;;
linux-TEST-vars)
	export OPENSSL_SHA1_UNSAFE=YesPlease
	export GIT_TEST_SPLIT_INDEX=yes
	export GIT_TEST_FULL_IN_PACK_ARRAY=true
	export GIT_TEST_OE_SIZE=10
	export GIT_TEST_OE_DELTA_SIZE=5
	export GIT_TEST_COMMIT_GRAPH=1
	export GIT_TEST_COMMIT_GRAPH_CHANGED_PATHS=1
	export GIT_TEST_MULTI_PACK_INDEX=1
	export GIT_TEST_MULTI_PACK_INDEX_WRITE_INCREMENTAL=1
	export GIT_TEST_DEFAULT_INITIAL_BRANCH_NAME=master
	export GIT_TEST_NO_WRITE_REV_INDEX=1
	export GIT_TEST_CHECKOUT_WORKERS=2
	export GIT_TEST_PACK_USE_BITMAP_BOUNDARY_TRAVERSAL=1
	;;
linux-clang)
	export GIT_TEST_DEFAULT_HASH=sha1
	;;
linux-sha256)
	export GIT_TEST_DEFAULT_HASH=sha256
	;;
linux-reftable|linux-reftable-leaks|osx-reftable)
	export GIT_TEST_DEFAULT_REF_FORMAT=reftable
	;;
pedantic)
	# Don't run the tests; we only care about whether Git can be
	# built.
	export DEVOPTS=pedantic
	run_tests=
	;;
esac

case "$jobname" in
*-meson)
	group "Configure" meson setup build . \
		--fatal-meson-warnings \
		--warnlevel 2 --werror \
		--wrap-mode nofallback \
		-Dfuzzers=true \
		-Dtest_output_directory="${TEST_OUTPUT_DIRECTORY:-$(pwd)/t}" \
		$MESONFLAGS
	group "Build" meson compile -C build --
	if test -n "$run_tests"
	then
		group "Run tests" meson test -C build --print-errorlogs --test-args="$GIT_TEST_OPTS" || (
			./t/aggregate-results.sh "${TEST_OUTPUT_DIRECTORY:-t}/test-results"
			handle_failed_tests
		)
	fi
	;;
*)
	group Build make
	if test -n "$run_tests"
	then
		group "Run tests" make test ||
		handle_failed_tests
	fi
	;;
esac

case " $MAKE_TARGETS " in
*" all "*) make -C contrib/subtree test;;
esac

check_unignored_build_artifacts
save_good_tree
