# ============================================================
# com
# Computes one COM per resid for all frames of the current molecule
# ============================================================

proc com {seltext} {
    set origmol -1
    foreach cand [molinfo list] {
        if {[string match "COM *" [molinfo $cand get name]]} continue
        set sel [atomselect $cand $seltext frame 0]
        if {[$sel num] > 0} {
            $sel delete
            set origmol $cand
            break
        }
        $sel delete
    }
    if {$origmol == -1} {
        error "Selection \"$seltext\" did not match any atoms in the loaded molecules"
    }
    set nframes [molinfo $origmol get numframes]

    puts "Computing COM for selection: $seltext"
    puts "Frames: $nframes"

    set resids {}
    for {set f 0} {$f < $nframes} {incr f} {
        set sel [atomselect $origmol $seltext frame $f]
        if {[$sel num] > 0} {
            set resids [lsort -integer -unique [concat $resids [$sel get resid]]]
        }
        $sel delete
    }

    if {[llength $resids] == 0} {
        error "Selection \"$seltext\" did not match any atoms in the trajectory"
    }

    #puts "Number of molecules (resids): [llength $resids]"

    set frame_xs {}
    set frame_ys {}
    set frame_zs {}
    set missing 0
    for {set f 0} {$f < $nframes} {incr f} {
        set xs {}
        set ys {}
        set zs {}
        foreach resid $resids {
            set sel [atomselect $origmol "$seltext and resid $resid" frame $f]
            set count [$sel num]
            #puts "Frame $f resid $resid total_atoms $count"
            if {$count == 0} {
                incr missing
                lappend xs nan
                lappend ys nan
                lappend zs nan
            } else {
                set com [measure center $sel weight mass]
                lappend xs [lindex $com 0]
                lappend ys [lindex $com 1]
                lappend zs [lindex $com 2]
            }
            $sel delete
        }
        lappend frame_xs $xs
        lappend frame_ys $ys
        lappend frame_zs $zs
    }

    set molname "COM $seltext"
    set commol [mol new atoms [llength $resids]]
    mol rename $commol "$molname"
    set sel_all [atomselect $commol "all"]
    $sel_all set name COM
    $sel_all set type COM
    $sel_all set resname COM
    $sel_all delete

    for {set f 0} {$f < $nframes} {incr f} {
        if {$f >= 0} {
            animate dup $commol
            puts "Frame $f "
        }
        set sel_com [atomselect $commol "all" frame $f]
        $sel_com set x [lindex $frame_xs $f]
        $sel_com set y [lindex $frame_ys $f]
        $sel_com set z [lindex $frame_zs $f]
        $sel_com delete
    }

    if {$missing > 0} {
        puts "Warning: $missing resid/frame combinations lacked atoms and were set to NaN."
    }

    puts "COM molecule created successfully."
}















