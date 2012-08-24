#!/bin/sh
# Copyright (C) 2011-2012 Red Hat, Inc. All rights reserved.
#
# This copyrighted material is made available to anyone wishing to use,
# modify, copy, or redistribute it subject to the terms and conditions
# of the GNU General Public License v.2.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software Foundation,
# Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

. lib/test

get_image_pvs() {
	local d
	local images=""

	for d in `ls /dev/mapper/${1}-${2}_?image_*`; do
		images="$images `basename $d | sed s:-:/:`"
	done
	lvs --noheadings -a -o devices $images | sed s/\(.\)//
}

########################################################
# MAIN
########################################################
aux target_at_least dm-raid 1 1 0 || skip

# 9 PVs needed for RAID10 testing (3-stripes/2-mirror - replacing 3 devs)
aux prepare_pvs 9 80
vgcreate -c n -s 256k $vg $(cat DEVICES)

###########################################
# RAID1 convert tests
###########################################
for under_snap in false true; do
for i in 1 2 3 4; do
	for j in 1 2 3 4; do
		if [ $i -eq 1 ]; then
			from="linear"
		else
			from="$i-way"
		fi
		if [ $j -eq 1 ]; then
			to="linear"
		else
			to="$j-way"
		fi

		echo -n "Converting from $from to $to"
		if $under_snap; then
			echo -n " (while under a snapshot)"
		fi
		echo

		if [ $i -eq 1 ]; then
			# Shouldn't be able to create with just 1 image
			not lvcreate --type raid1 -m 0 -l 2 -n $lv1 $vg

			lvcreate -l 2 -n $lv1 $vg
		else
			lvcreate --type raid1 -m $(($i - 1)) -l 2 -n $lv1 $vg
			aux wait_for_sync $vg $lv1
		fi

		if $under_snap; then
			lvcreate -s $vg/$lv1 -n snap -l 2
		fi

		lvconvert -m $((j - 1))  $vg/$lv1

		# FIXME: ensure no residual devices

		if [ $j -eq 1 ]; then
			check linear $vg $lv1
		fi
		lvremove -ff $vg
	done
done
done

# 3-way to 2-way convert while specifying devices
lvcreate --type raid1 -m 2 -l 2 -n $lv1 $vg $dev1 $dev2 $dev3
aux wait_for_sync $vg $lv1
lvconvert -m1 $vg/$lv1 $dev2
lvremove -ff $vg

#
# FIXME: Add tests that specify particular devices to be removed
#

###########################################
# RAID1 split tests
###########################################
# 3-way to 2-way/linear
lvcreate --type raid1 -m 2 -l 2 -n $lv1 $vg
aux wait_for_sync $vg $lv1
lvconvert --splitmirrors 1 -n $lv2 $vg/$lv1
check lv_exists $vg $lv1
check linear $vg $lv2
# FIXME: ensure no residual devices
lvremove -ff $vg

# 2-way to linear/linear
lvcreate --type raid1 -m 1 -l 2 -n $lv1 $vg
aux wait_for_sync $vg $lv1
lvconvert --splitmirrors 1 -n $lv2 $vg/$lv1
check linear $vg $lv1
check linear $vg $lv2
# FIXME: ensure no residual devices
lvremove -ff $vg

# 3-way to linear/2-way
lvcreate --type raid1 -m 2 -l 2 -n $lv1 $vg
aux wait_for_sync $vg $lv1
# FIXME: Can't split off a RAID1 from a RAID1 yet
# 'should' results in "warnings"
should lvconvert --splitmirrors 2 -n $lv2 $vg/$lv1
#check linear $vg $lv1
#check lv_exists $vg $lv2
# FIXME: ensure no residual devices
lvremove -ff $vg

###########################################
# RAID1 split + trackchanges / merge
###########################################
# 3-way to 2-way/linear
lvcreate --type raid1 -m 2 -l 2 -n $lv1 $vg
aux wait_for_sync $vg $lv1
lvconvert --splitmirrors 1 --trackchanges $vg/$lv1
check lv_exists $vg $lv1
check linear $vg ${lv1}_rimage_2
lvconvert --merge $vg/${lv1}_rimage_2
# FIXME: ensure no residual devices
lvremove -ff $vg

###########################################
# Mirror to RAID1 conversion
###########################################
for i in 1 2 3 ; do
	lvcreate --type mirror -m $i -l 2 -n $lv1 $vg
	aux wait_for_sync $vg $lv1
	lvconvert --type raid1 $vg/$lv1
	lvremove -ff $vg
done

###########################################
# Device Replacement Testing
###########################################
# RAID1: Replace up to n-1 devices - trying different combinations
# Test for 2-way to 4-way RAID1 LVs
for i in {1..3}; do
	lvcreate --type raid1 -m $i -l 2 -n $lv1 $vg

	for j in $(seq $(($i + 1))); do # The number of devs to replace at once
	for o in $(seq 0 $i); do        # The offset into the device list
		replace=""

		devices=( $(get_image_pvs $vg $lv1) )

		for k in $(seq $j); do
			index=$((($k + $o) % ($i + 1)))
			replace="$replace --replace ${devices[$index]}"
		done
		aux wait_for_sync $vg $lv1

		if [ $j -ge $((i + 1)) ]; then
			# Can't replace all at once.
			not lvconvert $replace $vg/$lv1
		else
			lvconvert $replace $vg/$lv1
		fi
	done
	done

	lvremove -ff $vg
done

# RAID 4/5/6 (can replace up to 'parity' devices)
for i in 4 5 6; do
	lvcreate --type raid$i -i 3 -l 3 -n $lv1 $vg

	if [ $i -eq 6 ]; then
		dev_cnt=5
		limit=2
	else
		dev_cnt=4
		limit=1
	fi

	for j in {1..3}; do
	for o in $(seq 0 $i); do
		replace=""

		devices=( $(get_image_pvs $vg $lv1) )

		for k in $(seq $j); do
			index=$((($k + $o) % $dev_cnt))
			replace="$replace --replace ${devices[$index]}"
		done
		aux wait_for_sync $vg $lv1

		if [ $j -gt $limit ]; then
			not lvconvert $replace $vg/$lv1
		else
			lvconvert $replace $vg/$lv1
		fi
	done
	done

	lvremove -ff $vg
done

# RAID10: Can replace 'copies - 1' devices from each stripe
# Tests are run on 2-way mirror, 3-way stripe RAID10
aux target_at_least dm-raid 1 3 1 || skip

lvcreate --type raid10 -m 1 -i 3 -l 3 -n $lv1 $vg
aux wait_for_sync $vg $lv1

# Can replace any single device
for i in $(get_image_pvs $vg $lv1); do
	lvconvert --replace $i $vg/$lv1
	aux wait_for_sync $vg $lv1
done

# Can't replace adjacent devices
devices=( $(get_image_pvs $vg $lv1) )
not lvconvert --replace ${devices[0]} --replace ${devices[1]} $vg/$lv1
not lvconvert --replace ${devices[2]} --replace ${devices[3]} $vg/$lv1
not lvconvert --replace ${devices[4]} --replace ${devices[5]} $vg/$lv1

# Can replace non-adjacent devices
for i in 0 1; do
	lvconvert \
		--replace ${devices[$i]} \
		--replace ${devices[$(($i + 2))]} \
		--replace ${devices[$(($i + 4))]} \
		 $vg/$lv1
	aux wait_for_sync $vg $lv1
done
