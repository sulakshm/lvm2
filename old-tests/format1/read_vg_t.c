/*
 * Copyright (C) 2001 Sistina Software (UK) Limited.
 *
 * This file is released under the GPL.
 */

#include "log.h"
#include "format1.h"
#include "dbg_malloc.h"

#include <stdio.h>

int main(int argc, char **argv)
{
	struct io_space *ios;
	struct volume_group *vg;

	if (argc != 2) {
		fprintf(stderr, "usage: read_vg_t <vg_name>\n");
		exit(1);
	}

	init_log(stderr);
	init_debug(_LOG_DEBUG);

	if (!dev_cache_init()) {
		fprintf(stderr, "init of dev-cache failed\n");
		exit(1);
	}

	if (!dev_cache_add_dir("/dev")) {
		fprintf(stderr, "couldn't add /dev to dir-cache\n");
		exit(1);
	}

	ios = create_lvm1_format(NULL);
	vg = ios->vg_read(ios, argv[1]);

	if (!vg) {
		fprintf(stderr, "couldn't read vg %s\n", argv[1]);
		exit(1);
	}

	ios->destroy(ios);

	dump_memory();
	fin_log();
	return 0;
}
