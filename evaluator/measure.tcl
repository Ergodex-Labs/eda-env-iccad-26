# Measure the final ODB using task-owned libraries and constraints.

set odb  $::env(ODB_FILE)
set sdc  $::env(EVAL_SDC)
set out  $::env(OUT_JSON)

read_db $odb

foreach lib $::env(LIB_FILES) {
  read_liberty $lib
}

read_sdc $sdc

if { [info exists ::env(RCX_RULES)] && $::env(RCX_RULES) ne ""
     && [file exists $::env(RCX_RULES)] } {
  define_process_corner -ext_model_index 0 X
  extract_parasitics -ext_model_file $::env(RCX_RULES)
  set spef [file join [file dirname $::env(OUT_JSON)] signoff.spef]
  write_spef $spef
  read_spef $spef
} else {
  estimate_parasitics -global_routing
}

set_propagated_clock [all_clocks]

set have_drc_check 0
catch {
  set drc_rpt [file join [file dirname $out] check_drc.rpt]
  file delete -force $drc_rpt
  check_drc -output_file $drc_rpt
  set n 0
  set fh3 [open $drc_rpt r]
  while { [gets $fh3 line] >= 0 } {
    if { [regexp {^\s*violation type:} $line] } { incr n }
  }
  close $fh3
  set drc_check_violations $n
  set have_drc_check 1
  puts "SIGNOFF_GATER check_drc: $n violations on the final layout"
}

set wns   [sta::worst_slack -max]
set whs   [sta::worst_slack -min]
set tns   [sta::total_negative_slack -max]
set inst_count 0
foreach inst [[ord::get_db_block] getInsts] {
  set mtype [[$inst getMaster] getType]
  if { $mtype eq "CORE_SPACER" || $mtype eq "CORE_WELLTAP"
       || [string match "ENDCAP*" $mtype] } { continue }
  incr inst_count
}

set have_timing 1
if { ![string is double -strict $wns] || abs($wns) > 1.0e6 } {
  set have_timing 0
  puts "SIGNOFF_GATER RT-19: non-physical WNS ($wns) — timing keys omitted"
}

set have_power 0
catch {
  set pw_file [file join [file dirname $out] power.rpt]
  report_power > $pw_file
  set fh2 [open $pw_file r]
  while { [gets $fh2 line] >= 0 } {
    if { [regexp {^Total\s} $line] } {
      set f [regexp -all -inline {\S+} $line]
      set ptotal [lindex $f 4]
      if { [string is double -strict $ptotal] } { set have_power 1 }
    }
  }
  close $fh2
}
set have_area 0
set have_util 0
catch {
  set block [ord::get_db_block]
  set dbu   [[ord::get_db_tech] getDbUnitsPerMicron]
  set sum 0.0
  foreach inst [$block getInsts] {
    set m [$inst getMaster]
    set mtype [$m getType]
    if { $mtype eq "CORE_SPACER" || $mtype eq "CORE_WELLTAP"
         || [string match "ENDCAP*" $mtype] } { continue }
    set sum [expr {$sum + double([$m getWidth]) * [$m getHeight]}]
  }
  set area_um2 [expr {$sum / (double($dbu) * $dbu)}]
  set have_area 1
  catch {
    set core [$block getCoreArea]
    set cw [expr {double([$core dx]) / $dbu}]
    set ch [expr {double([$core dy]) / $dbu}]
    if { $cw > 0 && $ch > 0 } {
      set utilization [expr {$area_um2 / ($cw * $ch)}]
      set have_util 1
    }
  }
}

if { [info exists ::env(IR_NET)] && $::env(IR_NET) ne "" } {
  catch {
    set_pdnsim_net_voltage -net $::env(IR_NET) -voltage $::env(IR_VOLTAGE)
    analyze_power_grid -net $::env(IR_NET)
  }
}
set lines [list "  \"instance_count\": $inst_count"]
if { $have_timing } {
  lappend lines "  \"wns\": $wns" "  \"whs\": $whs" "  \"tns\": $tns"
}
if { $have_power } { lappend lines "  \"power_total\": $ptotal" }
if { $have_area }  { lappend lines "  \"area_um2\": $area_um2" }
if { $have_util }  { lappend lines "  \"utilization\": $utilization" }
if { $have_drc_check } { lappend lines "  \"drc_check_violations\": $drc_check_violations" }
if { [info exists ::env(MACRO_MASTER)] && $::env(MACRO_MASTER) ne "" } {
  if { ![catch {
    set mmset [split $::env(MACRO_MASTER)]
    set mc 0; set mplaced 1; set msig 1; set mpg 1
    array set mfound {}
    foreach inst [[ord::get_db_block] getInsts] {
      set mname [[$inst getMaster] getName]
      if { [lsearch -exact $mmset $mname] < 0 } { continue }
      set mfound($mname) 1
      incr mc
      if { ![$inst isPlaced] } { set mplaced 0 }
      foreach it [$inst getITerms] {
        set st  [$it getSigType]
        set net [$it getNet]
        if { $st eq "POWER" || $st eq "GROUND" } {
          if { $net eq "NULL" || $net eq "" } { set mpg 0 }
        } else {
          if { $net eq "NULL" || $net eq "" } { set msig 0 }
        }
      }
    }
    if { $mc == 0 } { set mplaced 0; set msig 0; set mpg 0 }
    set mpresent [llength [array names mfound]]
  } merr] } {
    lappend lines "  \"macro_count\": $mc" \
      "  \"macro_masters_present\": $mpresent" \
      "  \"macro_placed\": $mplaced" \
      "  \"macro_conn_signal\": $msig" \
      "  \"macro_conn_power\": $mpg"
  } else {
    puts "SIGNOFF_GATER FS-15: macro check FAILED ($merr) - keys omitted"
  }
}
set fh [open $out w]
puts $fh "{"
puts $fh [join $lines ",\n"]
puts $fh "}"
close $fh
puts "SIGNOFF_GATER_DONE $out"
