#!/usr/bin/env tclsh

set repo_root [file normalize [file join [file dirname [info script]] ..]]
set script_path [file join $repo_root ignite]
set fh [open $script_path r]
set script [read $fh]
close $fh

if {![regexp {proc ssh_probe_succeeded \{probe_status probe_output\} \{.*?\n\}} $script proc_def]} {
  puts stderr "ssh_probe_succeeded helper not found"
  exit 1
}

eval $proc_def

proc assert_equal {expected actual message} {
  if {$expected ne $actual} {
    puts stderr "$message: expected <$expected>, got <$actual>"
    exit 1
  }
}

assert_equal 1 [ssh_probe_succeeded 0 "Torch login banner\nok\n"] \
  "successful probe with extra stdout should be accepted"
assert_equal 1 [ssh_probe_succeeded 0 ""] \
  "successful silent probe should be accepted"
assert_equal 0 [ssh_probe_succeeded 255 "Permission denied"] \
  "failed probe should be rejected"
