#!/bin/bash
TEST_COV_REPORT_FULL_PATH=`find $1 -name '*.xcresult' | sort -r | head -1`
TOTAL_XCTEST_COVERAGE=`xcrun xccov view --report $TEST_COV_REPORT_FULL_PATH | grep '.xctest' | head -1 | perl -pe 's/.+?(\d+\.\d+%).+/\1/'`
echo "Test Coverage=$TOTAL_XCTEST_COVERAGE"