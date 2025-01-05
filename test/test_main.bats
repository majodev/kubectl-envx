#!/usr/bin/env bats

setup() {
  bats_load_library bats-support
  bats_load_library bats-assert # https://github.com/bats-core/bats-assert
}

kenvx() {
  bash "$PROJECT_ROOT_DIR"/kenvx "$@"
}

@test "fails on missing arguments" {
  run kenvx
  assert_failure
}

@test "fails on invalid resource kind" {
  run kenvx invalid/app
  assert_failure
  assert_output "error: the server doesn't have a resource type \"invalid\""
}

@test "fails on invalid resource name" {
  run kenvx deployment/notfound
  assert_failure
  assert_output "Error from server (NotFound): deployments.apps \"notfound\" not found"
}

@test "deployment/noenv: prints ENV (nothing)" {
  run kenvx deployment/noenv
  assert_success
  assert_output ""
}

@test "deployment/noenv: exec with ENV" {
  run kenvx deployment/noenv -- sh -c 'echo exec'
  assert_success
  assert_output "exec"
}

@test "deployment/emptyenv: prints ENV (nothing)" {
  run kenvx deployment/emptyenv
  assert_success
  assert_output ""
}

@test "deployment/emptyenv: exec with ENV" {
  run kenvx deployment/emptyenv -- sh -c 'echo exec'
  assert_success
  assert_output "exec"
}

# shellcheck disable=SC2016
@test "deployment/emptyenv: exec with ENV add (new var single)" {
  run kenvx deployment/emptyenv MYVAR=added -- sh -c 'echo "$MYVAR"'
  assert_success
  assert_output "added"
}

# shellcheck disable=SC2016
@test "deployment/emptyenv: exec with ENV add (new var multi)" {
  run kenvx deployment/emptyenv MYVAR="added\nmulti" -- sh -c 'echo "$MYVAR"'
  assert_success
  assert_output "added
multi"
}

# shellcheck disable=SC2016
@test "deployment/sample: exec with ENV multiline override" {
  run kenvx deployment/sample SAMPLE_MULTI="override\nmulti" -- sh -c 'echo "$SAMPLE_MULTI"'
  assert_success
  assert_output "override
multi"
}

# shellcheck disable=SC2016
@test "deployment/sample: exec with envFrom multiline override" {
  run kenvx deployment/sample SAMPLE_FROM_MULTI="override\nmulti" -- sh -c 'echo "$SAMPLE_FROM_MULTI"'
  assert_success
  assert_output "override
multi"
}

# shellcheck disable=SC2016
@test "cronjob/envfrom: exec with envFrom manifest SAMPLE_FROM_SINGLE override" {
  run kenvx cronjob/envfrom -- sh -c 'echo "$SAMPLE_FROM_SINGLE"'
  assert_success
  assert_output "override"
}

@test "cronjob/invalidrefs: prints (partial) ENV" {
  run kenvx cronjob/invalidrefs
  assert_output "SAMPLE_HERE=working"
}

@test "cronjob/duplicates: prints (partial) ENV" {
  run kenvx cronjob/duplicates
  assert_output "SAMPLE_HERE=working
SAMPLE_DUP=first_occurrence"
}

@test "deployment/sample2 -n default2: prints (partial) ENV" {
  expected="SAMPLE_SINGLE=Simple string 2
SAMPLE_MULTI=Multi line
value 2"

  run kenvx -n default2 deployment/sample2
  assert_output "$expected"

  run kenvx --namespace default2 deployment/sample2
  assert_output "$expected"
}

# todo test with other namespace as in context
# test with invalid referenced
# test with specific container
# test with duplicated env

# test envFrom support (which is something the default list does not support!)