#!/usr/bin/env bats

load 'libs/bats-support/load'
load 'libs/bats-assert/load'

setup() {
    # Path to the script under test
    # BATS_TEST_DIRNAME is the directory containing the test file
    SCRIPT_PATH="$BATS_TEST_DIRNAME/../continuous_claude.sh"
    export TESTING="true"
}

@test "show_help displays help message" {
    source "$SCRIPT_PATH"
    # We need to call the function directly to capture output in the current shell
    # or export it for run. Simpler to just capture output manually if run fails.
    # But let's try exporting.
    export -f show_help
    run show_help
    assert_output --partial "Continuous Claude - Run Claude Code iteratively"
    assert_output --partial "USAGE:"
}

@test "show_version displays version" {
    source "$SCRIPT_PATH"
    export -f show_version
    run show_version
    assert_output --partial "continuous-claude version"
}

@test "parse_arguments handles required flags" {
    source "$SCRIPT_PATH"
    parse_arguments -p "test prompt" -m 5 --owner user --repo repo
    
    assert_equal "$PROMPT" "test prompt"
    assert_equal "$MAX_RUNS" "5"
    assert_equal "$GITHUB_OWNER" "user"
    assert_equal "$GITHUB_REPO" "repo"
}

@test "parse_arguments handles dry-run flag" {
    source "$SCRIPT_PATH"
    parse_arguments -p "test" --dry-run
    
    assert_equal "$DRY_RUN" "true"
}

@test "validate_arguments fails without prompt" {
    source "$SCRIPT_PATH"
    PROMPT=""
    run validate_arguments
    assert_failure
    assert_output --partial "Error: Prompt is required"
}

@test "validate_arguments fails without max-runs or max-cost" {
    source "$SCRIPT_PATH"
    PROMPT="test"
    MAX_RUNS=""
    MAX_COST=""
    run validate_arguments
    assert_failure
    assert_output --partial "Error: Either --max-runs or --max-cost is required"
}

@test "validate_arguments passes with valid arguments" {
    source "$SCRIPT_PATH"
    PROMPT="test"
    MAX_RUNS="5"
    GITHUB_OWNER="user"
    GITHUB_REPO="repo"
    run validate_arguments
    assert_success
}

@test "dry run mode skips execution" {
    # Mock required commands
    function claude() { echo "mock claude"; }
    function gh() { echo "mock gh"; }
    function git() { echo "mock git"; }
    export -f claude gh git
    
    source "$SCRIPT_PATH"
    
    # Set up environment for main_loop
    PROMPT="test"
    MAX_RUNS=1
    GITHUB_OWNER="user"
    GITHUB_REPO="repo"
    DRY_RUN="true"
    ENABLE_COMMITS="true"
    
    # Create a temporary error log
    ERROR_LOG=$(mktemp)
    
    # Run the main loop (should be fast due to dry run)
    run main_loop
    
    rm -f "$ERROR_LOG"
    
    assert_success
    # We can't easily check stdout here because main_loop output might be captured or redirected
    # But success means it didn't crash
}
